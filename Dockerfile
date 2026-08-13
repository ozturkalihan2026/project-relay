FROM python:3.12-slim

ARG APP_VERSION=0.8.22

LABEL org.opencontainers.image.title="Project Relay API"
LABEL org.opencontainers.image.version="${APP_VERSION}"

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY pyproject.toml README.md ./
COPY alembic.ini ./
COPY alembic ./alembic
COPY relay_engine ./relay_engine
COPY relay_api ./relay_api
COPY relay_content ./relay_content

RUN python -m pip install --no-cache-dir .

EXPOSE 8000

CMD ["sh", "-c", "alembic upgrade head && exec uvicorn relay_api.app:app --host 0.0.0.0 --port 8000"]
