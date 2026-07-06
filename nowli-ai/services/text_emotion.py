"""
services/text_emotion.py
========================
Detects emotions from plain text using an OpenAI chat completion.
The model returns a JSON object  {emotion: score, ...}  which we parse
and turn into a ranked list of EmotionScore objects.
"""
from __future__ import annotations

import json
import logging
import re
from typing import List

from openai import AsyncOpenAI

from config import OPENAI_API_KEY, LLM_MODEL, TOP_N_EMOTIONS, TEXT_EMOTION_PROMPT
from models import EmotionScore, EmotionSource

logger = logging.getLogger("text_emotion")

_client: AsyncOpenAI | None = None


def _get_client() -> AsyncOpenAI:
    global _client
    if _client is None:
        _client = AsyncOpenAI(api_key=OPENAI_API_KEY)
    return _client


def _parse_json_blob(raw: str) -> dict:
    """Extract the first JSON object from the model's reply."""
    # Strip markdown code fences if present
    cleaned = re.sub(r"```(?:json)?|```", "", raw).strip()
    return json.loads(cleaned)


async def detect_text_emotions(text: str, top_n: int = TOP_N_EMOTIONS) -> List[EmotionScore]:
    """
    Ask GPT to analyse `text` and return emotion scores as JSON.
    Returns a list of EmotionScore sorted by score descending.
    """
    if not OPENAI_API_KEY:
        logger.warning("OPENAI_API_KEY not set — skipping text emotion detection")
        return []

    if not text or not text.strip():
        return []

    prompt = TEXT_EMOTION_PROMPT.format(top_n=top_n, text=text.strip())

    try:
        client = _get_client()
        resp = await client.chat.completions.create(
            model=LLM_MODEL,
            messages=[{"role": "user", "content": prompt}],
            max_tokens=256,
            temperature=0.0,  # deterministic for classification
        )
        raw = resp.choices[0].message.content or "{}"
        scores: dict = _parse_json_blob(raw)

        sorted_scores = sorted(scores.items(), key=lambda kv: kv[1], reverse=True)[:top_n]
        return [
            EmotionScore(
                name=name,
                score=min(max(float(score), 0.0), 1.0),
                source=EmotionSource.TEXT,
            )
            for name, score in sorted_scores
        ]

    except json.JSONDecodeError as exc:
        logger.warning("Failed to parse text-emotion JSON: %s", exc)
        return []
    except Exception as exc:
        logger.error("Text emotion detection error: %s", exc, exc_info=True)
        return []
