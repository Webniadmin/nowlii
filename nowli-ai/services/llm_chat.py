"""
services/llm_chat.py
====================
Streaming GPT response generator that injects the user's current
emotion state into the system prompt so the model adapts its tone.
"""
from __future__ import annotations

import logging
from typing import AsyncIterator, List

from openai import AsyncOpenAI

from config import (
    OPENAI_API_KEY,
    LLM_MODEL,
    LLM_MAX_TOKENS,
    LLM_TEMPERATURE,
    SYSTEM_PROMPT_TEMPLATE,
)
from models import ChatMessage, EmotionScore

logger = logging.getLogger("llm_chat")

_client: AsyncOpenAI | None = None


def _get_client() -> AsyncOpenAI:
    global _client
    if _client is None:
        _client = AsyncOpenAI(api_key=OPENAI_API_KEY)
    return _client


def _build_system_prompt(emotions: List[EmotionScore]) -> str:
    if emotions:
        parts = [f"{e.name} ({e.score:.2f})" for e in emotions[:5]]
        emotion_context = ", ".join(parts)
    else:
        emotion_context = "neutral / unknown"
    return SYSTEM_PROMPT_TEMPLATE.format(emotion_context=emotion_context)


async def stream_chat_response(
    user_message: str,
    history: List[ChatMessage],
    emotions: List[EmotionScore],
) -> AsyncIterator[str]:
    """
    Yields GPT response tokens one by one.

    Parameters
    ----------
    user_message : str
        The current user turn.
    history : list[ChatMessage]
        Previous conversation turns (role + content).
    emotions : list[EmotionScore]
        The combined emotion scores from /emotion/combined (or empty list).

    Yields
    ------
    str
        Individual text tokens from the streaming GPT response.
    """
    client = _get_client()

    system_prompt = _build_system_prompt(emotions)

    messages = [{"role": "system", "content": system_prompt}]

    # Include conversation history (cap at last 20 turns for context window)
    for msg in history[-20:]:
        messages.append({"role": msg.role, "content": msg.content})

    messages.append({"role": "user", "content": user_message})

    logger.info(
        "Streaming GPT response | model=%s | emotions=%s | history_len=%d",
        LLM_MODEL,
        [e.name for e in emotions[:3]],
        len(history),
    )

    try:
        stream = await client.chat.completions.create(
            model=LLM_MODEL,
            messages=messages,
            max_tokens=LLM_MAX_TOKENS,
            temperature=LLM_TEMPERATURE,
            stream=True,
        )

        async for chunk in stream:
            delta = chunk.choices[0].delta
            if delta and delta.content:
                yield delta.content

    except Exception as exc:
        logger.error("LLM streaming error: %s", exc, exc_info=True)
        raise
