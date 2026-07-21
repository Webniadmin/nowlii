# nowli-ai — FastAPI "Emotion AI — Human Friend System" (:8001)
# Multi-stage; final stage is named `runtime` to match docker-compose.prod.yml (target: runtime).
FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1
WORKDIR /app

# ---- builder: install deps into an isolated venv ----
FROM base AS builder
COPY requirements.txt .
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install -r requirements.txt

# ---- runtime: slim final image ----
FROM base AS runtime
ENV PATH="/opt/venv/bin:$PATH" \
    HOST=0.0.0.0 \
    PORT=8001
COPY --from=builder /opt/venv /opt/venv
# App source (test17.py is the live entrypoint; config.py, models.py, services/ are imported by it)
COPY . .
EXPOSE 8001
# Entry point per CLAUDE.md: `python test17.py` binds HOST/PORT from env (defaults 0.0.0.0:8001)
CMD ["python", "test17.py"]
