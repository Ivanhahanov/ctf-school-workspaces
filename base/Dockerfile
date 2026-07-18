FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="ctf-school/desktop/base" \
      org.opencontainers.image.description="CTF School base workspace — XFCE4 + Firefox (default) via noVNC. Variant images (coding/datasci/pentest) build FROM this." \
      org.opencontainers.image.source="https://github.com/Ivanhahanov/ctf-school"

ENV DEBIAN_FRONTEND=noninteractive \
    CTF_USER=ctf \
    CTF_HOSTNAME=workspace \
    GEOMETRY=1280x800

# NOTE: python3 stays as a system dep for websockify; no pip/dev/stdlib extras
RUN apt-get update && apt-get install -y --no-install-recommends \
    # X11
    xauth x11-xserver-utils dbus-x11 \
    # Desktop
    xfce4 xfce4-terminal thunar \
    # VNC + web client (websockify requires python3-minimal)
    tigervnc-standalone-server novnc websockify \
    # Browser
    firefox-esr \
    # Theme
    arc-theme papirus-icon-theme fonts-hack \
    # Cyrillic fonts (fonts-hack covers Latin only; DejaVu has full Cyrillic)
    fonts-dejavu-core \
    # Locale support (needed for ru_RU.UTF-8 generation below)
    locales \
    # Basic terminal utils (no dev tools — add via child images)
    curl wget netcat-openbsd file xxd vim tmux less procps \
    && rm -rf /var/lib/apt/lists/*

# Generate Russian + English locales. LANG stays en_US.UTF-8 (tool output remains
# English), but ru_RU.UTF-8 is available for apps and the desktop can display
# Cyrillic correctly. The keyboard layout (us + ru, Alt+Shift toggle) is wired in
# skel/.config/xfce4/xfconf/xfce-perchannel-xml/keyboard-layout.xml.
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
    sed -i 's/^# *\(ru_RU.UTF-8\)/\1/' /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Firefox is THE browser: make it the system default so links never prompt.
RUN update-alternatives --set x-www-browser /usr/bin/firefox-esr && \
    (update-alternatives --set gnome-www-browser /usr/bin/firefox-esr 2>/dev/null || true)

# Competition start page (offline, file://) + Firefox enterprise policy that pins
# it as the homepage and disables the Mozilla new-tab / telemetry / first-run.
COPY startpage/ /usr/share/ctf/startpage/
COPY firefox/policies.json /usr/lib/firefox-esr/distribution/policies.json

# Pre-generated wallpaper (see tools/gen-wallpaper.py to regenerate)
COPY wallpaper.png /etc/ctf-wallpaper.png

# noVNC landing page: auto-connect + scale to browser window
COPY novnc/index.html /usr/share/novnc/index.html

# Theme script (fixed path, called by XFCE4 autostart)
COPY ctf-theme.sh /usr/local/bin/ctf-theme.sh
RUN chmod +x /usr/local/bin/ctf-theme.sh

# Skeleton home directory (copied to /home/$CTF_USER at runtime). Includes the
# Desktop launchers, default-app wiring (mimeapps.list / helpers.rc) and configs.
COPY skel/ /etc/ctf-skel/
RUN chmod +x /etc/ctf-skel/.vnc/xstartup

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6080
ENTRYPOINT ["/entrypoint.sh"]
