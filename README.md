# CTF School — workspace images

Browser-based Linux desktops (XFCE + noVNC) handed to each player as an isolated,
**internet-free** container. One `base`, several variants built on top.

```
vpc/
  base/      XFCE + Firefox (default browser) + noVNC + competition start page
  coding/    base + OpenVSCode Server (VS Code, offline) + Python  — coding challenges
  datasci/   base + Python data/ML + Jupyter + stego/pickle      — avatarius/members/trojanml
  pentest/   base + nmap / radare2 / pwntools                    — pwn/recon
  terminal/  STANDALONE console-only (ttyd, no desktop)          — text-only challenges
  Makefile
```

Each variant is its **own repository**, versioned **independently** (semver in
`versions.mk`): `ctf-school/desktop/<base|coding|datasci|pentest>:<version>` (prefix
with `REGISTRY/` for prod). They're different images — not tags of one — so they
version on their own; each build also moves a `latest` tag. A challenge pins an exact
version via `LabSpace.spec.workspace.image`. Run `make images` to see the current refs.

## Build

```bash
make base                      # just the base
make all                       # base + every variant
make deploy-local              # build all + `kind load` into the cluster (dev)
make deploy-prod REGISTRY=ghcr.io/ivanhahanov
make images                    # print the fully-qualified pinned image refs
```

## What's in `base`

- **Hostname** `workspace` (overridable per-session via `CTF_HOSTNAME`); shell prompt `ctf@workspace:~$`. You work in your home `~`.
- **Firefox is the default browser** — `update-alternatives` + `mimeapps.list`/`helpers.rc`, so links never prompt for an app.
- **Competition start page** — a local, offline page (`startpage/index.html`) pinned as the Firefox homepage via an enterprise `policies.json` (Mozilla new-tab/telemetry/first-run disabled).
- **Desktop launchers** — `Firefox`, `Terminal`, `Files` appear on the desktop. Each variant drops its own launcher into `Desktop/` (Theia, Jupyter, …) so added apps show up automatically.
- Dark Arc theme, Hack font, generated wallpaper.
- **Custom noVNC client** (`base/novnc/index.html`) — a from-scratch hacking-themed UI
  built on noVNC's `core/rfb.js` (v1.3.0) instead of the stock control bar. Auto-connects,
  scales to the window, and exposes a slim left rail with just **two** controls:
  **Clipboard** (a flyout that mirrors the workspace clipboard both ways) and
  **Fullscreen**. No settings/power/keyboard panels.

## The `terminal` variant (console-only)

A **standalone** image (`FROM debian:bookworm-slim`, *not* `base`) for text-only
challenges where a full desktop is overkill. It serves an interactive `bash` in the
browser via **ttyd** (xterm.js front-end, PTY back-end) on port **7681**, themed to
match the noVNC client (neon-green on near-black, Hack font). ttyd isn't packaged in
bookworm, so the official static binary is fetched at build time (per-arch) — offline at
runtime like the rest. The shell runs as the unprivileged `ctf` user, so the root-owned
`/flag` stays unreadable — same trust model as the desktop. Point a challenge at it with
`spec.workspace.image: …-terminal:<version>` and `spec.workspace.port: 7681`.

## Adding a variant

Create `vpc/<name>/Dockerfile`:

```dockerfile
ARG BASE
FROM ${BASE}
RUN apt-get update && apt-get install -y --no-install-recommends <tools> && rm -rf /var/lib/apt/lists/*
COPY <name>.desktop /etc/ctf-skel/Desktop/<name>.desktop   # appears on the desktop
```

The `Makefile` passes `--build-arg BASE=ctf-school/desktop/base:$(BASE_VERSION)`, so a
variant is pinned to the exact base it was built on. Add the variant to `VARIANTS` in
the `Makefile`, add a `<NAME>_VERSION` to `versions.mk`, and give it build/load/push
lines mirroring the others. Everything offline: install at build time (internet
available), runtime needs no network.

## Offline note (Theia / Jupyter)

`coding` ships **OpenVSCode Server** — official VS Code in the browser (Gitpod), a
prebuilt tarball (no npm build), launched locally (backend on `127.0.0.1:3000`, opened
in Firefox). It runs the backend as the player, so the editor has a **real file tree,
integrated terminal and full access to `~`** — same as a native IDE, just rendered in a
browser tab. Arch-portable (arm64 & amd64); VS Code bundles built-in language extensions,
so highlighting works offline. `datasci` ships Jupyter + the numeric stack from apt.
Neither contacts a marketplace/CDN at competition time.
