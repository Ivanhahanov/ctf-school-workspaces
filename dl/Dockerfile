ARG BASE=explabs/ctf-school-desktop-base:latest
FROM ${BASE}

LABEL org.opencontainers.image.title="ctf-school/desktop/dl" \
      org.opencontainers.image.description="Base workspace + deep-learning stack (PyTorch + TensorFlow, CPU) + classic ML/vision libs + Jupyter (offline). For train-your-own-model challenges (e.g. puzzle)."

# Interpreter + Jupyter + OpenMP runtime (torch/tf) from apt. The whole NUMERIC stack
# is installed via pip below (NOT apt) so numpy is a single coherent version —
# TensorFlow needs numpy>=1.26, newer than Debian's python3-numpy, and mixing an
# apt numpy with a pip one is an ABI hazard.
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv python3-dev \
        jupyter-notebook libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# ML/vision stack. CPU-only torch: the extra-index serves CPU wheels on amd64 (avoids
# the ~2.5 GB CUDA build); on arm64 torch is CPU-only regardless. `tensorflow` (not
# `tensorflow-cpu`, which has no arm64 wheel) — it runs on CPU with no GPU present.
# opencv-python-headless = cv2 without the GUI/X libs (training uses the array API).
RUN pip3 install --no-cache-dir --break-system-packages \
        --extra-index-url https://download.pytorch.org/whl/cpu \
        numpy pillow matplotlib scikit-learn tqdm opencv-python-headless \
        torch torchvision tensorflow

# Jupyter launcher (starts the server locally and opens it in Firefox).
COPY jupyter.sh /usr/local/bin/jupyter-ctf.sh
RUN chmod +x /usr/local/bin/jupyter-ctf.sh
COPY jupyter.desktop /etc/ctf-skel/Desktop/jupyter.desktop

# Place this variant's icon right AFTER the base icons. Base occupies rows 0-2
# (Home / Firefox / Terminal), so the Jupyter launcher takes row 3 — consecutive, no gap.
RUN printf '\n[/home/ctf/Desktop/jupyter.desktop]\nrow=3\ncol=0\n' \
    >> /etc/ctf-skel/.config/xfce4/desktop/icons.screen0-1264x757.rc

# FLAG injected at runtime via -e FLAG=CTF{...} (base entrypoint writes /flag root-only).
# Training data is added by a thin per-challenge layer (FROM this image) at /opt/dataset.
