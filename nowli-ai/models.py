"""
models.py — all shared Pydantic schemas and dataclasses.
"""
from __future__ import annotations

import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


# ── Enums ────────────────────────────────────────────────────────────────────

class EmotionSource(str, Enum):
    VOICE = "voice"
    TEXT  = "text"
    COMBINED = "combined"


# ── API 1: /emotion/combined ─────────────────────────────────────────────────

class EmotionScore(BaseModel):
    name:   str   = Field(..., description="Emotion label")
    score:  float = Field(..., ge=0.0, le=1.0, description="Confidence score")
    source: EmotionSource = Field(default=EmotionSource.COMBINED)


class CombinedEmotionResponse(BaseModel):
    """Response from POST /emotion/combined"""
    transcript:      str                      = Field(..., description="Whisper transcript of the audio")
    voice_emotions:  List[EmotionScore]       = Field(default_factory=list, description="Hume prosody emotions")
    text_emotions:   List[EmotionScore]       = Field(default_factory=list, description="GPT text emotions")
    combined_emotions: List[EmotionScore]     = Field(default_factory=list, description="Merged & weighted final emotions")
    dominant_emotion: Optional[EmotionScore]  = Field(None, description="Single highest-confidence emotion")
    processing_ms:   float                    = Field(..., description="Total processing time in ms")


# ── API 2: /chat/stream ───────────────────────────────────────────────────────

class ChatMessage(BaseModel):
    role:    str = Field(..., description="'user' or 'assistant'")
    content: str


class ChatRequest(BaseModel):
    """
    Sent by the client over WebSocket as JSON at the start of a turn.
    """
    message:   str                        = Field(..., description="User's text message")
    history:   List[ChatMessage]          = Field(default_factory=list, description="Previous turns")
    emotions:  List[EmotionScore]         = Field(default_factory=list, description="Current emotions from /emotion/combined")


class StreamChunk(BaseModel):
    """
    Each server → client frame over the WebSocket.
    """
    type:    str          = Field(..., description="'token' | 'emotion' | 'done' | 'error'")
    content: Optional[str] = None
    emotion: Optional[EmotionScore] = None
    error:   Optional[str] = None


# ── Internal dataclasses ─────────────────────────────────────────────────────

@dataclass
class EmotionState:
    """Live emotion state tracked per WebSocket session."""
    combined: List[EmotionScore] = field(default_factory=list)
    dominant: Optional[EmotionScore] = None
    updated_at: float = field(default_factory=time.time)

    def update(self, emotions: List[EmotionScore]) -> None:
        self.combined = sorted(emotions, key=lambda e: e.score, reverse=True)
        self.dominant = self.combined[0] if self.combined else None
        self.updated_at = time.time()

    def as_context_string(self) -> str:
        if not self.combined:
            return "unknown / neutral"
        parts = [f"{e.name} ({e.score:.2f})" for e in self.combined[:5]]
        return ", ".join(parts)
