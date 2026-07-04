ARG BASE=explabs/ctf-school-desktop-base:0.1.0
FROM ${BASE}

LABEL org.opencontainers.image.title="ctf-school/desktop/members" \
      org.opencontainers.image.description="Workspace for the Members task."

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    && rm -rf /var/lib/apt/lists/*
