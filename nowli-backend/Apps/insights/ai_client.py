"""
AI client for generating weekly reflections.
Auto-detects provider from settings (same pattern as subtasks app).
Priority: ANTHROPIC → OPENAI → GOOGLE
"""
import json
import anthropic
import openai
from google import genai
from django.conf import settings


# ─────────────────────────────────────────────
#  Prompt
# ─────────────────────────────────────────────

REFLECTION_PROMPT = """
You are a personal productivity coach analyzing a user's quest/task completion data.

Based on the weekly analytics below, generate exactly 3 short, insightful reflection sentences.
Rules:
- Each sentence must be specific to the data provided (mention day names, percentages, zone types).
- Tone: encouraging, honest, motivating.
- Keep each sentence under 20 words.
- Do NOT use generic filler like "Great job!" or "Keep it up!".
- Return ONLY a clean JSON array of 3 strings. No explanation, no markdown, no code fences.

Weekly data:
{weekly_data}

Output format:
["Reflection 1", "Reflection 2", "Reflection 3"]
"""

QUEST_SUGGESTION_PROMPT = """
You are a personal productivity coach. Your job is to generate 5 personalized "Quest" suggestions for users based on their behavior, current time, and productivity patterns.

Context:
The app has "Quests" with:
- task (2-4 words, like: "To walk", "Deep focus")
- description (1 short motivational line)
- zone: "Soft steps", "Elevated", "Power move", "Stretch zone"
- suggested_time (HH:MM)

Input:
- Weekly analytics: {weekly_data}
- Current time: {current_time}
- Today's day: {day_of_week}

Rules:
1. Time-based:
   - Morning -> light + activation tasks
   - Afternoon -> focus/work tasks
   - Evening -> reflection / light tasks
   - Night -> calm / sleep tasks
2. Behavior-based:
   - If user skips tasks -> suggest more "Soft steps"
   - If user is consistent -> suggest "Power move"
   - If mixed -> balance zones
3. Variety:
   - Include at least: 1 Soft step, 1 Power move, 1 Stretch zone.
   - Do NOT repeat similar tasks.
4. Output Format:
   Return ONLY a clean JSON array of 5 objects. No markdown, no code fences, no extra text.
   [
     {{"task": "...", "description": "...", "zone": "...", "suggested_time": "HH:MM"}}
   ]
"""


def _build_reflection_prompt(weekly_data: dict) -> str:
    return REFLECTION_PROMPT.format(weekly_data=json.dumps(weekly_data, indent=2))


def _build_quest_prompt(weekly_data: dict, current_time: str, day_of_week: str) -> str:
    return QUEST_SUGGESTION_PROMPT.format(
        weekly_data=json.dumps(weekly_data, indent=2),
        current_time=current_time,
        day_of_week=day_of_week
    )


def _parse(raw: str) -> list:
    clean = raw.replace("```json", "").replace("```", "").strip()
    return json.loads(clean)


# ─────────────────────────────────────────────
#  Provider auto-detection
# ─────────────────────────────────────────────

def get_active_provider() -> str:
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


# ─────────────────────────────────────────────
#  Provider callers
# ─────────────────────────────────────────────

def _call_claude(prompt: str) -> list:
    client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
    response = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=500,
        messages=[{"role": "user", "content": prompt}]
    )
    return _parse(response.content[0].text)


def _call_chatgpt(prompt: str) -> list:
    client = openai.OpenAI(api_key=settings.OPENAI_API_KEY)
    response = client.chat.completions.create(
        model="gpt-4o",
        max_tokens=500,
        messages=[{"role": "user", "content": prompt}]
    )
    return _parse(response.choices[0].message.content)


def _call_gemini(prompt: str) -> list:
    client = genai.Client(api_key=settings.GOOGLE_AI_API_KEY)
    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt
    )
    return _parse(response.text)


_PROVIDERS = {
    "claude":  _call_claude,
    "chatgpt": _call_chatgpt,
    "gemini":  _call_gemini,
}


# ─────────────────────────────────────────────
#  Public API
# ─────────────────────────────────────────────

def generate_weekly_reflections(weekly_data: dict) -> list[str]:
    """
    Calls the auto-detected AI provider and returns
    a list of 3 reflection strings.
    """
    provider = get_active_provider()
    prompt   = _build_reflection_prompt(weekly_data)
    return _PROVIDERS[provider](prompt)


def generate_quest_suggestions(weekly_data: dict, current_time: str, day_of_week: str) -> list[dict]:
    """
    Calls the auto-detected AI provider and returns
    a list of 5 quest suggestion objects.
    """
    provider = get_active_provider()
    prompt   = _build_quest_prompt(weekly_data, current_time, day_of_week)
    return _PROVIDERS[provider](prompt)
