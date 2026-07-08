ARG BASE=explabs/ctf-school-desktop-base:latest
FROM ${BASE}

LABEL org.opencontainers.image.title="ctf-school/desktop/datasci" \
      org.opencontainers.image.description="Base workspace + Python data/ML stack + stego/pickle tooling + Jupyter (offline). Covers avatarius / members / trojanml."

# Heavy numeric/ML stack from apt (reliable, offline at runtime); niche analysis
# tools from pip (build-time internet only). joblib/numpy cover trojanml's pickle,
# pandas/numpy cover members' CSV scoring, Pillow covers avatarius' LSB stego.
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    python3-numpy python3-pandas python3-scipy python3-sklearn \
    python3-pil python3-matplotlib python3-joblib python3-requests \
    jupyter-notebook \
    imagemagick libimage-exiftool-perl steghide binwalk \
    && pip3 install --no-cache-dir --break-system-packages picklescan fickling \
    && rm -rf /var/lib/apt/lists/*

# Jupyter launcher (starts the server locally and opens it in Firefox).
COPY jupyter.sh /usr/local/bin/jupyter-ctf.sh
RUN chmod +x /usr/local/bin/jupyter-ctf.sh
COPY jupyter.desktop /etc/ctf-skel/Desktop/jupyter.desktop

# Place this variant's icon right AFTER the base icons. Base occupies rows 0-2
# (Home / Firefox / Terminal), so the Jupyter launcher takes row 3 — consecutive, no gap.
RUN printf '\n[/home/ctf/Desktop/jupyter.desktop]\nrow=3\ncol=0\n' \
    >> /etc/ctf-skel/.config/xfce4/desktop/icons.screen0-1264x757.rc

# FLAG injected at runtime via -e FLAG=CTF{...} (base entrypoint writes /flag root-only).
