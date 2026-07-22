ARG BASE=explabs/ctf-school-desktop-base:latest
FROM ${BASE}

LABEL org.opencontainers.image.title="ctf-school/desktop/datasci" \
      org.opencontainers.image.description="Base workspace + Python data/ML stack + stego/pickle tooling + Jupyter (offline). Covers avatarius / members / trojanml."

# Heavy numeric/ML stack from apt (reliable, offline at runtime); niche analysis
# tools from pip (build-time internet only). joblib/numpy cover trojanml's pickle,
# pandas/numpy cover members' CSV scoring, Pillow covers avatarius' LSB stego.
# beautifulsoup4 covers challenges whose API/portal renders results as HTML
# (members' docs page) rather than pure JSON.
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    python3-numpy python3-pandas python3-scipy python3-sklearn \
    python3-pil python3-matplotlib python3-joblib python3-requests python3-bs4 \
    jupyter-notebook \
    imagemagick libimage-exiftool-perl steghide binwalk \
    && pip3 install --no-cache-dir --break-system-packages picklescan fickling \
    && rm -rf /var/lib/apt/lists/*

# Go toolchain (offline at runtime) + pre-vendored HTTP/scraping/numeric libraries,
# for Go-fluent players who don't know Python — same rationale as vpc/coding.
# `go get` runs at BUILD time (real internet); GOPROXY=off at runtime forces
# resolution from this pre-populated module cache only.
ARG GO_VERSION=1.23.4
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      amd64) arch=amd64 ;; \
      arm64) arch=arm64 ;; \
      *) echo "unsupported arch"; exit 1 ;; \
    esac; \
    wget -qO /tmp/go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-${arch}.tar.gz"; \
    tar -C /usr/local -xzf /tmp/go.tgz; \
    rm /tmp/go.tgz
ENV PATH="/usr/local/go/bin:${PATH}" GOPATH=/opt/go
RUN mkdir -p /opt/go-toolbox && cd /opt/go-toolbox && go mod init ctf-toolbox && \
    go get github.com/PuerkitoBio/goquery@v1.9.2 \
           github.com/gocolly/colly/v2@v2.1.0 \
           gonum.org/v1/gonum@v0.15.1 && \
    go mod download
ENV GOFLAGS=-mod=mod GOPROXY=off GOSUMDB=off

# Jupyter launcher (starts the server locally and opens it in Firefox).
COPY jupyter.sh /usr/local/bin/jupyter-ctf.sh
RUN chmod +x /usr/local/bin/jupyter-ctf.sh
COPY jupyter.desktop /etc/ctf-skel/Desktop/jupyter.desktop

# Place this variant's icon right AFTER the base icons. Base occupies rows 0-2
# (Home / Firefox / Terminal), so the Jupyter launcher takes row 3 — consecutive, no gap.
RUN printf '\n[/home/ctf/Desktop/jupyter.desktop]\nrow=3\ncol=0\n' \
    >> /etc/ctf-skel/.config/xfce4/desktop/icons.screen0-1264x757.rc

# FLAG injected at runtime via -e FLAG=CTF{...} (base entrypoint writes /flag root-only).
