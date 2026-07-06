"""
services/emotion_merger.py
==========================
Merges voice (Hume) and text (OpenAI) emotion scores into a single
ranked list using a weighted average.

Voice prosody captures *how* something is said; text captures *what*.
Default weights give slightly more weight to voice because prosody is
harder to fake, but both sources matter.
"""
from __future__ import annotations

from collections import defaultdict
from typing import List

from models import EmotionScore, EmotionSource

# Weight given to each source (must sum to 1.0)
VOICE_WEIGHT: float = 0.55
TEXT_WEIGHT:  float = 0.45


def merge_emotions(
    voice: List[EmotionScore],
    text: List[EmotionScore],
    top_n: int = 5,
    voice_weight: float = VOICE_WEIGHT,
    text_weight: float = TEXT_WEIGHT,
) -> List[EmotionScore]:
    """
    Weighted merge of voice and text emotion scores.

    - Emotions present in both sources are averaged with the given weights.
    - Emotions present in only one source are scaled by that source's weight
      (so they don't unfairly dominate when the other source is absent).
    - Returns the top_n results sorted by merged score descending.
    """
    scores: dict[str, float] = defaultdict(float)
    counts: dict[str, int]   = defaultdict(int)

    # Normalise weights in case neither source contributed
    total_voice = sum(e.score for e in voice)
    total_text  = sum(e.score for e in text)

    for e in voice:
        scores[e.name.lower()] += e.score * voice_weight
        counts[e.name.lower()] += 1

    for e in text:
        scores[e.name.lower()] += e.score * text_weight
        counts[e.name.lower()] += 1

    # If one source is completely missing, normalise the other to fill the gap
    if not voice and text:
        scores = {k: v / text_weight for k, v in scores.items()}
    elif not text and voice:
        scores = {k: v / voice_weight for k, v in scores.items()}

    # Clamp to [0, 1]
    merged = [
        EmotionScore(
            name=name.capitalize(),
            score=min(score, 1.0),
            source=EmotionSource.COMBINED,
        )
        for name, score in sorted(scores.items(), key=lambda kv: kv[1], reverse=True)
    ]

    return merged[:top_n]
