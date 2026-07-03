#!/bin/bash
set -e

CTF_USER="${CTF_USER:-ctf}"
CTF_HOSTNAME="${CTF_HOSTNAME:-workspace}"
HOME_DIR="/home/${CTF_USER}"

# Register hostname in /etc/hosts so tools like curl/ping resolve it too
sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t${CTF_HOSTNAME}/" /etc/hosts 2>/dev/null || \
    echo -e "127.0.1.1\t${CTF_HOSTNAME}" >> /etc/hosts

# Unprivileged user (no auto-skeleton — we fully control the home dir)
if ! id "$CTF_USER" &>/dev/null; then
    useradd -M -s /bin/bash "$CTF_USER"
fi
mkdir -p "$HOME_DIR"

# Deploy our skeleton (overwrite — our config always wins)
cp -r /etc/ctf-skel/. "$HOME_DIR/"
chown -R "${CTF_USER}:${CTF_USER}" "$HOME_DIR"

# Write flag (root-only, unreadable to the CTF user without privilege escalation)
if [ -n "${FLAG}" ]; then
    printf '%s' "${FLAG}" > /flag
    chmod 400 /flag
    chown root:root /flag
fi

echo "[*] ${CTF_USER}@${CTF_HOSTNAME} console ready"
echo "[*] ttyd → http://0.0.0.0:${TTYD_PORT:-7681}/"

# Drop to the CTF user and serve the console. CTF_HOSTNAME/TTYD_PORT are inherited
# from the environment (Dockerfile ENV) so the PTY shell's prompt renders correctly.
exec su "$CTF_USER" -s /bin/bash -c /usr/local/bin/console.sh
