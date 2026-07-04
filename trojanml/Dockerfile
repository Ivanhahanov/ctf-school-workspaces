ARG BASE=explabs/ctf-school-desktop-base:0.1.0
FROM ${BASE}

LABEL org.opencontainers.image.title="ctf-school/desktop/trojanml" \
      org.opencontainers.image.description="Workspace for the TrojanML task."

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-joblib python3-numpy \
    && rm -rf /var/lib/apt/lists/*
