#!/bin/bash
set -e

CTF_USER="${CTF_USER:-ctf}"
CTF_HOSTNAME="${CTF_HOSTNAME:-workspace}"
HOME_DIR="/home/${CTF_USER}"

# Register hostname in /etc/hosts (Docker allows writes there)
# PS1 reads $CTF_HOSTNAME directly; this makes tools like curl/ping resolve it too
sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t${CTF_HOSTNAME}/" /etc/hosts 2>/dev/null || \
    echo -e "127.0.1.1\t${CTF_HOSTNAME}" >> /etc/hosts

# Create unprivileged user without auto-skeleton so we fully control the home dir
if ! id "$CTF_USER" &>/dev/null; then
    useradd -M -s /bin/bash "$CTF_USER"
fi
mkdir -p "$HOME_DIR"

# Deploy our skeleton (overwrite — ensures our configs always win)
cp -r /etc/ctf-skel/. "$HOME_DIR/"
# Desktop launchers must be executable so XFCE treats them as trusted launchers
# (otherwise it shows them as plain files / prompts on first click).
chmod +x "$HOME_DIR"/Desktop/*.desktop 2>/dev/null || true
chown -R "${CTF_USER}:${CTF_USER}" "$HOME_DIR"

# Write flag (root-only, inaccessible to CTF user without privilege escalation)
if [ -n "${FLAG}" ]; then
    printf '%s' "${FLAG}" > /flag
    chmod 400 /flag
    chown root:root /flag
fi

# X11 socket dirs must exist before switching to unprivileged user
mkdir -p /tmp/.X11-unix /tmp/.ICE-unix
chmod 1777 /tmp/.X11-unix /tmp/.ICE-unix
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

# System dbus
mkdir -p /run/dbus
dbus-daemon --system --fork 2>/dev/null || true

# VNC server (no auth — each user has their own container/port)
su -c "Xtigervnc :1 \
    -geometry ${GEOMETRY:-1280x800} \
    -depth 24 \
    -rfbport 5901 \
    -SecurityTypes None \
    -localhost no \
    -AlwaysShared &" "$CTF_USER"

sleep 2

# XFCE4 desktop session
su -c "DISPLAY=:1 HOME=${HOME_DIR} dbus-launch --exit-with-session startxfce4 &" "$CTF_USER"

sleep 3

echo "[*] ${CTF_USER}@${CTF_HOSTNAME} desktop ready"
echo "[*] noVNC → http://0.0.0.0:6080/"

# Proxy WebSocket → VNC; serve noVNC from /usr/share/novnc/
websockify --web /usr/share/novnc/ 0.0.0.0:6080 localhost:5901 &

exec tail -f /dev/null
