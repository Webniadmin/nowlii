"""
routers/emotion.py
==================
API 1 — POST /emotion/combined

Accepts a multipart form with:
  - audio_file : WAV/PCM audio (optional)
  - text       : plain text (optional)

At least one of audio_file or text must be supplied.

Flow
----
1. Transcribe audio → Whisper (if audio supplied)
2. Run Hume prosody on audio   → voice_emotions (if audio supplied)
3. Run GPT text classifier on transcript + text → text_emotions
4. Merge both with weighted average              → combined_emotions
5. Return full CombinedEmotionResponse
"""
from __future__ import annotations

import logging
import os
import tempfile
import time
from typing import Optional

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from openai import AsyncOpenAI

from config import OPENAI_API_KEY
from models import CombinedEmotionResponse, EmotionScore, EmotionSource
from services.hume_emotion import detect_voice_emotions
from services.text_emotion import detect_text_emotions
from services.emotion_merger import merge_emotions

logger = logging.getLogger("router.emotion")
router = APIRouter(tags=["Emotion Detection"])

_openai: AsyncOpenAI | None = None


def _get_openai() -> AsyncOpenAI:
    global _openai
    if _openai is None:
        _openai = AsyncOpenAI(api_key=OPENAI_API_KEY)
    return _openai


async def _transcribe(audio_path: str) -> str:
    """Transcribe audio file using OpenAI Whisper."""
    client = _get_openai()
    with open(audio_path, "rb") as f:
        result = await client.audio.transcriptions.create(
            model="whisper-1",
            file=f,
        )
    return result.text


@router.post(
    "/emotion/combined",
    response_model=CombinedEmotionResponse,
    summary="Detect emotions from voice + text",
    description=(
        "Upload an audio file and/or plain text. "
        "Returns voice emotions (Hume prosody), text emotions (GPT), "
        "and a merged combined score with the dominant emotion."
    ),
)
async def combined_emotion(
    audio_file: Optional[UploadFile] = File(None, description="WAV audio file (16 kHz mono recommended)"),
    text: Optional[str] = Form(None, description="Plain text to analyse"),
):
    if audio_file is None and not text:
        raise HTTPException(
            status_code=422,
            detail="Provide at least one of: audio_file, text",
        )

    t0 = time.perf_counter()

    transcript = ""
    voice_emotions: list[EmotionScore] = []
    text_emotions:  list[EmotionScore] = []
    tmp_path: str | None = None

    # ── 1. Handle audio ──────────────────────────────────────────────────────
    if audio_file is not None:
        suffix = os.path.splitext(audio_file.filename or "audio.wav")[1] or ".wav"
        fd, tmp_path = tempfile.mkstemp(suffix=suffix)
        try:
            os.close(fd)
            content = await audio_file.read()
            with open(tmp_path, "wb") as f:
                f.write(content)

            logger.info("Audio saved to %s (%d bytes)", tmp_path, len(content))

            # Run Whisper + Hume in parallel for speed
            import asyncio
            transcript, voice_emotions = await asyncio.gather(
                _transcribe(tmp_path),
                detect_voice_emotions(tmp_path),
            )
            logger.info("Transcript: %r | Voice emotions: %s", transcript, voice_emotions)

        finally:
            if tmp_path and os.path.exists(tmp_path):
                os.unlink(tmp_path)

    # ── 2. Combine transcript + user text for text emotion ───────────────────
    combined_text = " ".join(filter(None, [transcript, text])).strip()
    if combined_text:
        text_emotions = await detect_text_emotions(combined_text)
        logger.info("Text emotions: %s", text_emotions)

    # ── 3. Merge ─────────────────────────────────────────────────────────────
    combined = merge_emotions(voice_emotions, text_emotions, top_n=5)
    dominant = combined[0] if combined else None

    elapsed_ms = (time.perf_counter() - t0) * 1000

    return CombinedEmotionResponse(
        transcript=transcript,
        voice_emotions=voice_emotions,
        text_emotions=text_emotions,
        combined_emotions=combined,
        dominant_emotion=dominant,
        processing_ms=round(elapsed_ms, 1),
    )
