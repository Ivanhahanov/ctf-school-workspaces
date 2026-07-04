ARG BASE=explabs/ctf-school-desktop-base:0.1.0
FROM ${BASE}

LABEL org.opencontainers.image.title="ctf-school/desktop/avatarius" \
      org.opencontainers.image.description="Workspace for the Avatarius task."

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pil python3-numpy \
    && rm -rf /var/lib/apt/lists/*
