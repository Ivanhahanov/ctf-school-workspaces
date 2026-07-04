# Per-variant image versions. Each workspace image is its OWN repository
# (ctf-school/desktop/<variant>) and is versioned INDEPENDENTLY — bump only the
# one you changed. Manifests (llm-ctf-2026/*/infra.yaml → spec.workspace.image)
# pin these exact versions; `make` also moves a `latest` tag for convenience.
#
# Bump rules (semver): patch = same tools, rebuilt/fixed; minor = added tooling or
# meaningful change; major = incompatible reshuffle. `coding` FROM `base`, so a
# base bump usually means rebuilding + bumping the variants that sit on it.
BASE_VERSION     = 0.1.0
CODING_VERSION   = 0.1.0
DATASCI_VERSION  = 0.1.0
PENTEST_VERSION  = 0.1.0
# terminal is STANDALONE (FROM debian-slim, not base): console-only ttyd workspace.
TERMINAL_VERSION = 0.1.0
# llm-ctf task workspaces (FROM base)
AVATARIUS_VERSION = 0.1.0
TROJANML_VERSION  = 0.1.0
MEMBERS_VERSION   = 0.1.0
AGENTIC_VERSION   = 0.1.0
