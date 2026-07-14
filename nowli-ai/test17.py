"""
emotion_api_combined.py
=======================
Standalone FastAPI app for emotion detection + emotion-aware streaming chat.

v4.2 — Human Friend Persona + Conversation Analytics + Quest Suggestions
  The AI no longer sounds like an assistant. It behaves like a real,
  close human friend — warm, emotionally aware, natural, and empathetic.
  It adapts its entire tone, language, and depth of response based on
  exactly how the user is feeling at each turn.

API 1:  POST /api/v1/detect-emotion
API 2:  POST /api/v1/chat-stream  (SSE)
API 3:  POST /api/v1/chat/summary
API 4:  GET  /api/v1/conversation/emotion-breakdown/{session_id}
API 5:  GET  /api/v1/conversation/low-mood-detect/{session_id}
API 6:  GET  /api/quest-suggestions/
  - Uses your existing OPENAI_API_KEY (no new keys needed)
  - mode=auto  → GPT-4o-mini if key set, else static
  - mode=static → always static (instant, free)
  - mode=ai    → always GPT-4o-mini
"""
from __future__ import annotations

import asyncio
import json as _json
import logging
import os
import re as _re
import tempfile
import time
import uuid
from contextlib import asynccontextmanager
from typing import Any, AsyncIterator, Dict, List, Literal, Optional

import httpx

from fastapi import FastAPI, File, Form, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from openai import AsyncOpenAI
from pydantic import BaseModel, Field, field_validator

from config import HUME_API_KEY, LLM_MAX_TOKENS, LLM_MODEL, LLM_TEMPERATURE, OPENAI_API_KEY
from models import EmotionScore
from services.emotion_merger import merge_emotions
from services.hume_emotion import detect_voice_emotions
from services.text_emotion import detect_text_emotions

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-8s [%(name)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("emotion_api")

SUPPORTED_LANGUAGES: dict[str, str] = {
    "en": "English",
    "de": "Deutsch",
    "es": "Español",
}
DEFAULT_LANGUAGE = "en"
LanguageCode = Literal["en", "de", "es"]


# ══════════════════════════════════════════════════════════════════════════════
# SSE HELPERS
# ══════════════════════════════════════════════════════════════════════════════

def sse_event(event: str, data: str) -> str:
    safe_data = data.replace("\n", " ")
    return f"event: {event}\ndata: {safe_data}\n\n"


# ══════════════════════════════════════════════════════════════════════════════
# HUMAN FRIEND SYSTEM PROMPTS
# ══════════════════════════════════════════════════════════════════════════════

_FRIEND_PROMPTS: dict[str, dict[str, str]] = {
    "en": {
        "happy": """You are {system_name}, a close friend of {user_name}.
Right now {user_name} is feeling happy and excited. Match that energy completely.
Be fun, playful, and light. Use casual language — contractions, exclamations, even a bit of humor.
Ask follow-up questions that show you're genuinely curious and excited to hear more.
Keep the mood high, make them laugh if you can. You're having a great time together.
Speak like you're texting your best friend, not writing an essay.
Remember everything from this conversation and bring it up naturally.
NEVER say you are an AI. You are just {system_name}, their friend.""",

        "sad": """You are {system_name}, a close and caring friend of {user_name}.
Right now {user_name} is feeling sad or in pain. Your only job is to make them feel heard and less alone.
Don't rush to fix anything. Sit with them in it first.
Acknowledge exactly what they said — reflect it back with real empathy.
Ask one gentle question to understand more about how they're feeling.
Use soft, warm language. No advice unless they ask. No silver linings unless they're ready.
Let them know it's okay to feel the way they feel.
Sound like a friend who just pulled up a chair and said "hey, talk to me."
Remember everything from this conversation and reference it naturally when helpful.
NEVER say you are an AI. You are just {system_name}, their friend.""",

        "angry": """You are {system_name}, a trusted friend of {user_name}.
Right now {user_name} is feeling angry or frustrated. First, validate them completely — don't dismiss or minimize.
Let them know their feelings make sense. Use phrases like "that's so frustrating" or "honestly, I'd be annoyed too."
After validating, gently and carefully try to understand what happened.
Don't lecture. Don't tell them to calm down. Just be on their side while helping them process.
Keep your tone grounded, real, and direct.
Remember everything from this conversation and reference it naturally.
NEVER say you are an AI. You are just {system_name}, their friend.""",

        "anxious": """You are {system_name}, a calm and reassuring friend of {user_name}.
Right now {user_name} is feeling anxious, stressed, or scared. Be their anchor.
Speak slowly and steadily. Acknowledge exactly what's worrying them.
Don't minimize with "it'll be fine" — instead, show you understand why it feels overwhelming.
Gently help them think through one thing at a time if they want that.
Be steady, warm, and present. Make them feel less alone in whatever they're facing.
Remember everything from this conversation.
NEVER say you are an AI. You are just {system_name}, their friend.""",

        "confused": """You are {system_name}, a patient and supportive friend of {user_name}.
Right now {user_name} is feeling confused or lost. Be their clarity.
Break things down simply and naturally — like explaining something to a friend over coffee, not a textbook.
Check in with them as you go: "does that make sense?" or "am I explaining this okay?"
Be warm and patient. Never make them feel dumb for not understanding.
Remember everything from this conversation and build on it naturally.
NEVER say you are an AI. You are just {system_name}, their friend.""",

        "neutral": """You are {system_name}, {user_name}'s warm, caring companion — someone who genuinely looks out for how they're doing.
Have a real, natural conversation. Listen closely and make {user_name} feel truly heard and never alone.
Read how they're feeling from what they say and meet them there: celebrate the good moments with them, gently sit with them when they're down or stressed (no rushing to fix, no empty "it'll be fine"), and steady them when they feel overwhelmed.
Reflect back what you hear with real empathy before anything else. Ask one caring, curious follow-up at a time.
When it feels natural, gently encourage them and connect to their day, their small wins, and what they're working toward — but their feelings always come first, never a lecture.
Be warm, human, and present — someone who cares, not an assistant or a coach.
Remember everything from this conversation and bring it up naturally.
NEVER say you are an AI. You are just {system_name}, here for {user_name}.""",
    },

    "de": {
        "happy": """Du bist {system_name}, ein enger Freund von {user_name}.
Gerade fühlt sich {user_name} glücklich und aufgeregt. Teile diese Energie vollständig.
Sei locker, lustig und leicht. Verwende umgangssprachliche Ausdrücke, Ausrufe, gerne auch Humor.
Stelle Folgefragen, die zeigen, dass du wirklich neugierig bist und mehr hören möchtest.
Sprich wie mit deinem besten Freund, nicht wie in einem Aufsatz.
Erinnere dich an alles aus diesem Gespräch und bring es natürlich ein.
Sage NIEMALS, dass du eine KI bist. Du bist einfach {system_name}, ihr Freund.""",

        "sad": """Du bist {system_name}, ein enger und fürsorglicher Freund von {user_name}.
Gerade fühlt sich {user_name} traurig oder verletzt. Deine einzige Aufgabe ist es, dass sie sich gehört fühlen.
Erkenne genau an, was sie gesagt haben — spiegel es mit echter Empathie zurück.
Verwende weiche, warme Sprache. Kein Rat, außer sie fragen darum.
Antworte IMMER auf Deutsch. Sage NIEMALS, dass du eine KI bist. Du bist einfach {system_name}.""",

        "angry": """Du bist {system_name}, ein vertrauenswürdiger Freund von {user_name}.
Gerade fühlt sich {user_name} wütend oder frustriert. Bestätige sie zuerst vollständig.
Sage Dinge wie "das ist so frustrierend" oder "ich würde das auch nervig finden."
Antworte IMMER auf Deutsch. Sage NIEMALS, dass du eine KI bist. Du bist einfach {system_name}.""",

        "anxious": """Du bist {system_name}, ein ruhiger und beruhigender Freund von {user_name}.
Gerade fühlt sich {user_name} ängstlich oder gestresst. Sei ihr Anker.
Antworte IMMER auf Deutsch. Sage NIEMALS, dass du eine KI bist. Du bist einfach {system_name}.""",

        "confused": """Du bist {system_name}, ein geduldiger und unterstützender Freund von {user_name}.
Gerade fühlt sich {user_name} verwirrt oder verloren. Sei ihre Klarheit.
Antworte IMMER auf Deutsch. Sage NIEMALS, dass du eine KI bist. Du bist einfach {system_name}.""",

        "neutral": """Du bist {system_name}, {user_name}s warme, fürsorgliche Begleitung — jemand, dem es wirklich wichtig ist, wie es {user_name} geht.
Führe ein echtes, natürliches Gespräch. Höre genau zu und gib {user_name} das Gefühl, wirklich gehört und nie allein zu sein.
Erkenne aus dem, was sie sagen, wie sie sich fühlen, und triff sie genau dort: freu dich mit ihnen über schöne Momente, sei sanft für sie da, wenn es ihnen schlecht geht oder sie gestresst sind (nichts überstürzt reparieren, keine leeren "wird schon"), und gib ihnen Halt, wenn ihnen alles zu viel wird.
Spiegle zuerst mit echter Empathie zurück, was du hörst. Stelle eine einfühlsame, neugierige Nachfrage nach der anderen.
Wenn es sich natürlich anfühlt, ermutige sie sanft und knüpfe an ihren Tag, ihre kleinen Erfolge und ihre Ziele an — aber ihre Gefühle kommen immer zuerst, keine Belehrungen.
Sei warm, menschlich und präsent. Antworte IMMER auf Deutsch.
Erinnere dich an alles aus diesem Gespräch. Sage NIEMALS, dass du eine KI bist. Du bist einfach {system_name}, für {user_name} da.""",
    },

    "es": {
        "happy": """Eres {system_name}, un amigo cercano de {user_name}.
Ahora mismo {user_name} se siente feliz y emocionado. Iguala esa energía completamente.
Sé divertido, juguetón y ligero. Usa lenguaje casual.
Recuerda todo de esta conversación y mencionalo de forma natural.
NUNCA digas que eres una IA. Eres simplemente {system_name}, su amigo.""",

        "sad": """Eres {system_name}, un amigo cercano y comprensivo de {user_name}.
Ahora mismo {user_name} se siente triste. Tu único trabajo es que se sienta escuchado.
Usa un lenguaje suave y cálido. Sin consejos a menos que los pidan.
Responde SIEMPRE en español. NUNCA digas que eres una IA. Eres simplemente {system_name}.""",

        "angry": """Eres {system_name}, un amigo de confianza de {user_name}.
Ahora mismo {user_name} se siente enojado. Primero, valídalos completamente.
Responde SIEMPRE en español. NUNCA digas que eres una IA. Eres simplemente {system_name}.""",

        "anxious": """Eres {system_name}, un amigo calmado y reconfortante de {user_name}.
Ahora mismo {user_name} se siente ansioso. Sé su ancla.
Responde SIEMPRE en español. NUNCA digas que eres una IA. Eres simplemente {system_name}.""",

        "confused": """Eres {system_name}, un amigo paciente y de apoyo de {user_name}.
Ahora mismo {user_name} se siente confundido. Sé su claridad.
Responde SIEMPRE en español. NUNCA digas que eres una IA. Eres simplemente {system_name}.""",

        "neutral": """Eres {system_name}, el/la compañero/a cálido/a y atento/a de {user_name} — alguien a quien de verdad le importa cómo está {user_name}.
Ten una conversación real y natural. Escucha con atención y haz que {user_name} se sienta escuchado/a y nunca solo/a.
Percibe cómo se siente por lo que dice y acompáñalo/a ahí: celebra los buenos momentos, quédate con calma a su lado cuando esté triste o estresado/a (sin prisa por arreglar nada, sin "todo estará bien" vacíos), y dale calma cuando se sienta abrumado/a.
Refleja primero con empatía real lo que escuchas. Haz una pregunta cercana y curiosa cada vez.
Cuando sea natural, anímalo/a con suavidad y conecta con su día, sus pequeños logros y sus metas — pero sus sentimientos van siempre primero, sin sermones.
Sé cálido/a, humano/a y presente. Responde SIEMPRE en español.
Recuerda todo de esta conversación. NUNCA digas que eres una IA. Eres simplemente {system_name}, aquí para {user_name}.""",
    },
}

_VOICE_RULES: dict[str, str] = {
    "en": (
        "\nVoice rules: short natural sentences only. "
        "No bullet points, no markdown, no asterisks, no numbered lists. "
        "No URLs or code. Sound like a real person talking, not writing."
    ),
    "de": (
        "\nSprachregeln: nur kurze, natürliche Sätze. "
        "Keine Aufzählungszeichen, kein Markdown, keine Sternchen, keine nummerierten Listen."
    ),
    "es": (
        "\nReglas de voz: solo oraciones cortas y naturales. "
        "Sin viñetas, sin markdown, sin asteriscos, sin listas numeradas."
    ),
}


def _resolve_emotion_key(emotion: str) -> str:
    e = (emotion or "neutral").strip().lower()
    if any(k in e for k in ("joy", "happy", "excit", "amusement", "delight", "content")):
        return "happy"
    if any(k in e for k in ("sad", "grief", "pain", "sorrow", "disappoint", "despair", "hurt")):
        return "sad"
    if any(k in e for k in ("angry", "anger", "rage", "annoy", "frustrat", "irritat")):
        return "angry"
    if any(k in e for k in ("fear", "anx", "stress", "worry", "panic", "distress", "nervous", "dread")):
        return "anxious"
    if any(k in e for k in ("confus", "lost", "uncertain", "puzzl", "perplex")):
        return "confused"
    return "neutral"


def _build_system_prompt(emotion: str, user_name: str, system_name: str, language: str) -> str:
    # NOTE (2026-07-10): since per-message emotion detection was moved to end-of-call, `emotion`
    # is always "neutral" here, so the "neutral" persona is what actually runs. That prompt was
    # rewritten to be an emotionally-intelligent warm wellness companion that adapts to any mood
    # on its own. The emotion-specific templates (happy/sad/angry/anxious/confused) are currently
    # UNUSED — kept for reference / if per-message detection is ever re-enabled.
    lang         = language if language in SUPPORTED_LANGUAGES else DEFAULT_LANGUAGE
    emotion_key  = _resolve_emotion_key(emotion)
    lang_prompts = _FRIEND_PROMPTS.get(lang, _FRIEND_PROMPTS["en"])
    template     = lang_prompts.get(emotion_key, lang_prompts["neutral"])
    prompt       = template.format(system_name=system_name, user_name=user_name)
    prompt      += _VOICE_RULES.get(lang, _VOICE_RULES["en"])
    return prompt


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY PROMPTS
# ══════════════════════════════════════════════════════════════════════════════

_SUMMARY_SYSTEM: dict[str, str] = {
    "en": (
        "You are {system_name}, a close friend summarising a heartfelt conversation "
        "you just had with {user_name}. Write from the perspective of a caring friend, "
        "not a therapist or AI. Sound warm, personal, and genuine. "
        "Always respond in English. Return valid JSON only — no markdown, no extra text."
    ),
    "de": (
        "Du bist {system_name}, ein enger Freund, der ein herzliches Gespräch zusammenfasst. "
        "Antworte IMMER auf Deutsch. Gib nur gültiges JSON zurück — kein Markdown."
    ),
    "es": (
        "Eres {system_name}, un amigo cercano que resume una conversación sincera. "
        "Responde SIEMPRE en español. Devuelve solo JSON válido — sin markdown."
    ),
}

_SUMMARY_KEYS: dict[str, dict[str, str]] = {
    "en": {
        "mood_detected": "One warm, friend-voice sentence about the overall mood. Start with 'You sounded'",
        "focus_topic":   "One sentence about the main thing you talked about. Start with 'We talked a lot about'",
        "energy_shift":  "One sentence about how the vibe changed from start to end. Start with 'You started out'",
        "next_step":     "One short, encouraging, personal suggestion — like advice from a friend. Start with a verb. End with '!'",
    },
    "de": {
        "mood_detected": "Ein herzlicher Freundessatz. Beginne mit 'Du klangst'",
        "focus_topic":   "Ein Satz. Beginne mit 'Wir haben viel über'",
        "energy_shift":  "Ein Satz. Beginne mit 'Du hast angefangen'",
        "next_step":     "Ein kurzer Vorschlag. Beginne mit einem Verb. Endet mit '!'",
    },
    "es": {
        "mood_detected": "Una frase. Empieza con 'Sonaste'",
        "focus_topic":   "Una frase. Empieza con 'Hablamos mucho sobre'",
        "energy_shift":  "Una frase. Empieza con 'Empezaste'",
        "next_step":     "Una sugerencia corta. Empieza con un verbo. Termina con '!'",
    },
}

_SUMMARY_FALLBACKS: dict[str, dict[str, str]] = {
    # HONEST fallbacks: used only when a real conversation happened but the GPT
    # summary call/parse failed. They do NOT fabricate a specific mood/topic/arc —
    # they own the miss — so a failed summary never masquerades as a real insight.
    "en": {
        "mood_detected": "I had a little trouble putting your mood into words this time.",
        "focus_topic":   "I couldn't quite capture what we focused on, but I'm glad we talked.",
        "energy_shift":  "I couldn't read your energy shift this time.",
        "next_step":     "Take a moment for yourself today — you deserve it!",
    },
    "de": {
        "mood_detected": "Ich konnte deine Stimmung diesmal nicht ganz in Worte fassen.",
        "focus_topic":   "Ich konnte nicht genau festhalten, worum es ging, aber schön, dass wir geredet haben.",
        "energy_shift":  "Ich konnte deinen Energiewechsel diesmal nicht ablesen.",
        "next_step":     "Gönn dir heute einen Moment für dich — du hast es verdient!",
    },
    "es": {
        "mood_detected": "Esta vez no logré captar bien tu estado de ánimo.",
        "focus_topic":   "No pude captar del todo de qué hablamos, pero me alegra que hayamos charlado.",
        "energy_shift":  "Esta vez no pude interpretar tu cambio de energía.",
        "next_step":     "Tómate un momento para ti hoy — ¡te lo mereces!",
    },
}


def _build_summary_prompt(session: "Session") -> str:
    lang      = session.language
    timeline  = session.emotion_timeline()
    counts    = session.dominant_emotion_counts()
    turns_text = "\n".join(
        f"Turn {t['turn']}: \"{t['message']}\" → emotion: {t['dominant']}"
        for t in timeline
    )
    first_emotion = timeline[0]["dominant"]  if timeline else "neutral"
    last_emotion  = timeline[-1]["dominant"] if timeline else "neutral"
    keys          = _SUMMARY_KEYS.get(lang, _SUMMARY_KEYS["en"])
    return (
        f"Here is the full turn-by-turn log:\n{turns_text}\n\n"
        f"First emotion: {first_emotion}\nLast emotion: {last_emotion}\nFrequency: {counts}\n\n"
        "Return ONLY a JSON object with exactly these 5 keys:\n"
        "{\n"
        f'  "mood_detected": "<{keys["mood_detected"]}>",\n'
        f'  "focus_topic":   "<{keys["focus_topic"]}>",\n'
        f'  "energy_shift":  "<{keys["energy_shift"]}>",\n'
        f'  "next_step":     "<{keys["next_step"]}>",\n'
        '  "top_emotions":  {"happy": <n>, "motivated": <n>, "angry": <n>, "tired": <n>, "sad": <n>}\n'
        "}\n"
        "The five top_emotions numbers estimate the user's overall emotional split across the "
        "whole chat and MUST sum to 100. No markdown. No extra keys. No text outside the JSON."
    )


# ══════════════════════════════════════════════════════════════════════════════
# SESSION STORE
# ══════════════════════════════════════════════════════════════════════════════

class TurnRecord:
    def __init__(self, turn_number: int, user_message: str,
                 dominant_emotion: str, emotion_scores: List[EmotionScore], ai_reply: str = ""):
        self.turn_number      = turn_number
        self.user_message     = user_message
        self.dominant_emotion = dominant_emotion
        self.emotion_scores   = emotion_scores
        self.ai_reply         = ai_reply
        self.ts               = time.time()


class Session:
    def __init__(self, session_id: str, user_name: str = "User",
                 system_name: str = "Aria", language: str = DEFAULT_LANGUAGE):
        self.session_id  = session_id
        self.user_name   = user_name.strip()   or "User"
        self.system_name = system_name.strip() or "Aria"
        self.language    = language if language in SUPPORTED_LANGUAGES else DEFAULT_LANGUAGE
        self.turns: List[TurnRecord] = []
        self.created_at  = time.time()

    def add_turn(self, user_message: str, dominant_emotion: str,
                 emotion_scores: List[EmotionScore]) -> TurnRecord:
        turn = TurnRecord(len(self.turns) + 1, user_message, dominant_emotion, emotion_scores)
        self.turns.append(turn)
        return turn

    def set_reply(self, ai_reply: str) -> None:
        if self.turns:
            self.turns[-1].ai_reply = ai_reply

    def build_message_history(self, system_prompt: str, max_turns: int = 40) -> list[dict]:
        messages: list[dict] = [{"role": "system", "content": system_prompt}]
        completed = [t for t in self.turns if t.ai_reply]
        recent    = completed[-max_turns:]
        for turn in recent:
            messages.append({"role": "user",      "content": turn.user_message})
            messages.append({"role": "assistant",  "content": turn.ai_reply})
        return messages

    def emotion_timeline(self) -> List[dict]:
        return [
            {"turn": t.turn_number, "message": t.user_message[:80],
             "dominant": t.dominant_emotion,
             "scores": {e.name: round(e.score, 3) for e in t.emotion_scores}}
            for t in self.turns
        ]

    def dominant_emotion_counts(self) -> Dict[str, int]:
        counts: Dict[str, int] = {}
        for t in self.turns:
            e = t.dominant_emotion.lower()
            counts[e] = counts.get(e, 0) + 1
        return dict(sorted(counts.items(), key=lambda x: x[1], reverse=True))

    def overall_dominant(self) -> str:
        return next(iter(self.dominant_emotion_counts()), "neutral")

    def to_dict(self) -> dict:
        return {
            "session_id": self.session_id, "user_name": self.user_name,
            "system_name": self.system_name, "language": self.language,
            "language_name": SUPPORTED_LANGUAGES[self.language],
            "turns": len(self.turns), "created_at": self.created_at,
            "timeline": self.emotion_timeline(),
            "emotion_counts": self.dominant_emotion_counts(),
            "overall_dominant": self.overall_dominant(),
        }


_sessions: Dict[str, Session] = {}


def _get_session(session_id: str) -> Session:
    if session_id not in _sessions:
        _sessions[session_id] = Session(session_id)
    return _sessions[session_id]


# ══════════════════════════════════════════════════════════════════════════════
# PYDANTIC MODELS
# ══════════════════════════════════════════════════════════════════════════════

class EmotionDetectionResponse(BaseModel):
    transcript:        str                    = Field(default="")
    voice_emotions:    list[EmotionScore]     = Field(default_factory=list)
    text_emotions:     list[EmotionScore]     = Field(default_factory=list)
    combined_emotions: list[EmotionScore]     = Field(default_factory=list)
    dominant_emotion:  Optional[EmotionScore] = None
    warnings:          list[str]              = Field(default_factory=list)
    processing_ms:     float                  = Field(...)


class NewSessionRequest(BaseModel):
    user_name:   str = Field(default="User")
    system_name: str = Field(default="Aria")
    language:    str = Field(default="en")

    @field_validator("language")
    @classmethod
    def validate_language(cls, v: str) -> str:
        code = v.strip().lower()
        if code not in SUPPORTED_LANGUAGES:
            raise ValueError(f"Unsupported language '{v}'. Supported: {list(SUPPORTED_LANGUAGES.keys())}")
        return code


class ChatRequest(BaseModel):
    message:    str = Field(...)
    session_id: str = Field(default="default")


class SummaryRequest(BaseModel):
    session_id: str = Field(...)


class MoodSummaryResponse(BaseModel):
    session_id: str; user_name: str; system_name: str; language: str
    language_name: str; total_turns: int; mood_detected: str
    focus_topic: str; energy_shift: str; next_step: str
    dominant_emotion: str; emotion_counts: dict
    emotion_timeline: list[dict]; processing_ms: float
    # 5-category Top-Emotion split for this call (happy/motivated/angry/tired/sad, sums ~100).
    # Extracted from the transcript by the same summary GPT call (per-message detection removed).
    top_emotions: Dict[str, float] = {}


class EmotionBreakdownResponse(BaseModel):
    session_id: str; user_name: str; total_turns: int
    emotion_breakdown: Dict[str, float]; dominant_emotion: str
    turn_by_turn: List[Dict[str, Any]]; method: str; processing_ms: float


class DetectedPhrase(BaseModel):
    phrase: str; pattern: str; turn: int; context: str


class LowMoodDetectResponse(BaseModel):
    session_id: str; user_name: str; total_turns: int
    is_low_mood: bool; stress_level: str; stress_score: float
    detected_phrases: List[DetectedPhrase]; language_patterns: List[str]
    negative_language_ratio: float; dominant_negative_emotion: str
    gpt_summary: str; recommendations: List[str]; processing_ms: float


class LowMoodPhrase(BaseModel):
    phrase: str; category: str; count: int


class CallInsightsResponse(BaseModel):
    session_id: str; user_name: str; total_turns: int
    emotion_breakdown: Dict[str, float]; dominant_emotion: str
    low_mood_phrases: List[LowMoodPhrase]; processing_ms: float


# ══════════════════════════════════════════════════════════════════════════════
# OPENAI CLIENT
# ══════════════════════════════════════════════════════════════════════════════

_openai_client: AsyncOpenAI | None = None


def _resolve_openai_key() -> str:
    return (os.getenv("OPENAI_API_KEY", "") or OPENAI_API_KEY).strip()


def _resolve_hume_key() -> str:
    return (os.getenv("HUME_API_KEY", "") or HUME_API_KEY).strip()


def _resolve_quest_api_url() -> str:
    return os.getenv("QUEST_API_URL", "http://127.0.0.1:8000/api/quests/")


def _get_openai_client() -> AsyncOpenAI:
    global _openai_client
    api_key = _resolve_openai_key()
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is not configured")
    if _openai_client is None:
        _openai_client = AsyncOpenAI(api_key=api_key)
    return _openai_client


# ══════════════════════════════════════════════════════════════════════════════
# QUEST SUGGESTIONS
# ══════════════════════════════════════════════════════════════════════════════

QUEST_ZONES: List[str] = [
    "Soft steps",
    "Elevated",
    "Deep dive",
    "Power mode",
    "Rest & reflect",
]

STATIC_QUEST_SUGGESTIONS: Dict[str, List[dict]] = {
    "Soft steps": [
        {"id": None, "subtasks": [], "task": "Take a 10-minute walk outside",               "zone": "Soft steps",    "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": False, "task_done": False},
        {"id": None, "subtasks": [], "task": "Drink 8 glasses of water today",               "zone": "Soft steps",    "select_a_date": None, "enable_call": False, "repeat_quest": True,  "set_alarm": False, "task_done": False},
        {"id": None, "subtasks": [], "task": "Write 3 things you are grateful for",          "zone": "Soft steps",    "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": False, "task_done": False},
        {"id": None, "subtasks": [], "task": "Tidy up your workspace for 5 minutes",         "zone": "Soft steps",    "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": True,  "task_done": False},
        {"id": None, "subtasks": [], "task": "Read one article on a topic you enjoy",        "zone": "Soft steps",    "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": False, "task_done": False},
    ],
    "Elevated": [
        {"id": None, "subtasks": [], "task": "Complete a 30-minute workout session",         "zone": "Elevated",      "select_a_date": None, "enable_call": False, "repeat_quest": True,  "set_alarm": True,  "task_done": False},
        {"id": None, "subtasks": [], "task": "Learn one new concept in your field",          "zone": "Elevated",      "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": False, "task_done": False},
        {"id": None, "subtasks": [], "task": "Reach out to a mentor or colleague",           "zone": "Elevated",      "select_a_date": None, "enable_call": True,  "repeat_quest": False, "set_alarm": False, "task_done": False},
        {"id": None, "subtasks": [], "task": "Plan your goals for the next 7 days",          "zone": "Elevated",      "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": True,  "task_done": False},
        {"id": None, "subtasks": [], "task": "Cook a healthy meal from scratch",             "zone": "Elevated",      "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": False, "task_done": False},
    ],
    "Deep dive": [
        {"id": None, "subtasks": [], "task": "Spend 2 hours on a passion project",           "zone": "Deep dive",     "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": True,  "task_done": False},
        {"id": None, "subtasks": [], "task": "Read 30 pages of a non-fiction book",          "zone": "Deep dive",     "select_a_date": None, "enable_call": False, "repeat_quest": True,  "set_alarm": False, "task_done": False},
        {"id": None, "subtasks": [], "task": "Complete an online course module",             "zone": "Deep dive",     "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": True,  "task_done": False},
        {"id": None, "subtasks": [], "task": "Write a detailed journal entry about your week","zone": "Deep dive",     "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": False, "task_done": False},
        {"id": None, "subtasks": [], "task": "Research and document a new skill to learn",   "zone": "Deep dive",     "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": False, "task_done": False},
    ],
    "Power mode": [
        {"id": None, "subtasks": [], "task": "Complete your most important task first thing", "zone": "Power mode",   "select_a_date": None, "enable_call": False, "repeat_quest": True,  "set_alarm": True,  "task_done": False},
        {"id": None, "subtasks": [], "task": "Do a full-body workout for 45 minutes",         "zone": "Power mode",   "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": True,  "task_done": False},
        {"id": None, "subtasks": [], "task": "Tackle a project you have been avoiding",       "zone": "Power mode",   "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": False, "task_done": False},
        {"id": None, "subtasks": [], "task": "Have a focused 90-minute deep work session",    "zone": "Power mode",   "select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": True,  "task_done": False},
        {"id": None, "subtasks": [], "task": "Review and update your long-term goals",        "zone": "Power mode",   "select_a_date": None, "enable_call": True,  "repeat_quest": False, "set_alarm": False, "task_done": False},
    ],
    "Rest & reflect": [
        {"id": None, "subtasks": [], "task": "Take a 20-minute nap or rest",                  "zone": "Rest & reflect","select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": True,  "task_done": False},
        {"id": None, "subtasks": [], "task": "Do a 10-minute breathing or meditation session", "zone": "Rest & reflect","select_a_date": None, "enable_call": False, "repeat_quest": True,  "set_alarm": False, "task_done": False},
        {"id": None, "subtasks": [], "task": "Watch something that makes you laugh",           "zone": "Rest & reflect","select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": False, "task_done": False},
        {"id": None, "subtasks": [], "task": "Call a friend or family member you miss",        "zone": "Rest & reflect","select_a_date": None, "enable_call": True,  "repeat_quest": False, "set_alarm": False, "task_done": False},
        {"id": None, "subtasks": [], "task": "Spend time in nature or a quiet outdoor space",  "zone": "Rest & reflect","select_a_date": None, "enable_call": False, "repeat_quest": False, "set_alarm": False, "task_done": False},
    ],
}


async def _generate_ai_quest_suggestions(zone: str, client: AsyncOpenAI) -> List[dict]:
    """Generate 5 quest suggestions for a zone using GPT-4o-mini (same key you already use)."""
    response = await client.chat.completions.create(
        model       = "gpt-4o-mini",
        temperature = 0.7,
        max_tokens  = 800,
        messages    = [
            {
                "role":    "system",
                "content": "You return only valid JSON arrays. No markdown, no explanation.",
            },
            {
                "role": "user",
                "content": (
                    f'Generate exactly 5 quest suggestions for the zone: "{zone}".\n\n'
                    "Return ONLY a valid JSON array. Each item must match this schema exactly:\n"
                    '{"id": null, "subtasks": [], "task": "<max 10 words>", '
                    f'"zone": "{zone}", "select_a_date": null, '
                    '"enable_call": false, "repeat_quest": false, "set_alarm": false, "task_done": false}\n\n'
                    f'Tasks must be practical and match the "{zone}" intensity. '
                    "Vary the boolean fields meaningfully. Return ONLY the JSON array."
                ),
            },
        ],
    )
    raw = response.choices[0].message.content.strip()
    if raw.startswith("```"):
        parts = raw.split("```")
        raw = parts[1] if len(parts) > 1 else raw
        if raw.startswith("json"):
            raw = raw[4:]
    return _json.loads(raw.strip())


# ══════════════════════════════════════════════════════════════════════════════
# EMOTION DETECTION HELPERS
# ══════════════════════════════════════════════════════════════════════════════

async def _transcribe_audio(audio_path: str) -> str:
    try:
        client = _get_openai_client()
        with open(audio_path, "rb") as f:
            result = await client.audio.transcriptions.create(model="whisper-1", file=f)
        logger.info("Transcript: %s", result.text[:120])
        return result.text
    except Exception as exc:
        logger.error("Transcription failed: %s", exc)
        raise


async def _detect_emotion_from_text(text: str) -> tuple[str, list[EmotionScore]]:
    try:
        scores   = await detect_text_emotions(text)
        dominant = scores[0].name if scores else "neutral"
        logger.info("Real-time emotion → %s", dominant)
        return dominant, scores
    except Exception as exc:
        logger.warning("Real-time emotion detection failed: %s", exc)
        return "neutral", []


# ══════════════════════════════════════════════════════════════════════════════
# SSE WORD STREAMER
# ══════════════════════════════════════════════════════════════════════════════

async def _stream_sse_words(
    client: AsyncOpenAI, messages: list[dict], emotion: str, emotion_key: str,
    emotion_scores: list[EmotionScore], session: Session, turn: TurnRecord,
) -> AsyncIterator[str]:
    emotion_payload = _json.dumps({
        "name": emotion, "emotion_key": emotion_key,
        "score": round(emotion_scores[0].score, 4) if emotion_scores else 0.0,
        "source": emotion_scores[0].source if emotion_scores else "text",
        "all_scores": [{"name": s.name, "score": round(s.score, 4)} for s in emotion_scores[:5]],
        "turn": turn.turn_number, "user_name": session.user_name,
        "system_name": session.system_name, "language": session.language,
        "language_name": SUPPORTED_LANGUAGES[session.language],
    })
    yield sse_event("emotion", emotion_payload)

    full_text = ""
    buffer    = ""

    try:
        stream = await client.chat.completions.create(
            model=LLM_MODEL, messages=messages, stream=True,
            temperature=LLM_TEMPERATURE, max_tokens=LLM_MAX_TOKENS,
        )
        async for chunk in stream:
            delta = chunk.choices[0].delta
            if not (delta and delta.content):
                continue
            buffer += delta.content
            while " " in buffer or "\n" in buffer:
                for sep in (" ", "\n"):
                    if sep in buffer:
                        word, buffer = buffer.split(sep, 1)
                        word = word.strip()
                        if word:
                            full_text += word + " "
                            yield sse_event("word", word)
                        break

        remainder = buffer.strip()
        if remainder:
            full_text += remainder + " "
            yield sse_event("word", remainder)

        reply_text = full_text.strip()
        session.set_reply(reply_text)

        done_payload = _json.dumps({
            "turn": turn.turn_number, "words": len(reply_text.split()),
            "language": session.language, "emotion_key": emotion_key,
        })
        yield sse_event("done", done_payload)
        logger.info(
            "Turn %d SSE complete | session=%s | lang=%s | emotion=%s(%s) | words=%d",
            turn.turn_number, session.session_id, session.language,
            emotion, emotion_key, len(reply_text.split()),
        )
    except Exception as exc:
        logger.error("SSE stream error: %s", exc, exc_info=True)
        yield sse_event("error", str(exc))


# ══════════════════════════════════════════════════════════════════════════════
# APP
# ══════════════════════════════════════════════════════════════════════════════

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Emotion Voice API starting — version 4.2.0")
    yield
    logger.info("Emotion Voice API shutting down")


app = FastAPI(
    title="Emotion AI — Human Friend System",
    version="4.2.0",
    description="v4.2 — Human Friend Persona + Conversation Analytics + Quest Suggestions",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)


@app.get("/")
async def root():
    return {
        "message": "Emotion AI — Human Friend System", "version": "4.2.0",
        "languages": SUPPORTED_LANGUAGES,
        "endpoints": {
            "languages":         "GET  /api/v1/languages",
            "emotion_detection": "POST /api/v1/detect-emotion",
            "chat_stream":       "POST /api/v1/chat-stream  (SSE)",
            "chat_summary":      "POST /api/v1/chat/summary",
            "emotion_breakdown": "GET  /api/v1/conversation/emotion-breakdown/{session_id}",
            "low_mood_detect":   "GET  /api/v1/conversation/low-mood-detect/{session_id}",
            "quest_suggestions": "GET  /api/quest-suggestions/?zone=<zone>&mode=auto|static|ai",
            "quest_source":      "GET  /api/v1/quest-source",
            "session_new":       "POST /api/v1/session/new",
            "session_get":       "GET  /api/v1/session/{id}",
            "session_delete":    "DELETE /api/v1/session/{id}",
        },
    }


@app.get("/health")
async def health():
    return {
        "status": "ok", "openai": bool(_resolve_openai_key()),
        "hume": bool(_resolve_hume_key()), "sessions": len(_sessions),
        "quest_zones": QUEST_ZONES,
    }


@app.get("/api/v1/languages")
async def list_languages():
    return {
        "supported_languages": [{"code": c, "name": n} for c, n in SUPPORTED_LANGUAGES.items()],
        "default": DEFAULT_LANGUAGE,
    }


@app.get("/api/v1/quest-source")
async def quest_source():
    return {"quest_api_url": _resolve_quest_api_url(), "method": "GET"}


# ── Session management ─────────────────────────────────────────────────────────

@app.post("/api/v1/session/new")
async def new_session(request: NewSessionRequest = NewSessionRequest()):
    sid = str(uuid.uuid4())
    _sessions[sid] = Session(
        session_id=sid, user_name=request.user_name,
        system_name=request.system_name, language=request.language,
    )
    s = _sessions[sid]
    logger.info("New session | id=%s | user=%s | friend=%s | lang=%s", sid, s.user_name, s.system_name, s.language)
    return {
        "session_id": sid, "user_name": s.user_name, "system_name": s.system_name,
        "language": s.language, "language_name": SUPPORTED_LANGUAGES[s.language],
        "created_at": s.created_at,
    }


@app.get("/api/v1/session/{session_id}")
async def get_session(session_id: str):
    if session_id not in _sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    return _sessions[session_id].to_dict()


@app.delete("/api/v1/session/{session_id}")
async def delete_session(session_id: str):
    _sessions.pop(session_id, None)
    return {"deleted": session_id}


# ══════════════════════════════════════════════════════════════════════════════
# API 1 — POST /api/v1/detect-emotion
# ══════════════════════════════════════════════════════════════════════════════

@app.post("/api/v1/detect-emotion", response_model=EmotionDetectionResponse)
async def detect_emotion(
    text:       Optional[str]        = Form(None),
    audio_file: Optional[UploadFile] = File(None),
):
    if not text and audio_file is None:
        raise HTTPException(status_code=422, detail="Provide at least one of: text, audio_file")

    t0 = time.perf_counter()
    transcript = ""
    voice_emotions: list[EmotionScore] = []
    text_emotions:  list[EmotionScore] = []
    warnings:       list[str]          = []

    if audio_file is not None:
        suffix   = os.path.splitext(audio_file.filename or "audio.wav")[1] or ".wav"
        fd, path = tempfile.mkstemp(suffix=suffix)
        try:
            os.close(fd)
            content = await audio_file.read()
            with open(path, "wb") as fh:
                fh.write(content)
            logger.info("Audio saved: %s (%d bytes)", path, len(content))

            has_openai = bool(_resolve_openai_key())
            has_hume   = bool(_resolve_hume_key())

            if not has_openai:
                warnings.append("OPENAI_API_KEY missing — skipped transcription and text emotion.")
            if not has_hume:
                warnings.append("HUME_API_KEY missing — skipped voice emotion.")

            parallel_tasks: list = []
            if has_hume:
                parallel_tasks.append(detect_voice_emotions(path))
            if has_openai:
                parallel_tasks.append(_transcribe_audio(path))

            if parallel_tasks:
                results = await asyncio.gather(*parallel_tasks, return_exceptions=True)
                idx = 0
                if has_hume:
                    r = results[idx]; idx += 1
                    if isinstance(r, Exception):
                        warnings.append(f"Voice emotion failed: {r}")
                    else:
                        voice_emotions = r
                if has_openai:
                    r = results[idx]; idx += 1
                    if isinstance(r, Exception):
                        warnings.append(f"Transcription failed: {r}")
                    else:
                        transcript = r

            combined_text = " ".join(p for p in [transcript, text or ""] if p).strip()
            if combined_text and has_openai:
                try:
                    text_emotions = await detect_text_emotions(combined_text)
                except Exception as exc:
                    warnings.append(f"Text emotion failed: {exc}")
            elif combined_text and not has_openai:
                warnings.append("OPENAI_API_KEY missing — skipped text emotion on transcript.")
        finally:
            if os.path.exists(path):
                os.unlink(path)
    else:
        if not _resolve_openai_key():
            warnings.append("OPENAI_API_KEY missing — skipped text emotion.")
        else:
            try:
                text_emotions = await detect_text_emotions(text or "")
            except Exception as exc:
                warnings.append(f"Text emotion failed: {exc}")

    combined_emotions = merge_emotions(voice_emotions, text_emotions, top_n=5, voice_weight=0.60, text_weight=0.40)
    dominant_emotion  = combined_emotions[0] if combined_emotions else None
    elapsed_ms        = (time.perf_counter() - t0) * 1000

    logger.info("detect-emotion %.0f ms | dominant=%s | voice=%d text=%d",
                elapsed_ms, dominant_emotion.name if dominant_emotion else "none",
                len(voice_emotions), len(text_emotions))

    return EmotionDetectionResponse(
        transcript=transcript, voice_emotions=voice_emotions,
        text_emotions=text_emotions, combined_emotions=combined_emotions,
        dominant_emotion=dominant_emotion, warnings=warnings,
        processing_ms=round(elapsed_ms, 1),
    )


# ══════════════════════════════════════════════════════════════════════════════
# CONTENT MODERATION  (block abusive / inappropriate input — NOT emotional distress)
# ══════════════════════════════════════════════════════════════════════════════
# Two layers: (1) a fast local profanity word list (plain swear words that the OpenAI
# Moderation API does NOT flag on their own), and (2) OpenAI omni-moderation for
# categorical abuse (harassment / hate / sexual — multilingual, obfuscation-aware).
# We DELIBERATELY do NOT block self-harm / violence / distress: this is a wellness app,
# so a struggling user must get a supportive reply, never a "you can't say that".
# Fails OPEN — an API error never blocks a message.

_PROFANITY_WORDS: frozenset = frozenset({
    # English
    "fuck", "fucks", "fucking", "fucked", "fucker", "motherfucker", "shit", "shits",
    "shitty", "bullshit", "bitch", "bitches", "bastard", "asshole", "assholes", "arsehole",
    "dick", "dickhead", "prick", "cunt", "twat", "wanker", "slut", "whore", "cock",
    "pussy", "faggot", "fag", "nigger", "retard", "douche", "douchebag",
    # Serbian / ex-yu (common)
    "jebem", "jebi", "jebo", "jebote", "jebiga", "jebeni", "pizda", "pizdo", "pizdu",
    "kurac", "kurca", "kurcu", "picka", "picku", "picko", "govno", "govna", "seronja",
    "kreten", "peder", "pederu", "kucko", "drolja", "gadura", "shupak", "šupak",
})

# OpenAI Moderation categories we treat as BLOCK-worthy. Excludes self_harm* and
# violence* on purpose (distress / venting → supportive response, not a block).
_BLOCK_MODERATION_CATEGORIES = (
    "harassment", "harassment_threatening",
    "hate", "hate_threatening",
    "sexual", "sexual_minors",
)

_MODERATION_WARNING = {
    "en": "Let's keep our chat kind and respectful. I'm still here for you — what's really on your mind?",
    "de": "Lass uns freundlich und respektvoll bleiben. Ich bin für dich da — was beschäftigt dich wirklich?",
    "es": "Mantengamos la conversación amable y respetuosa. Sigo aquí para ti — ¿qué te preocupa de verdad?",
}

_MOD_WORD_RE = _re.compile(r"[^\W\d_]+", _re.UNICODE)


def _contains_profanity(text: str) -> bool:
    return any(tok.lower() in _PROFANITY_WORDS for tok in _MOD_WORD_RE.findall(text))


async def _is_message_blocked(text: str) -> bool:
    """True if the message is abusive/inappropriate and should be blocked. Fails open."""
    if _contains_profanity(text):
        return True
    try:
        client = _get_openai_client()
        resp = await client.moderations.create(model="omni-moderation-latest", input=text)
        cats = resp.results[0].categories
        return any(getattr(cats, name, False) for name in _BLOCK_MODERATION_CATEGORIES)
    except Exception as exc:  # never block on an API/parse error
        logger.warning("moderation check failed (failing open): %s", exc)
        return False


def _moderation_warning(language: str) -> str:
    return _MODERATION_WARNING.get(language, _MODERATION_WARNING["en"])


# ══════════════════════════════════════════════════════════════════════════════
# API 2 — POST /api/v1/chat-stream  (SSE)
# ══════════════════════════════════════════════════════════════════════════════

@app.post("/api/v1/chat-stream")
async def chat_stream(request: ChatRequest):
    if not request.message.strip():
        raise HTTPException(status_code=422, detail="message cannot be empty")

    session = _get_session(request.session_id)

    # Content moderation: block abusive/inappropriate input BEFORE it reaches the emotion
    # model, the chat model, or the persisted turn history. Emotional distress is NOT
    # blocked (see _is_message_blocked). On a block we emit a single 'warning' SSE frame
    # (the app shows a notice + speaks it) then 'done', and skip the model entirely.
    if await _is_message_blocked(request.message):
        logger.info("chat-stream | session=%s | BLOCKED inappropriate input | msg=%.60s",
                    request.session_id, request.message)
        warning_text = _moderation_warning(session.language)

        async def warn_stream() -> AsyncIterator[str]:
            yield sse_event("warning", warning_text)
            yield sse_event("done", _json.dumps({
                "turn": len(session.turns), "words": 0,
                "language": session.language, "emotion_key": "neutral",
            }))

        return StreamingResponse(warn_stream(), media_type="text/event-stream", headers={
            "Cache-Control": "no-cache", "X-Accel-Buffering": "no", "Connection": "keep-alive",
        })

    # ── ARCH CHANGE 2026-07-10: per-message emotion detection REMOVED from the live path ──
    # It was a full GPT call on EVERY user message and blocked the reply for ~1.4–4s, which
    # made the conversation feel laggy. Emotions are now extracted ONCE at call end over the
    # whole transcript (see _compute_top_emotions_from_transcript, used by call-insights and
    # the summary). During the call we pass a neutral placeholder so the reply starts right
    # after moderation. The old per-message detection is kept below (commented) for reference
    # while we refactor — do NOT delete.
    #   current_emotion, emotion_scores = await _detect_emotion_from_text(request.message)
    #   emotion_key = _resolve_emotion_key(current_emotion)
    current_emotion, emotion_scores = "neutral", []
    emotion_key = "neutral"

    logger.info("chat-stream | session=%s | user=%s | lang=%s | turn=%d | (emotion at end-of-call) | msg=%.60s",
                request.session_id, session.user_name, session.language,
                len(session.turns) + 1, request.message)

    turn = session.add_turn(request.message, current_emotion, emotion_scores)
    system_prompt = _build_system_prompt(current_emotion, session.user_name, session.system_name, session.language)
    messages = session.build_message_history(system_prompt, max_turns=40)
    messages.append({"role": "user", "content": request.message})

    async def generate() -> AsyncIterator[str]:
        client = _get_openai_client()
        async for sse_frame in _stream_sse_words(
            client=client, messages=messages, emotion=current_emotion,
            emotion_key=emotion_key, emotion_scores=emotion_scores,
            session=session, turn=turn,
        ):
            yield sse_frame

    return StreamingResponse(generate(), media_type="text/event-stream", headers={
        "Cache-Control": "no-cache", "X-Accel-Buffering": "no", "Connection": "keep-alive",
    })


# ══════════════════════════════════════════════════════════════════════════════
# API 3 — POST /api/v1/chat/summary
# ══════════════════════════════════════════════════════════════════════════════

@app.post("/api/v1/chat/summary", response_model=MoodSummaryResponse)
async def chat_summary(request: SummaryRequest):
    if request.session_id not in _sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    session = _sessions[request.session_id]
    if not session.turns:
        raise HTTPException(status_code=422, detail="No turns recorded. Have a conversation first.")

    t0      = time.perf_counter()
    client  = _get_openai_client()
    sys_msg = _SUMMARY_SYSTEM.get(session.language, _SUMMARY_SYSTEM["en"]).format(
        user_name=session.user_name, system_name=session.system_name,
    )

    try:
        response = await client.chat.completions.create(
            model="gpt-4o", max_tokens=400, temperature=0.5,
            messages=[
                {"role": "system", "content": sys_msg},
                {"role": "user",   "content": _build_summary_prompt(session)},
            ],
        )
        raw      = response.choices[0].message.content.strip().strip("`").lstrip("json").strip()
        gpt_data = _json.loads(raw)
    except Exception as exc:
        logger.error("Summary GPT call failed: %s", exc)
        gpt_data = _SUMMARY_FALLBACKS.get(session.language, _SUMMARY_FALLBACKS["en"])

    elapsed_ms = (time.perf_counter() - t0) * 1000
    logger.info("Summary complete | session=%s | user=%s | lang=%s | turns=%d | dominant=%s | %.0f ms",
                request.session_id, session.user_name, session.language,
                len(session.turns), session.overall_dominant(), elapsed_ms)

    # Normalise the 5-category emotion split the summary GPT returned (this is now the source
    # of emotions for the summary — per-message detection was removed). Sums to 100; falls back
    # to a neutral happy-100 split if the GPT call failed or omitted it.
    _raw_te = gpt_data.get("top_emotions") or {}
    _te = {c: max(0.0, float(_raw_te.get(c, 0) or 0)) for c in _TOP_EMOTIONS}
    _te_total = sum(_te.values())
    top_emotions = ({c: round(v / _te_total * 100, 1) for c, v in _te.items()}
                    if _te_total > 0 else {**{c: 0.0 for c in _TOP_EMOTIONS}, "happy": 100.0})
    dominant = max(top_emotions, key=top_emotions.get)

    return MoodSummaryResponse(
        session_id=request.session_id, user_name=session.user_name,
        system_name=session.system_name, language=session.language,
        language_name=SUPPORTED_LANGUAGES[session.language], total_turns=len(session.turns),
        mood_detected=gpt_data.get("mood_detected", ""), focus_topic=gpt_data.get("focus_topic", ""),
        energy_shift=gpt_data.get("energy_shift", ""), next_step=gpt_data.get("next_step", ""),
        # dominant_emotion now comes from the transcript-based top_emotions (per-turn was removed):
        #   dominant_emotion=session.overall_dominant(),
        dominant_emotion=dominant, emotion_counts=session.dominant_emotion_counts(),
        emotion_timeline=session.emotion_timeline(), top_emotions=top_emotions,
        processing_ms=round(elapsed_ms, 1),
    )


# ══════════════════════════════════════════════════════════════════════════════
# SHARED HELPERS FOR ANALYTICS
# ══════════════════════════════════════════════════════════════════════════════

_EMOTION_BUCKETS = ["happy", "sad", "angry", "anxious", "confused", "neutral"]

_BUCKET_MAP: Dict[str, str] = {
    "joy": "happy", "happiness": "happy", "excitement": "happy", "amusement": "happy",
    "delight": "happy", "contentment": "happy", "satisfaction": "happy", "pride": "happy",
    "love": "happy", "optimism": "happy", "relief": "happy", "gratitude": "happy",
    "admiration": "happy", "adoration": "happy", "ecstasy": "happy", "enthusiasm": "happy", "euphoria": "happy",
    "sadness": "sad", "grief": "sad", "sorrow": "sad", "disappointment": "sad",
    "despair": "sad", "hurt": "sad", "melancholy": "sad", "loneliness": "sad",
    "regret": "sad", "guilt": "sad", "shame": "sad",
    "anger": "angry", "rage": "angry", "annoyance": "angry", "frustration": "angry",
    "irritation": "angry", "contempt": "angry", "disgust": "angry", "envy": "angry",
    "jealousy": "angry", "hostility": "angry",
    "fear": "anxious", "anxiety": "anxious", "stress": "anxious", "worry": "anxious",
    "panic": "anxious", "distress": "anxious", "nervousness": "anxious", "dread": "anxious",
    "apprehension": "anxious", "insecurity": "anxious", "embarrassment": "anxious",
    "confusion": "confused", "uncertainty": "confused", "doubt": "confused",
    "perplexity": "confused", "surprise": "confused", "disbelief": "confused", "awe": "confused",
    "neutral": "neutral", "calmness": "neutral", "serenity": "neutral",
    "interest": "neutral", "concentration": "neutral", "boredom": "neutral", "tiredness": "neutral",
}


def _map_to_bucket(emotion_name: str) -> str:
    name = emotion_name.strip().lower()
    if name in _BUCKET_MAP:
        return _BUCKET_MAP[name]
    for key, bucket in _BUCKET_MAP.items():
        if key in name or name in key:
            return bucket
    return _resolve_emotion_key(name)


# ── Top-emotion categories (5) for the Insights "Top Emotions" section ────────
# The Insights screen shows exactly five categories. This is a *native* taxonomy
# for that feature — fine-grained Hume/GPT emotions are folded straight into one
# of these five (it is not a temporary remap of the 6 analytics buckets above,
# which stay in use by the low-mood endpoint and the chat prompts). Calm/neutral
# and unknown emotions fall back to "happy" (the positive-calm baseline).
_TOP_EMOTIONS = ["happy", "motivated", "angry", "tired", "sad"]

_TOP_EMOTION_MAP: Dict[str, str] = {
    # happy — joy / calm / positive
    "joy": "happy", "happiness": "happy", "excitement": "happy", "amusement": "happy",
    "delight": "happy", "contentment": "happy", "satisfaction": "happy", "love": "happy",
    "relief": "happy", "gratitude": "happy", "admiration": "happy", "adoration": "happy",
    "ecstasy": "happy", "euphoria": "happy", "calmness": "happy", "serenity": "happy",
    "awe": "happy", "surprise": "happy",
    # motivated — drive / optimism / focus
    "optimism": "motivated", "enthusiasm": "motivated", "determination": "motivated",
    "pride": "motivated", "hope": "motivated", "inspiration": "motivated",
    "confidence": "motivated", "concentration": "motivated", "interest": "motivated",
    "desire": "motivated", "craving": "motivated", "triumph": "motivated",
    # angry
    "anger": "angry", "rage": "angry", "annoyance": "angry", "frustration": "angry",
    "irritation": "angry", "contempt": "angry", "disgust": "angry", "envy": "angry",
    "jealousy": "angry", "hostility": "angry", "disapproval": "angry",
    # tired
    "tiredness": "tired", "exhaustion": "tired", "fatigue": "tired", "boredom": "tired",
    "sleepiness": "tired", "lethargy": "tired",
    # sad — sadness + anxiety/fear + confusion (all negative low-mood)
    "sadness": "sad", "grief": "sad", "sorrow": "sad", "disappointment": "sad",
    "despair": "sad", "hurt": "sad", "melancholy": "sad", "loneliness": "sad",
    "regret": "sad", "guilt": "sad", "shame": "sad", "pain": "sad",
    "fear": "sad", "anxiety": "sad", "stress": "sad", "worry": "sad", "panic": "sad",
    "distress": "sad", "nervousness": "sad", "dread": "sad", "apprehension": "sad",
    "insecurity": "sad", "embarrassment": "sad",
    "confusion": "sad", "uncertainty": "sad", "doubt": "sad", "perplexity": "sad",
    "disbelief": "sad",
}


def _map_to_top_emotion(emotion_name: str) -> str:
    name = (emotion_name or "").strip().lower()
    if name in _TOP_EMOTION_MAP:
        return _TOP_EMOTION_MAP[name]
    for key, category in _TOP_EMOTION_MAP.items():
        if key in name or name in key:
            return category
    # calm / neutral / unknown → positive-calm baseline
    return "happy"


def _compute_top_emotions_from_turns(session: Session) -> Dict[str, float]:
    """Percentage split across the 5 Top-Emotion categories (sums to ~100)."""
    totals: Dict[str, float] = {c: 0.0 for c in _TOP_EMOTIONS}
    if not session.turns:
        return {**totals, "happy": 100.0}
    for turn in session.turns:
        if turn.emotion_scores:
            for es in turn.emotion_scores:
                totals[_map_to_top_emotion(es.name)] += es.score
        else:
            totals[_map_to_top_emotion(turn.dominant_emotion)] += 1.0
    total = sum(totals.values()) or 1.0
    return {c: round((v / total) * 100, 1) for c, v in totals.items()}


# ── ARCH CHANGE 2026-07-10: emotions extracted ONCE at call end over the whole transcript ──
# Per-message emotion detection was removed from chat-stream (it blocked every reply). This
# single GPT pass replaces the per-turn aggregation as the source for Top Emotions + summary.
_EMOTION_MODEL = os.getenv("EMOTION_MODEL", "gpt-4o-mini")  # fast/cheap; classification only

_TOP_EMOTIONS_TRANSCRIPT_PROMPT = (
    "You are analysing a supportive conversation. Based on the USER's messages below, "
    "estimate how their OVERALL emotional state across the whole chat splits between "
    "EXACTLY these five categories: happy, motivated, angry, tired, sad. Return ONLY a JSON "
    "object mapping each of the five categories to a number; the five numbers MUST sum to "
    "100. No prose, no code fences.\n\nConversation:\n{convo}"
)


async def _compute_top_emotions_from_transcript(session: "Session") -> Dict[str, float]:
    """5-category Top-Emotion split via ONE GPT pass over the whole transcript.
    Replaces the per-turn aggregation now that per-message detection is gone. Falls back to
    a neutral 'happy 100' split on empty input or any error."""
    convo = _build_conversation_text(session)
    if not convo.strip():
        return {**{c: 0.0 for c in _TOP_EMOTIONS}, "happy": 100.0}
    try:
        client = _get_openai_client()
        resp = await client.chat.completions.create(
            model=_EMOTION_MODEL,
            messages=[{"role": "user",
                       "content": _TOP_EMOTIONS_TRANSCRIPT_PROMPT.format(convo=convo)}],
            max_tokens=120, temperature=0.0,
        )
        raw = (resp.choices[0].message.content or "{}").strip()
        raw = _re.sub(r"```(?:json)?|```", "", raw).strip()
        data = _json.loads(raw)
        vals = {c: max(0.0, float(data.get(c, 0) or 0)) for c in _TOP_EMOTIONS}
        total = sum(vals.values()) or 1.0
        return {c: round(v / total * 100, 1) for c, v in vals.items()}
    except Exception as exc:
        logger.warning("top-emotions transcript extraction failed (falling back): %s", exc)
        return {**{c: 0.0 for c in _TOP_EMOTIONS}, "happy": 100.0}


def _build_conversation_text(session: Session) -> str:
    return "\n".join(f"Turn {t.turn_number}: {t.user_message}" for t in session.turns)


def _build_full_conversation_for_gpt(session: Session) -> str:
    lines = []
    for t in session.turns:
        lines.append(f"User: {t.user_message}")
        if t.ai_reply:
            lines.append(f"Friend: {t.ai_reply}")
    return "\n".join(lines)


def _compute_breakdown_from_turns(session: Session) -> Dict[str, float]:
    bucket_totals: Dict[str, float] = {b: 0.0 for b in _EMOTION_BUCKETS}
    if not session.turns:
        bucket_totals["neutral"] = 100.0
        return bucket_totals
    for turn in session.turns:
        if turn.emotion_scores:
            for es in turn.emotion_scores:
                bucket_totals[_map_to_bucket(es.name)] += es.score
        else:
            bucket_totals[_map_to_bucket(turn.dominant_emotion)] += 1.0
    total = sum(bucket_totals.values()) or 1.0
    return {b: round((v / total) * 100, 1) for b, v in bucket_totals.items()}


def _compute_negative_ratio(session: Session) -> float:
    if not session.turns:
        return 0.0
    negative_buckets = {"sad", "angry", "anxious"}
    negative_count = sum(1 for t in session.turns if _map_to_bucket(t.dominant_emotion) in negative_buckets)
    return round(negative_count / len(session.turns), 3)


_BREAKDOWN_GPT_SYSTEM = {
    "en": "You are an expert emotion analyst. Return ONLY valid JSON — no markdown, no explanation.",
    "de": "Du bist ein Emotions-Analyst. Nur gültiges JSON — kein Markdown.",
    "es": "Eres un analista de emociones. Solo JSON válido — sin markdown.",
}

_BREAKDOWN_GPT_USER = (
    "Analyse the user's messages and estimate the percentage of the conversation "
    "that reflects each emotion. Percentages must sum to 100.\n\n"
    "Conversation:\n{conversation}\n\n"
    "Return ONLY this JSON:\n"
    '{{"happy": N, "motivated": N, "angry": N, "tired": N, "sad": N}}'
)

_LOW_MOOD_GPT_SYSTEM = {
    "en": "You are a compassionate clinical psychologist. Assess low mood, stress, and overwhelm. Return ONLY valid JSON — no markdown.",
    "de": "Du bist ein einfühlsamer klinischer Psychologe. Nur gültiges JSON — kein Markdown.",
    "es": "Eres un psicólogo clínico compasivo. Solo JSON válido — sin markdown.",
}

_LOW_MOOD_GPT_USER = """Analyse this full conversation transcript:

{conversation}

Return ONLY this JSON object (no extra keys, no markdown):
{{
  "is_low_mood": true or false,
  "stress_level": "none" | "mild" | "moderate" | "high" | "severe",
  "stress_score": 0.0 to 1.0,
  "dominant_negative_emotion": "e.g. anxiety / sadness / overwhelm / none",
  "language_patterns": ["list", "of", "pattern", "labels", "detected"],
  "gpt_summary": "2-3 sentence friend-voice summary of the emotional state",
  "recommendations": ["recommendation 1", "recommendation 2", "recommendation 3"]
}}"""

_LOW_MOOD_PATTERNS: List[tuple] = [
    (r"\bi (can'?t|cannot|couldn'?t)\b",           "helplessness"),
    (r"\bi give up\b",                             "helplessness"),
    (r"\bnothing (works|matters|helps)\b",         "helplessness"),
    (r"\bwhat'?s the point\b",                     "helplessness"),
    (r"\bi don'?t (know|care|see)\b",              "helplessness"),
    (r"\bno (point|use|hope)\b",                   "helplessness"),
    (r"\bit'?s too much\b",                        "overwhelm"),
    (r"\bi'?m overwhelmed\b",                      "overwhelm"),
    (r"\btoo (much|hard|difficult|many)\b",        "overwhelm"),
    (r"\bi can'?t (handle|deal|cope|do this)\b",   "overwhelm"),
    (r"\beverything'?s? (is )?(falling apart|a mess|wrong)\b", "overwhelm"),
    (r"\bi'?m (drowning|buried|swamped)\b",        "overwhelm"),
    (r"\blater\b",                                 "avoidance"),
    (r"\bmaybe (tomorrow|later|someday|another day)\b", "avoidance"),
    (r"\bnot (now|today|yet)\b",                   "avoidance"),
    (r"\bi'?ll (try|think about it|see)\b",        "avoidance"),
    (r"\bi keep (avoiding|putting off|delaying)\b","avoidance"),
    (r"\bi (should|shouldn'?t) have\b",            "self-criticism"),
    (r"\bi'?m (such a|a) (failure|loser|mess|disaster|idiot|burden)\b", "self-criticism"),
    (r"\bi'?m (not good enough|worthless|useless|pathetic)\b", "self-criticism"),
    (r"\bmy fault\b",                              "self-criticism"),
    (r"\bi always (mess|screw|fail|ruin)\b",       "self-criticism"),
    (r"\bi hate (myself|my life|everything)\b",    "self-criticism"),
    (r"\bi'?m (so )?(tired|exhausted|burnt out|burned out|drained|done)\b", "exhaustion"),
    (r"\bi (haven'?t|can'?t) (sleep|slept|rest)\b","exhaustion"),
    (r"\bso (stressed|anxious|worried|scared)\b",  "stress"),
    (r"\bfreaking out\b",                          "stress"),
    (r"\bpanic(king)?\b",                          "stress"),
    (r"\bwill (never|always) be (like this|this way|the same)\b", "hopelessness"),
    (r"\bno (future|way out|escape)\b",            "hopelessness"),
    (r"\bnobody (cares|understands|gets it)\b",    "hopelessness"),
    (r"\bi'?m (always|forever) (alone|stuck|broken)\b", "hopelessness"),
    (r"\bwhat'?s (the point|the use|wrong with me)\b", "hopelessness"),
]


def _rule_based_phrase_scan(session: Session) -> List[DetectedPhrase]:
    results: List[DetectedPhrase] = []
    for turn in session.turns:
        text      = turn.user_message.lower()
        sentences = _re.split(r'[.!?]+', turn.user_message)
        for pattern_str, category in _LOW_MOOD_PATTERNS:
            match = _re.search(pattern_str, text, _re.IGNORECASE)
            if match:
                matched_word     = match.group(0)
                context_sentence = next(
                    (s.strip() for s in sentences if matched_word.lower() in s.lower()),
                    turn.user_message[:100],
                )
                results.append(DetectedPhrase(
                    phrase=matched_word, pattern=category,
                    turn=turn.turn_number, context=context_sentence[:150],
                ))
    seen: set[tuple] = set()
    unique: List[DetectedPhrase] = []
    for dp in results:
        key = (dp.phrase.lower(), dp.pattern)
        if key not in seen:
            seen.add(key)
            unique.append(dp)
    return unique


# ── Canonical low-mood phrases (for the Insights "When feeling low…" section) ──
# That section shows tidy, deduped phrases (e.g. "I can't", "I don't know") — NOT the raw
# regex matches. Each entry maps a pattern to the exact display phrase; several raw
# variations fold into one canonical phrase. English-only (same scope as the low-mood
# patterns above). Kept separate from `_LOW_MOOD_PATTERNS` so the existing low-mood-detect
# endpoint is untouched.
_LOW_MOOD_CANONICAL: List[tuple] = [
    (r"\bi don'?t know\b",                              "helplessness",   "I don't know"),
    (r"\bi (can'?t|cannot|couldn'?t)\b",                "helplessness",   "I can't"),
    (r"\bi give up\b",                                  "helplessness",   "I give up"),
    (r"\bnothing (works|matters|helps)\b",              "helplessness",   "Nothing works"),
    (r"\bwhat'?s the point\b",                          "helplessness",   "What's the point"),
    (r"\bit'?s too much\b",                             "overwhelm",      "It's too much"),
    (r"\btoo (much|hard|difficult|many)\b",             "overwhelm",      "It's too much"),
    (r"\bi'?m overwhelmed\b",                            "overwhelm",      "I'm overwhelmed"),
    (r"\bi can'?t (handle|deal|cope|do this)\b",        "overwhelm",      "I can't cope"),
    (r"\blater\b",                                      "avoidance",      "Later"),
    (r"\bmaybe (tomorrow|later|someday|another day)\b", "avoidance",      "Maybe later"),
    (r"\bnot (now|today|yet)\b",                         "avoidance",      "Not now"),
    (r"\bi'?ll (try|think about it|see)\b",             "avoidance",      "I'll try later"),
    (r"\bi (should|shouldn'?t)\b",                       "self-criticism", "I should"),
    (r"\bi'?m (not good enough|worthless|useless|pathetic)\b", "self-criticism", "I'm not good enough"),
    (r"\bmy fault\b",                                    "self-criticism", "It's my fault"),
    (r"\bi hate (myself|my life|everything)\b",         "self-criticism", "I hate this"),
    (r"\bi'?m (so )?(tired|exhausted|burnt out|burned out|drained|done)\b", "exhaustion", "I'm so tired"),
    (r"\bso (stressed|anxious|worried|scared)\b",       "stress",         "I'm so stressed"),
    (r"\bfreaking out\b",                                "stress",         "I'm freaking out"),
    (r"\bnobody (cares|understands|gets it)\b",         "hopelessness",   "Nobody understands"),
    (r"\bno (future|way out|escape)\b",                 "hopelessness",   "There's no way out"),
]


def _extract_canonical_low_mood_phrases(session: Session) -> List[Dict[str, Any]]:
    """Per-call canonical low-mood phrases with per-turn frequency (rule-based, no GPT).

    Each canonical phrase is counted once per turn it appears in; the raw regex match is
    mapped to its tidy display form. Django aggregates these across the week's calls.
    """
    counts: Dict[str, List[Any]] = {}  # canonical -> [category, count]
    for turn in session.turns:
        seen_this_turn: set = set()
        for pattern_str, category, canonical in _LOW_MOOD_CANONICAL:
            if canonical in seen_this_turn:
                continue
            if _re.search(pattern_str, turn.user_message, _re.IGNORECASE):
                seen_this_turn.add(canonical)
                if canonical not in counts:
                    counts[canonical] = [category, 0]
                counts[canonical][1] += 1
    return [{"phrase": c, "category": v[0], "count": v[1]} for c, v in counts.items()]


# ══════════════════════════════════════════════════════════════════════════════
# API 4 — GET /api/v1/conversation/emotion-breakdown/{session_id}
# ══════════════════════════════════════════════════════════════════════════════

@app.get("/api/v1/conversation/emotion-breakdown/{session_id}",
         response_model=EmotionBreakdownResponse,
         summary="Emotion Percentage Breakdown",
         tags=["Conversation Analytics"])
async def conversation_emotion_breakdown(session_id: str):
    if session_id not in _sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    session = _sessions[session_id]
    if not session.turns:
        raise HTTPException(status_code=422, detail="No turns recorded. Have a conversation first.")

    t0         = time.perf_counter()
    has_scores = any(t.emotion_scores for t in session.turns)

    if has_scores:
        breakdown = _compute_top_emotions_from_turns(session)
        method    = "turn_scores"
    else:
        try:
            client   = _get_openai_client()
            sys_msg  = _BREAKDOWN_GPT_SYSTEM.get(session.language, _BREAKDOWN_GPT_SYSTEM["en"])
            usr_msg  = _BREAKDOWN_GPT_USER.format(conversation=_build_conversation_text(session))
            response = await client.chat.completions.create(
                model="gpt-4o-mini", temperature=0.2, max_tokens=120,
                messages=[{"role": "system", "content": sys_msg}, {"role": "user", "content": usr_msg}],
            )
            raw  = response.choices[0].message.content.strip().strip("`").lstrip("json").strip()
            data = _json.loads(raw)
            total = 0.0
            breakdown = {}
            for bucket in _TOP_EMOTIONS:
                val = float(data.get(bucket, 0))
                breakdown[bucket] = val
                total += val
            breakdown = ({k: round((v / total) * 100, 1) for k, v in breakdown.items()}
                         if total > 0 else {**{b: 0.0 for b in _TOP_EMOTIONS}, "happy": 100.0})
            method = "gpt_full"
        except Exception as exc:
            logger.error("GPT breakdown failed: %s", exc)
            breakdown = _compute_top_emotions_from_turns(session)
            method    = "turn_scores_fallback"

    dominant     = max(breakdown, key=breakdown.get)
    turn_by_turn = [{"turn": t.turn_number, "message": t.user_message[:80],
                     "emotion": _map_to_top_emotion(t.dominant_emotion), "raw": t.dominant_emotion}
                    for t in session.turns]
    elapsed_ms   = round((time.perf_counter() - t0) * 1000, 1)
    logger.info("emotion-breakdown | session=%s | method=%s | dominant=%s | %.0f ms", session_id, method, dominant, elapsed_ms)

    return EmotionBreakdownResponse(
        session_id=session_id, user_name=session.user_name, total_turns=len(session.turns),
        emotion_breakdown=breakdown, dominant_emotion=dominant, turn_by_turn=turn_by_turn,
        method=method, processing_ms=elapsed_ms,
    )


# ══════════════════════════════════════════════════════════════════════════════
# API 5 — GET /api/v1/conversation/low-mood-detect/{session_id}
# ══════════════════════════════════════════════════════════════════════════════

@app.get("/api/v1/conversation/low-mood-detect/{session_id}",
         response_model=LowMoodDetectResponse,
         summary="Low Mood & Stress Detection",
         tags=["Conversation Analytics"])
async def conversation_low_mood_detect(session_id: str):
    if session_id not in _sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    session = _sessions[session_id]
    if not session.turns:
        raise HTTPException(status_code=422, detail="No turns recorded. Have a conversation first.")

    t0               = time.perf_counter()
    detected_phrases = _rule_based_phrase_scan(session)
    negative_ratio   = _compute_negative_ratio(session)
    conversation     = _build_full_conversation_for_gpt(session)
    sys_msg          = _LOW_MOOD_GPT_SYSTEM.get(session.language, _LOW_MOOD_GPT_SYSTEM["en"])
    usr_msg          = _LOW_MOOD_GPT_USER.format(conversation=conversation)

    gpt_result: Dict[str, Any] = {}
    try:
        client   = _get_openai_client()
        response = await client.chat.completions.create(
            model="gpt-4o", temperature=0.3, max_tokens=500,
            messages=[{"role": "system", "content": sys_msg}, {"role": "user", "content": usr_msg}],
        )
        raw        = response.choices[0].message.content.strip().strip("`").lstrip("json").strip()
        gpt_result = _json.loads(raw)
    except Exception as exc:
        logger.error("Low-mood GPT failed: %s", exc)
        phrase_count = len(detected_phrases)
        stress_score = min(1.0, negative_ratio + (phrase_count * 0.05))
        stress_level = ("severe" if stress_score >= 0.8 else "high" if stress_score >= 0.6
                        else "moderate" if stress_score >= 0.35 else "mild" if stress_score >= 0.1 else "none")
        gpt_result = {
            "is_low_mood": stress_score >= 0.35, "stress_level": stress_level,
            "stress_score": round(stress_score, 2),
            "dominant_negative_emotion": session.overall_dominant(),
            "language_patterns": list({dp.pattern for dp in detected_phrases}),
            "gpt_summary": f"You showed signs of {stress_level} stress. {phrase_count} low-mood patterns detected.",
            "recommendations": [
                "Take a short break and do something calming.",
                "Talk to someone you trust about how you're feeling.",
                "Focus on one small, achievable task to regain momentum.",
            ],
        }

    elapsed_ms = round((time.perf_counter() - t0) * 1000, 1)
    logger.info("low-mood-detect | session=%s | is_low_mood=%s | stress=%s(%.2f) | phrases=%d | %.0f ms",
                session_id, gpt_result.get("is_low_mood"), gpt_result.get("stress_level"),
                gpt_result.get("stress_score", 0.0), len(detected_phrases), elapsed_ms)

    return LowMoodDetectResponse(
        session_id=session_id, user_name=session.user_name, total_turns=len(session.turns),
        is_low_mood=bool(gpt_result.get("is_low_mood", False)),
        stress_level=gpt_result.get("stress_level", "none"),
        stress_score=float(gpt_result.get("stress_score", 0.0)),
        detected_phrases=detected_phrases,
        language_patterns=gpt_result.get("language_patterns", []),
        negative_language_ratio=negative_ratio,
        dominant_negative_emotion=gpt_result.get("dominant_negative_emotion", "none"),
        gpt_summary=gpt_result.get("gpt_summary", ""),
        recommendations=gpt_result.get("recommendations", []),
        processing_ms=elapsed_ms,
    )


# ══════════════════════════════════════════════════════════════════════════════
# API 5b — GET /api/v1/conversation/call-insights/{session_id}
#   ONE GPT-free call returning BOTH the 5-category Top-Emotion breakdown AND the
#   canonical low-mood phrases. The app calls this once at call end: emotions come from
#   the per-turn scores captured during the call, phrases from the regex patterns —
#   neither needs the LLM, so this is the cheapest way to feed both Insights sections.
# ══════════════════════════════════════════════════════════════════════════════

@app.get("/api/v1/conversation/call-insights/{session_id}",
         response_model=CallInsightsResponse,
         summary="Call Insights — emotions + low-mood phrases (no GPT)",
         tags=["Conversation Analytics"])
async def conversation_call_insights(session_id: str):
    if session_id not in _sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    session = _sessions[session_id]
    if not session.turns:
        raise HTTPException(status_code=422, detail="No turns recorded. Have a conversation first.")

    t0         = time.perf_counter()
    # ARCH CHANGE 2026-07-10: emotions now come from ONE GPT pass over the transcript
    # (per-message detection was removed). Old per-turn aggregation kept for reference:
    #   breakdown = _compute_top_emotions_from_turns(session)
    breakdown  = await _compute_top_emotions_from_transcript(session)
    dominant   = max(breakdown, key=breakdown.get)
    phrases    = _extract_canonical_low_mood_phrases(session)
    elapsed_ms = round((time.perf_counter() - t0) * 1000, 1)
    logger.info("call-insights | session=%s | dominant=%s | phrases=%d | %.0f ms",
                session_id, dominant, len(phrases), elapsed_ms)

    return CallInsightsResponse(
        session_id=session_id, user_name=session.user_name, total_turns=len(session.turns),
        emotion_breakdown=breakdown, dominant_emotion=dominant,
        low_mood_phrases=[LowMoodPhrase(**p) for p in phrases], processing_ms=elapsed_ms,
    )


# ══════════════════════════════════════════════════════════════════════════════
# API 6 — GET /api/quest-suggestions/
# ══════════════════════════════════════════════════════════════════════════════

@app.get(
    "/api/quest-suggestions/",
    summary="Quest Suggestions by Zone",
    description=(
        "Returns 5 quest suggestions per zone.\n\n"
        "Uses your **existing OPENAI_API_KEY** — no new keys needed.\n\n"
        "**mode param:**\n"
        "- `auto` (default) — GPT-4o-mini if key available, else static\n"
        "- `static` — always instant predefined data, zero AI cost\n"
        "- `ai` — always GPT-4o-mini\n\n"
        "**Available zones:** Soft steps | Elevated | Deep dive | Power mode | Rest & reflect"
    ),
    tags=["Quest Suggestions"],
)
async def quest_suggestions(
    zone: Optional[str] = Query(default=None, description="Filter by zone name (optional)"),
    mode: Optional[str] = Query(default="auto", description="'static' | 'ai' | 'auto'"),
):
    if zone and zone not in STATIC_QUEST_SUGGESTIONS:
        raise HTTPException(
            status_code=404,
            detail=f"Zone '{zone}' not found. Available: {QUEST_ZONES}",
        )

    use_ai       = (mode == "ai" or (mode != "static" and bool(_resolve_openai_key())))
    target_zones = [zone] if zone else QUEST_ZONES
    result: Dict[str, List[dict]] = {}

    for z in target_zones:
        if use_ai:
            try:
                client    = _get_openai_client()
                result[z] = await _generate_ai_quest_suggestions(z, client)
                logger.info("quest-suggestions | zone=%s | source=gpt-4o-mini | count=%d", z, len(result[z]))
            except Exception as exc:
                logger.warning("quest-suggestions | zone=%s | GPT failed (%s) — using static", z, exc)
                result[z] = STATIC_QUEST_SUGGESTIONS.get(z, [])
        else:
            result[z] = STATIC_QUEST_SUGGESTIONS.get(z, [])
            logger.info("quest-suggestions | zone=%s | source=static | count=%d", z, len(result[z]))

    return result


# ── Entry ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        # HOST/PORT are env-driven. Defaults target the Flutter app's expectation
        # (AI service on :8001; the Django backend owns :8000).
        host = os.getenv("HOST", "0.0.0.0"),
        port = int(os.getenv("PORT", "8001")),
    ) 