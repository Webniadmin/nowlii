"""
routers/chat.py
===============
API 2 — WS /chat/stream

Real-time streaming chat WebSocket that adapts GPT's tone based on the
user's current emotion state.

Protocol (client → server)
--------------------------
Send a JSON object:
  {
    "message":  "Hello, I'm feeling anxious today",
    "history":  [{"role": "user", "content": "..."}, ...],   # optional
    "emotions": [{"name": "Anxiety", "score": 0.82, "source": "combined"}, ...]  # optional
  }

Protocol (server → client)
--------------------------
Stream of JSON frames:

  {"type": "emotion",  "emotion": {"name": "Anxiety", "score": 0.82, "source": "combined"}}
  {"type": "token",    "content": "I"}
  {"type": "token",    "content": " hear"}
  ...
  {"type": "done",     "content": "<full assembled reply>"}

  On error:
  {"type": "error",    "error": "...message..."}

Emotion update mid-conversation
--------------------------------
After the user sends a message the server:
  1. Re-detects text emotions from the new message (live update).
  2. Merges with any emotions the client passed in (from /emotion/combined).
  3. Injects the merged emotion state into the system prompt.
  4. Streams the GPT response token by token.
  5. Sends {"type": "done"} with the full assembled reply.
"""
from __future__ import annotations

import json
import logging
from typing import List

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from pydantic import ValidationError

from models import ChatMessage, ChatRequest, EmotionScore, EmotionState, StreamChunk
from services.text_emotion import detect_text_emotions
from services.emotion_merger import merge_emotions
from services.llm_chat import stream_chat_response

logger = logging.getLogger("router.chat")
router = APIRouter(tags=["Streaming Chat"])


async def _send(ws: WebSocket, chunk: StreamChunk) -> None:
    await ws.send_text(chunk.model_dump_json(exclude_none=True))


@router.websocket("/chat/stream")
async def chat_stream(ws: WebSocket):
    """
    WebSocket endpoint for emotion-aware real-time streaming chat.
    """
    await ws.accept()
    logger.info("Chat WebSocket connected: %s", ws.client)

    # Per-connection emotion state (updated each turn)
    emotion_state = EmotionState()

    try:
        while True:
            # ── Receive client message ────────────────────────────────────
            raw = await ws.receive_text()

            try:
                payload = json.loads(raw)
                req = ChatRequest(**payload)
            except (json.JSONDecodeError, ValidationError, TypeError) as exc:
                await _send(ws, StreamChunk(type="error", error=f"Invalid request: {exc}"))
                continue

            # ── 1. Detect text emotions from the new user message ─────────
            live_text_emotions: List[EmotionScore] = await detect_text_emotions(req.message)

            # ── 2. Merge with any client-supplied emotions (from /emotion/combined) ──
            merged = merge_emotions(
                voice=req.emotions,          # client passed voice/combined emotions
                text=live_text_emotions,     # freshly detected from text
                top_n=5,
            )
            emotion_state.update(merged)

            logger.info(
                "Turn emotion state: %s",
                [(e.name, round(e.score, 2)) for e in emotion_state.combined[:3]],
            )

            # ── 3. Broadcast dominant emotion to client ───────────────────
            if emotion_state.dominant:
                await _send(ws, StreamChunk(type="emotion", emotion=emotion_state.dominant))

            # ── 4. Stream GPT response ────────────────────────────────────
            full_reply = ""
            try:
                async for token in stream_chat_response(
                    user_message=req.message,
                    history=req.history,
                    emotions=emotion_state.combined,
                ):
                    full_reply += token
                    await _send(ws, StreamChunk(type="token", content=token))

            except Exception as exc:
                logger.error("LLM error: %s", exc, exc_info=True)
                await _send(ws, StreamChunk(type="error", error="LLM generation failed"))
                continue

            # ── 5. Done frame with full assembled reply ───────────────────
            await _send(ws, StreamChunk(type="done", content=full_reply))
            logger.info("Turn complete | reply_len=%d", len(full_reply))

    except WebSocketDisconnect:
        logger.info("Chat WebSocket disconnected: %s", ws.client)
    except Exception as exc:
        logger.error("Unexpected WebSocket error: %s", exc, exc_info=True)
        try:
            await _send(ws, StreamChunk(type="error", error=str(exc)))
        except Exception:
            pass
