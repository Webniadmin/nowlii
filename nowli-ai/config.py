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
