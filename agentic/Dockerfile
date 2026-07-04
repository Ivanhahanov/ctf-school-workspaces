ARG BASE=explabs/ctf-school-desktop-base:0.1.0
FROM ${BASE}

LABEL org.opencontainers.image.title="ctf-school/desktop/agentic" \
      org.opencontainers.image.description="Workspace for the Agentic task."

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    && rm -rf /var/lib/apt/lists/*
