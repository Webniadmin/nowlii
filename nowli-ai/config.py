"""
config.py — all environment variables and constants in one place.
"""
import os
from dotenv import load_dotenv

load_dotenv()


def _clean_env(name: str, default: str = "") -> str:
	value = os.getenv(name, default)
	if value is None:
		return default
	# Support inline comments in .env values and trim accidental spaces.
	return value.split("#", 1)[0].strip()

# ── API Keys ────────────────────────────────────────────────────────────────
OPENAI_API_KEY: str   = _clean_env("OPENAI_API_KEY", "")
HUME_API_KEY: str     = _clean_env("HUME_API_KEY", "")
HUME_SECRET_KEY: str  = _clean_env("HUME_SECRET_KEY", "")
HUME_CONFIG_ID: str   = _clean_env("HUME_CONFIG_ID", "")

# ── Auth ─────────────────────────────────────────────────────────────────────
# This service mints OpenAI Realtime ephemeral keys and runs GPT calls, so an open
# /api/v1/ surface is a direct route to someone else's OpenAI bill. Requests are
# authenticated by verifying the *Django* access token the app already holds — same
# HS256 secret, verified locally, so there is no extra network hop.
#
# Must equal `SECRET_KEY` in nowli-backend/.env. Left empty, auth is DISABLED and the
# service logs a warning on every start — that is the pre-existing behaviour, kept so
# setting the variable can lag the deploy without taking prod down.
NOWLII_JWT_SECRET: str = _clean_env("NOWLII_JWT_SECRET", "")
NOWLII_JWT_ALGORITHM: str = _clean_env("NOWLII_JWT_ALGORITHM", "HS256")

# Comma-separated CORS origins. The real client is a mobile app (CORS does not apply
# to it), so this only matters if a browser ever talks to the service.
AI_CORS_ORIGINS: str = _clean_env("AI_CORS_ORIGINS", "*")

# ── LLM ─────────────────────────────────────────────────────────────────────
LLM_MODEL: str        = os.getenv("LLM_MODEL", "gpt-4o")
LLM_MAX_TOKENS: int   = int(os.getenv("LLM_MAX_TOKENS", "512"))
LLM_TEMPERATURE: float = float(os.getenv("LLM_TEMPERATURE", "0.7"))

# ── Audio ────────────────────────────────────────────────────────────────────
SAMPLE_RATE: int   = 16_000   # 16 kHz PCM
CHANNELS: int      = 1
SAMPLE_WIDTH: int  = 2        # 16-bit

# ── Emotion ──────────────────────────────────────────────────────────────────
TOP_N_EMOTIONS: int = 5       # how many top emotions to surface

# ── System prompt template ───────────────────────────────────────────────────
SYSTEM_PROMPT_TEMPLATE: str = """\
You are a warm, empathetic conversational AI.

The user's current emotional state (detected from their voice and text):
{emotion_context}

Guidelines:
- Respond naturally and conversationally (2-4 sentences max).
- Acknowledge the user's emotional state when appropriate.
- Adapt your tone to match or complement their emotions.
- Be supportive, clear, and human.
"""

# ── Text-emotion prompt ──────────────────────────────────────────────────────
TEXT_EMOTION_PROMPT: str = """\
Analyse the emotional tone of the following text and return a JSON object
with emotion names as keys and confidence scores (0.0–1.0) as values.
Include only the top {top_n} emotions. Return ONLY valid JSON, no prose.

Text: {text}
"""
