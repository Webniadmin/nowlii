import json
import anthropic
import openai
from google import genai
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema

from .serializers import SubTaskRequestSerializer, SubTaskResponseSerializer


# ──────────────────────────────────────────
#  Prompt Builder
# ──────────────────────────────────────────

def build_prompt(category: str, previous_tasks: list) -> str:
    return f"""Your job is to generate exactly 3 unique and relevant sub-tasks based on the given category.

Rules:
1. Each sub-task must be 2-3 words only.
2. Each sub-task must be short, clear, and actionable.
3. Sub-tasks must be directly related to the category.
4. Do NOT repeat or generate similar tasks.
5. Each sub-task must be different from previous outputs (if regeneration is requested).
6. Avoid generic tasks — be specific.
7. Return output as a clean JSON array only — no explanation, no markdown, no code fences.

Category: "{category}"
Previously Generated Tasks (if any): {json.dumps(previous_tasks) if previous_tasks else "none"}

Output format:
["Task 1", "Task 2", "Task 3"]"""


def parse_response(raw: str) -> list:
    clean = raw.replace("```json", "").replace("```", "").strip()
    return json.loads(clean)


# ──────────────────────────────────────────
#  Auto-detect active provider from .env
#  Priority: ANTHROPIC → OPENAI → GOOGLE
# ──────────────────────────────────────────

def get_active_provider() -> str:
    """
    Reads settings to determine which provider is configured.
    Whichever API key is present in .env wins.
    Priority order: claude → chatgpt → gemini
    """
    if getattr(settings, "ANTHROPIC_API_KEY", None):
        return "claude"
    if getattr(settings, "OPENAI_API_KEY", None):
        return "chatgpt"
    if getattr(settings, "GOOGLE_AI_API_KEY", None):
        return "gemini"
    raise EnvironmentError(
        "No AI provider API key found. "
        "Set one of: ANTHROPIC_API_KEY, OPENAI_API_KEY, GOOGLE_AI_API_KEY in your .env"
    )


# ──────────────────────────────────────────
#  Provider Clients
# ──────────────────────────────────────────

def call_claude(prompt: str) -> list:
    client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
    response = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=1000,
        messages=[{"role": "user", "content": prompt}]
    )
    return parse_response(response.content[0].text)


def call_chatgpt(prompt: str) -> list:
    client = openai.OpenAI(api_key=settings.OPENAI_API_KEY)
    response = client.chat.completions.create(
        model="gpt-4o",
        max_tokens=1000,
        messages=[{"role": "user", "content": prompt}]
    )
    return parse_response(response.choices[0].message.content)


def call_gemini(prompt: str) -> list:
    client = genai.Client(api_key=settings.GOOGLE_AI_API_KEY)
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt
    )
    return parse_response(response.text)


# ──────────────────────────────────────────
#  Provider Registry
# ──────────────────────────────────────────

AI_PROVIDERS = {
    "claude":  call_claude,
    "chatgpt": call_chatgpt,
    "gemini":  call_gemini,
}


def call_ai(category: str, previous_tasks: list) -> tuple[list, str]:
    """
    Auto-detects the active provider from settings and calls it.
    Returns (tasks, provider_name).
    """
    provider = get_active_provider()
    prompt   = build_prompt(category, previous_tasks)
    handler  = AI_PROVIDERS[provider]
    return handler(prompt), provider


# ──────────────────────────────────────────
#  Views
# ──────────────────────────────────────────

class GenerateSubTasksView(APIView):

    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_summary="Generate sub-tasks using AI",
        operation_description="Generates 3 unique sub-tasks for a given category. The AI provider is auto-detected from .env.",
        tags=["Subtask Generator"],
        request_body=SubTaskRequestSerializer,
        responses={
            200: SubTaskResponseSerializer,
            400: "Bad Request",
            502: "AI Gateway Error",
            503: "Service Unavailable"
        }
    )
    def post(self, request):
        serializer = SubTaskRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        category       = serializer.validated_data["category"]
        previous_tasks = serializer.validated_data.get("previous_tasks", [])

        try:
            tasks, provider = call_ai(category, previous_tasks)

        except EnvironmentError as e:
            return Response({"error": str(e)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        except json.JSONDecodeError:
            return Response(
                {"error": "Failed to parse AI response. Please try again."},
                status=status.HTTP_502_BAD_GATEWAY
            )
        except (anthropic.APIError, openai.OpenAIError) as e:
            return Response(
                {"error": f"AI service error: {str(e)}"},
                status=status.HTTP_502_BAD_GATEWAY
            )
        except Exception as e:
            return Response(
                {"error": f"Unexpected error: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        response_data = {
            "category": category,
            "tasks":    tasks,
        }
        out = SubTaskResponseSerializer(data=response_data)
        out.is_valid()
        return Response(out.data, status=status.HTTP_200_OK)