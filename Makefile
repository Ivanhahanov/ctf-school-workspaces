# CTF School workspace images. One base, several variants built FROM it.
#
# Each variant is its OWN image repository, versioned independently (see versions.mk):
#
#   [REGISTRY/]ctf-school/desktop/base     : $(BASE_VERSION)
#   [REGISTRY/]ctf-school/desktop/coding   : $(CODING_VERSION)   (FROM base)
#   [REGISTRY/]ctf-school/desktop/datasci  : $(DATASCI_VERSION)  (FROM base)
#   [REGISTRY/]ctf-school/desktop/pentest  : $(PENTEST_VERSION)  (FROM base)
#
# Variants are DIFFERENT images (different purpose/content), not tags of one image —
# so they get different repositories and version on their own. Each build also moves
# a `latest` tag; manifests always pin the exact semver.
#
#   make base                 # build the base desktop (XFCE + Firefox + noVNC)
#   make coding               # base + OpenVSCode Server + Python
#   make datasci              # base + Python data/ML + Jupyter + stego/pickle tools
#   make pentest              # base + nmap/radare2/pwntools
#   make all                  # base + every variant
#   make deploy-local         # build all + `kind load` into the cluster (dev)
#   make deploy-prod REGISTRY=ghcr.io/ivanhahanov   # build all + push to a registry
#   make images               # print the fully-qualified image refs

include versions.mk

# Docker Hub org / namespace for the desktop image repos (Docker Hub is flat, so
# variants are `ctf-school-desktop-<variant>` repos under it). Override for another ns.
REGISTRY     ?= explabs
KIND_CLUSTER ?= ctfd
# Build platform. Empty = native host arch (OpenVSCode Server has prebuilt arm64 &
# amd64 tarballs). Set e.g. PLATFORM=linux/amd64 to cross-build.
PLATFORM ?=
# OpenVSCode Server (prebuilt VS Code for the browser) version used by `coding`.
OVSCODE_VERSION ?= 1.109.5

REPO  := $(REGISTRY)/ctf-school-desktop
BUILD := docker build $(if $(PLATFORM),--platform $(PLATFORM),)

# img(variant,version) -> pinned ref;  latest(variant) -> moving ref
img    = $(REPO)-$(1):$(2)
latest = $(REPO)-$(1):latest

# Registry-backed BUILD LAYER CACHE (buildx `push` only). Each image gets a
# `:buildcache` tag in its own repo; we read it on every build and rewrite it with
# mode=max (all intermediate layers). Unchanged layers — above all the slow
# QEMU-emulated arm64 apt installs — are then reused across CI runs instead of
# rebuilt, cutting a cold ~14 min "rebuild all" to a few minutes on typical commits.
cachefrom = --cache-from type=registry,ref=$(REPO)-$(1):buildcache
cacheto   = --cache-to   type=registry,ref=$(REPO)-$(1):buildcache,mode=max

# base-derived variants (built --build-arg BASE=…)
VARIANTS := coding datasci pentest
# standalone images (their own FROM, NOT built on base)
STANDALONE := terminal

.PHONY: help images all base $(VARIANTS) $(STANDALONE) load push buildx-ensure deploy-local deploy-prod

help: ## Show this help
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}'
	@echo; $(MAKE) --no-print-directory images

images: ## Print the fully-qualified image refs (pinned versions)
	@echo "base    -> $(call img,base,$(BASE_VERSION))"
	@echo "coding  -> $(call img,coding,$(CODING_VERSION))"
	@echo "datasci -> $(call img,datasci,$(DATASCI_VERSION))"
	@echo "pentest -> $(call img,pentest,$(PENTEST_VERSION))"
	@echo "terminal-> $(call img,terminal,$(TERMINAL_VERSION))"

base: ## Build the base workspace image
	$(BUILD) -t $(call img,base,$(BASE_VERSION)) -t $(call latest,base) base/

coding: base ## Build the coding image (OpenVSCode Server + Python)
	$(BUILD) --build-arg BASE=$(call img,base,$(BASE_VERSION)) \
	  --build-arg OVSCODE_VERSION="$(OVSCODE_VERSION)" \
	  -t $(call img,coding,$(CODING_VERSION)) -t $(call latest,coding) coding/

datasci: base ## Build the data-science image
	$(BUILD) --build-arg BASE=$(call img,base,$(BASE_VERSION)) \
	  -t $(call img,datasci,$(DATASCI_VERSION)) -t $(call latest,datasci) datasci/

pentest: base ## Build the pentest image
	$(BUILD) --build-arg BASE=$(call img,base,$(BASE_VERSION)) \
	  -t $(call img,pentest,$(PENTEST_VERSION)) -t $(call latest,pentest) pentest/

terminal: ## Build the console-only image (standalone ttyd, no desktop)
	$(BUILD) -t $(call img,terminal,$(TERMINAL_VERSION)) -t $(call latest,terminal) terminal/

all: base $(VARIANTS) $(STANDALONE) ## Build base + every variant

load: ## kind-load the pinned base + all variants into the cluster
	@kind load docker-image "$(call img,base,$(BASE_VERSION))"       --name "$(KIND_CLUSTER)"
	@kind load docker-image "$(call img,coding,$(CODING_VERSION))"   --name "$(KIND_CLUSTER)"
	@kind load docker-image "$(call img,datasci,$(DATASCI_VERSION))" --name "$(KIND_CLUSTER)"
	@kind load docker-image "$(call img,pentest,$(PENTEST_VERSION))" --name "$(KIND_CLUSTER)"
	@kind load docker-image "$(call img,terminal,$(TERMINAL_VERSION))" --name "$(KIND_CLUSTER)"

# CI builds MULTI-ARCH so prod (amd64) and the local demo/Mac (arm64) both run natively.
PLATFORMS ?= linux/amd64,linux/arm64

buildx-ensure:
	@docker buildx inspect ctf-builder >/dev/null 2>&1 || docker buildx create --name ctf-builder --driver docker-container >/dev/null
	@docker buildx use ctf-builder

## Multi-arch build + PUSH of base + all variants (needs REGISTRY + docker login).
## base is pushed FIRST so the variants can pull it per-platform for their FROM.
push: buildx-ensure ## Push multi-arch base + variants to the registry
	@test -n "$(REGISTRY)" || { echo "REGISTRY is required for push"; exit 1; }
	docker buildx build --platform $(PLATFORMS) \
	  $(call cachefrom,base) $(call cacheto,base) \
	  -t $(call img,base,$(BASE_VERSION)) -t $(call latest,base) --push base/
	docker buildx build --platform $(PLATFORMS) --build-arg BASE=$(call img,base,$(BASE_VERSION)) \
	  --build-arg OVSCODE_VERSION="$(OVSCODE_VERSION)" \
	  $(call cachefrom,coding) $(call cacheto,coding) \
	  -t $(call img,coding,$(CODING_VERSION)) -t $(call latest,coding) --push coding/
	docker buildx build --platform $(PLATFORMS) --build-arg BASE=$(call img,base,$(BASE_VERSION)) \
	  $(call cachefrom,datasci) $(call cacheto,datasci) \
	  -t $(call img,datasci,$(DATASCI_VERSION)) -t $(call latest,datasci) --push datasci/
	docker buildx build --platform $(PLATFORMS) --build-arg BASE=$(call img,base,$(BASE_VERSION)) \
	  $(call cachefrom,pentest) $(call cacheto,pentest) \
	  -t $(call img,pentest,$(PENTEST_VERSION)) -t $(call latest,pentest) --push pentest/
	docker buildx build --platform $(PLATFORMS) \
	  $(call cachefrom,terminal) $(call cacheto,terminal) \
	  -t $(call img,terminal,$(TERMINAL_VERSION)) -t $(call latest,terminal) --push terminal/

# ─────────────────────────────────────────────────────────────────────────────
# CI fast path: NATIVE per-arch builds (no QEMU) + selective rebuilds.
#
# The `push` target above is a correct-but-slow one-shot multi-arch build (arm64 is
# EMULATED under QEMU — the ~14 min cost). In CI we instead build each arch on its
# OWN native runner via `ci-arch` (pushing an arch-suffixed tag), then `ci-manifest`
# stitches the arch tags into the real multi-arch tag. The workflow only invokes these
# for images whose files actually changed (path filter), so a typical commit rebuilds
# one image on two fast native runners instead of five under emulation.
#
# Per-image version + build-args, looked up by $(IMAGE). `=` (lazy) so ordering vs
# OVSCODE_VERSION below doesn't matter.
VERSION_base     = $(BASE_VERSION)
VERSION_coding   = $(CODING_VERSION)
VERSION_datasci  = $(DATASCI_VERSION)
VERSION_pentest  = $(PENTEST_VERSION)
VERSION_terminal = $(TERMINAL_VERSION)

BUILD_ARGS_base     =
BUILD_ARGS_terminal =
BUILD_ARGS_coding   = --build-arg BASE=$(call img,base,$(BASE_VERSION)) --build-arg OVSCODE_VERSION="$(OVSCODE_VERSION)"
BUILD_ARGS_datasci  = --build-arg BASE=$(call img,base,$(BASE_VERSION))
BUILD_ARGS_pentest  = --build-arg BASE=$(call img,base,$(BASE_VERSION))

# Arches merged into each multi-arch tag (must match the matrix in release.yml).
CI_ARCHES ?= amd64 arm64

.PHONY: ci-arch ci-manifest ci-sign

ci-arch: buildx-ensure ## CI: build one IMAGE for one ARCH natively, push an arch-suffixed tag
	@test -n "$(REGISTRY)" || { echo "REGISTRY is required"; exit 1; }
	@test -n "$(IMAGE)$(ARCH)" || { echo "IMAGE and ARCH are required"; exit 1; }
	docker buildx build --platform linux/$(ARCH) $(BUILD_ARGS_$(IMAGE)) \
	  --cache-from type=registry,ref=$(REPO)-$(IMAGE):buildcache-$(ARCH) \
	  --cache-to   type=registry,ref=$(REPO)-$(IMAGE):buildcache-$(ARCH),mode=max \
	  -t $(REPO)-$(IMAGE):$(VERSION_$(IMAGE))-$(ARCH) --push $(IMAGE)/

ci-manifest: ## CI: merge the per-arch tags of IMAGE into its multi-arch version + latest tags
	@test -n "$(IMAGE)" || { echo "IMAGE is required"; exit 1; }
	docker buildx imagetools create \
	  -t $(call img,$(IMAGE),$(VERSION_$(IMAGE))) -t $(call latest,$(IMAGE)) \
	  $(foreach a,$(CI_ARCHES),$(REPO)-$(IMAGE):$(VERSION_$(IMAGE))-$(a))

ci-sign: ## CI: cosign-sign IMAGE's multi-arch version + latest tags (keyless)
	@test -n "$(IMAGE)" || { echo "IMAGE is required"; exit 1; }
	cosign sign --yes $(call img,$(IMAGE),$(VERSION_$(IMAGE)))
	cosign sign --yes $(call latest,$(IMAGE))

deploy-local: all load   ## Dev: build all + kind load
deploy-prod: push        ## Prod: multi-arch build + push to registry
