FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="ctf-school/desktop/terminal" \
      org.opencontainers.image.description="Console-only workspace — browser terminal via ttyd. A lightweight alternative to the XFCE/noVNC desktop for text-only challenges." \
      org.opencontainers.image.source="https://github.com/Ivanhahanov/ctf-school"

ENV DEBIAN_FRONTEND=noninteractive \
    CTF_USER=ctf \
    CTF_HOSTNAME=workspace \
    TTYD_PORT=7681

# Terminal utilities — mirror the base image's set so the console is equally useful,
# minus all X11 / desktop / browser weight. Everything from apt = offline at runtime.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl wget netcat-openbsd file xxd vim tmux less procps \
    && rm -rf /var/lib/apt/lists/*

# ttyd = the browser terminal (xterm.js in the page, PTY on the backend). It is NOT
# packaged in bookworm, so we fetch the official self-contained static binary (per
# arch) at build time — like `coding` does for OpenVSCode Server. No runtime network.
ARG TTYD_VERSION=1.7.7
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      amd64) arch=x86_64 ;; \
      arm64) arch=aarch64 ;; \
      *) echo "unsupported arch"; exit 1 ;; \
    esac; \
    wget -qO /usr/local/bin/ttyd \
      "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${arch}"; \
    chmod +x /usr/local/bin/ttyd; \
    ttyd --version

# Shell skeleton (same prompt as the desktop image, minus the X bits)
COPY skel/ /etc/ctf-skel/

# Launcher: ttyd serving an unprivileged bash, themed to match the noVNC client
COPY console.sh /usr/local/bin/console.sh
RUN chmod +x /usr/local/bin/console.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7681
ENTRYPOINT ["/entrypoint.sh"]
