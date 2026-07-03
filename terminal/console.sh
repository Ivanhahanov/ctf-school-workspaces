#!/bin/bash
# Browser console = ttyd serving an interactive bash over a PTY.
# Runs as the unprivileged CTF user (invoked via `su` from the entrypoint), so the
# root-owned /flag stays unreadable — same trust model as the desktop image.
#
# Dark theme keyed to the noVNC client (same near-black background) but tuned for
# READABILITY over long sessions: neutral light-gray body text, muted (non-neon)
# ANSI palette, block cursor. The green stays only where a terminal expects it —
# the prompt and `ls` dirs — not smeared across all output.
exec ttyd \
  --port "${TTYD_PORT:-7681}" \
  --interface 0.0.0.0 \
  --writable \
  --terminal-type xterm-256color \
  --client-option 'fontFamily=Hack, JetBrains Mono, monospace' \
  --client-option fontSize=14 \
  --client-option cursorStyle=block \
  --client-option cursorBlink=true \
  --client-option 'titleFixed=CTF School — Console' \
  --client-option 'theme={"background":"#0b0f14","foreground":"#cdd3de","cursor":"#7bd88f","cursorAccent":"#0b0f14","selectionBackground":"#24404f","black":"#1b2028","red":"#ff6b81","green":"#7bd88f","yellow":"#e3cf65","blue":"#6ab0f3","magenta":"#c792ea","cyan":"#5fd7d7","white":"#c5ccd6","brightBlack":"#5c7387","brightRed":"#ff8b9a","brightGreen":"#95e6a5","brightYellow":"#f0dd8a","brightBlue":"#8cc4ff","brightMagenta":"#dab4f2","brightCyan":"#8ce8e8","brightWhite":"#eef2f6"}' \
  bash
