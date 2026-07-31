FROM python:3.12-slim

LABEL org.opencontainers.image.title="Project Relay API"
LABEL org.opencontainers.image.version="0.5.0"

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY pyproject.toml README.md ./
COPY alembic.ini ./
COPY alembic ./alembic
COPY relay_engine ./relay_engine
COPY relay_api ./relay_api

RUN python -m pip install --no-cache-dir .

EXPOSE 8000

CMD ["sh", "-c", "alembic upgrade head && uvicorn relay_api.app:app --host 0.0.0.0 --port 8000"]
