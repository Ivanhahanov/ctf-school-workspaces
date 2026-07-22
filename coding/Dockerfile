ARG BASE=explabs/ctf-school-desktop-base:latest
FROM ${BASE}

LABEL org.opencontainers.image.title="ctf-school/desktop/coding" \
      org.opencontainers.image.description="Base workspace + OpenVSCode Server (prebuilt VS Code, offline) + Python. Arch-portable (arm64/amd64). For coding challenges."

# Python = the challenge language (kept lean — no gcc/java for challenges).
# requests + beautifulsoup4 cover the common "script the web challenge" case
# (find_chat, ats, credit-scoring style tasks) without a per-challenge extra layer.
# inkscape = general-purpose image editor for challenges that hand the player a
# screenshot/GIF/watermarked image to inspect or doctor.
# wmctrl = maximise the IDE window from the launcher.
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv python3-requests python3-bs4 \
        inkscape wmctrl \
    && rm -rf /var/lib/apt/lists/*

# OpenVSCode Server = official VS Code in the browser (Gitpod), a PREBUILT tarball:
# no npm build, multi-arch, and it bundles VS Code's built-in language extensions,
# so syntax/highlighting work with NO internet at runtime.
ARG OVSCODE_VERSION=1.109.5
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      amd64) arch=x64 ;; \
      arm64) arch=arm64 ;; \
      *) echo "unsupported arch"; exit 1 ;; \
    esac; \
    url="https://github.com/gitpod-io/openvscode-server/releases/download/openvscode-server-v${OVSCODE_VERSION}/openvscode-server-v${OVSCODE_VERSION}-linux-${arch}.tar.gz"; \
    wget -qO /tmp/ovs.tgz "$url"; \
    mkdir -p /opt/openvscode-server; \
    tar -xzf /tmp/ovs.tgz -C /opt/openvscode-server --strip-components=1; \
    rm /tmp/ovs.tgz

# The VS Code logo SVG doesn't render on xfdesktop's first cold pass (librsvg
# warm-up) and shows a blank file icon until a restart. Rasterize it to PNG once at
# build so it loads instantly, and publish it into hicolor (inherited by every theme)
# so Icon=visual-studio-code renders reliably at boot.
RUN apt-get update && apt-get install -y --no-install-recommends librsvg2-bin \
    && rm -rf /var/lib/apt/lists/* \
    && for s in 48 64 128; do \
         mkdir -p /usr/share/icons/hicolor/$s\x$s/apps; \
         rsvg-convert -w $s -h $s /usr/share/icons/Papirus/64x64/apps/visual-studio-code.svg \
           -o /usr/share/icons/hicolor/$s\x$s/apps/visual-studio-code.png; \
       done \
    && gtk-update-icon-cache -f /usr/share/icons/hicolor

# Python language support (IntelliSense/Pylance, debugging, linting) for the IDE —
# the prebuilt tarball ships with no extensions. OpenVSCode Server uses open-vsx.org
# (not the MS Marketplace); ms-python.python is mirrored there. Installed straight
# into the skeleton home (not root's) so it's present for the runtime `ctf` user via
# the base entrypoint's `cp -r /etc/ctf-skel/. $HOME/`.
ARG PYTHON_EXT_VERSION=2026.4.0
RUN wget -qO /tmp/ms-python.vsix \
      "https://open-vsx.org/api/ms-python/python/${PYTHON_EXT_VERSION}/file/ms-python.python-${PYTHON_EXT_VERSION}.vsix" && \
    /opt/openvscode-server/bin/openvscode-server \
      --extensions-dir /etc/ctf-skel/.openvscode-server/extensions \
      --install-extension /tmp/ms-python.vsix && \
    rm /tmp/ms-python.vsix

# Go toolchain (offline at runtime) + pre-vendored HTTP/scraping/numeric libraries,
# for Go-fluent players who don't know Python. `go get` runs at BUILD time (real
# internet); GOPROXY=off at runtime forces resolution from this pre-populated module
# cache only — matches these LabSpaces having no egress. goquery = BeautifulSoup
# equivalent, colly = scraping framework, gonum = numpy/scikit-learn equivalent.
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

# Dedicated Firefox profile (userChrome hides tabs/urlbar; the XFCE title bar keeps
# clickable Minimize/Close buttons). Seeded into the skeleton home.
COPY code-profile/ /etc/ctf-skel/.mozilla/code-ide/

# Launcher: starts the server on localhost:3000 (offline) and opens the IDE window.
COPY code.sh /usr/local/bin/code-ctf.sh
RUN chmod +x /usr/local/bin/code-ctf.sh
COPY code.desktop /etc/ctf-skel/Desktop/code.desktop

# Place this variant's icon right AFTER the base icons. Base occupies rows 0-2
# (Home / Firefox / Terminal), so the IDE launcher takes row 3 — consecutive, no gap.
RUN printf '\n[/home/ctf/Desktop/code.desktop]\nrow=3\ncol=0\n' \
    >> /etc/ctf-skel/.config/xfce4/desktop/icons.screen0-1264x757.rc

# FLAG injected at runtime via -e FLAG=CTF{...} (base entrypoint writes /flag root-only).
