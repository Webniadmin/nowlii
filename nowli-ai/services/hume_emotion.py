"""
services/hume_emotion.py
========================
Detects emotions from a WAV audio file using Hume Expression Measurement
batch API (prosody model).  Returns the top-N emotion scores.
"""
from __future__ import annotations

import asyncio
import logging
import time
from typing import List

from hume import HumeClient

from config import HUME_API_KEY, TOP_N_EMOTIONS
from models import EmotionScore, EmotionSource

logger = logging.getLogger("hume_emotion")


def _extract_top_emotions(
    predictions: list,
    top_n: int = TOP_N_EMOTIONS,
) -> List[EmotionScore]:
    """
    Walk the Hume batch-prediction tree:
      predictions → results.predictions → models.prosody →
      grouped_predictions → predictions → emotions
    Returns the top-N emotions sorted by score descending.
    """
    try:
        result = predictions[0]
        pred_list = result.results.predictions
        prosody = pred_list[0].models.prosody
        grouped = prosody.grouped_predictions[0]
        emotions = grouped.predictions[0].emotions

        scored = sorted(
            [{"name": e.name, "score": float(e.score)} for e in emotions],
            key=lambda x: x["score"],
            reverse=True,
        )[:top_n]

        return [
            EmotionScore(name=e["name"], score=e["score"], source=EmotionSource.VOICE)
            for e in scored
        ]
    except Exception as exc:
        logger.warning("Could not parse Hume predictions: %s", exc)
        return []


async def detect_voice_emotions(audio_path: str) -> List[EmotionScore]:
    """
    Submit an audio file to Hume batch API and poll until complete.
    Runs the blocking Hume SDK calls in a thread pool to stay async-friendly.
    """
    if not HUME_API_KEY:
        logger.warning("HUME_API_KEY not set — skipping voice emotion detection")
        return []

    def _run_hume() -> List[EmotionScore]:
        client = HumeClient(api_key=HUME_API_KEY)

        with open(audio_path, "rb") as f:
            file_content = f.read()

        job_id = client.expression_measurement.batch.start_inference_job_from_local_file(
            file=[("audio.wav", file_content, "audio/wav")],
            json={"models": {"prosody": {}}},
        )
        logger.info("Hume job started: %s", job_id)

        # Poll with exponential back-off
        delay = 0.5
        for _ in range(20):
            details = client.expression_measurement.batch.get_job_details(id=job_id)
            status = details.state.status
            logger.debug("Hume job %s status: %s", job_id, status)
            if status == "COMPLETED":
                break
            if status == "FAILED":
                logger.error("Hume job failed: %s", details)
                return []
            time.sleep(delay)
            delay = min(delay * 1.5, 5.0)

        predictions = list(
            client.expression_measurement.batch.get_job_predictions(id=job_id)
        )
        return _extract_top_emotions(predictions)

    return await asyncio.get_event_loop().run_in_executor(None, _run_hume)
