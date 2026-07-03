#!/bin/bash
# OpenVSCode Server presented as an app window that's easy to hide/close with the
# MOUSE (no keyboard shortcuts — the workspace is used from a noVNC browser tab,
# often on macOS where Alt/Alt+Tab don't apply):
#   * Firefox chrome (tabs/address bar) is hidden via userChrome.css → looks like an app
#   * the XFCE window title bar stays → always-visible Minimize (hide) and Close buttons
#   * the window is maximised to fill the desktop
# Backend runs as the ctf user: real file tree, integrated terminal, full ~ access.
set -e
URL="http://127.0.0.1:3000/?folder=${HOME}"
PROFILE="${HOME}/.mozilla/code-ide"

if ! curl -fsS http://127.0.0.1:3000/ >/dev/null 2>&1; then
  ( /opt/openvscode-server/bin/openvscode-server \
      --host 127.0.0.1 --port 3000 \
      --without-connection-token \
      --disable-telemetry \
      >/tmp/openvscode.log 2>&1 & )
  for _ in $(seq 1 40); do
    curl -fsS http://127.0.0.1:3000/ >/dev/null 2>&1 && break
    sleep 0.5
  done
fi

mkdir -p "$PROFILE"
firefox-esr --no-remote --profile "$PROFILE" --new-window "$URL" &

# Maximise the IDE window once it appears (fills the desktop, keeps the title bar).
for _ in $(seq 1 20); do
  wid="$(wmctrl -l 2>/dev/null | awk 'tolower($0) ~ /firefox/ {print $1; exit}')"
  if [ -n "$wid" ]; then
    wmctrl -i -r "$wid" -b add,maximized_vert,maximized_horz 2>/dev/null || true
    break
  fi
  sleep 0.5
done

wait
