# CTF Desktop — Base Image

> Browser-based Linux desktop for CTF competitions. Each participant gets their
> own isolated container accessible via a browser (noVNC). No root access for
> the CTF user. Flags are injected at runtime via environment variables.

## Architecture

```
ctf-desktop:latest          ← this image (base)
├── Dockerfile.pentest      ← + nmap, gdb, pwntools, radare2
└── Dockerfile.programming  ← + python3, gcc, node, java
```

Child images inherit the full desktop environment and add category-specific tools.
The **flag is never baked into the image** — it is passed at container start:

```bash
docker run -d -p 6080:6080 \
  -e CTF_USER=alice \
  -e CTF_HOSTNAME=web-01 \
  -e FLAG='CTF{your_flag_here}' \
  ctf-desktop-pentest:latest
```

The flag is written to `/flag` (mode 400, owned by root) by the entrypoint.
The CTF user has **no sudo and no root** — escalating to read the flag is
part of the challenge.

## Quick start

```bash
# Build base image
docker build -t ctf-desktop:latest .

# Build pentest image
docker build -t ctf-desktop-pentest:latest -f Dockerfile.pentest .

# Run a session
docker run -d --name ctf-alice -p 6080:6080 --shm-size=512m \
  -e CTF_USER=alice -e CTF_HOSTNAME=pentest-01 -e FLAG='CTF{test}' \
  ctf-desktop-pentest:latest

# Open in browser
open http://localhost:6080/
```

## Access

| URL | Description |
|-----|-------------|
| `http://HOST:PORT/` | Auto-connects, scales to browser window |
| `http://HOST:PORT/vnc.html` | Manual connect page |

The VNC canvas scales with the browser window (`resize=scale`).
For true fullscreen press **F11** in the browser.

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CTF_USER` | `ctf` | Linux username inside the container |
| `CTF_HOSTNAME` | `ctf-box` | Hostname shown in shell prompt |
| `FLAG` | _(empty)_ | Written to `/flag` at startup (root-only) |
| `GEOMETRY` | `1280x800` | VNC resolution |

## Base image contents

> **Image:** `ctf-desktop:latest`
> **Size:** 366 MB
> **Built:** 1980-01-01

### Desktop

- **WM:** XFCE4 (xfwm4) with Arc-Dark theme
- **Terminal:** xfce4-terminal (green-on-black)
- **File manager:** Thunar
- **Browser:** Firefox ESR
- **Remote access:** TigerVNC + noVNC (WebSocket, no client needed)

### Pre-installed CLI tools

| Tool | Purpose |
|------|---------|
| `curl`, `wget` | HTTP client |
| `netcat` (openbsd) | TCP/UDP Swiss Army knife |
| `file`, `xxd` | File inspection / hex dump |
| `vim` | Text editor |
| `tmux` | Terminal multiplexer |

### Not in base — add via child images

```
python3 / pip    →  Dockerfile.programming
nmap / gdb       →  Dockerfile.pentest
pwntools         →  Dockerfile.pentest
gcc / node       →  Dockerfile.programming
```

### Full package list (auto-generated)

<details>
<summary>Click to expand</summary>

| Package | Version | Size |
|---------|---------|------|
| /usr/bin/startxfce4: X server already running on display :1 |                                |  KB |
| [*] ctf@ctf-box desktop ready            |                                |  KB |
| [*] noVNC → http://0.0.0.0:6080/         |                                |  KB |

</details>

## Regenerate this file

```bash
./tools/gen-readme.sh ctf-desktop:latest
```

## Regenerate wallpaper

```bash
python3 tools/gen-wallpaper.py   # outputs wallpaper.png
docker build -t ctf-desktop:latest .
```
