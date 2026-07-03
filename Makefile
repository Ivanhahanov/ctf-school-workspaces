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

VARIANTS := coding datasci pentest

.PHONY: help images all base $(VARIANTS) load push buildx-ensure deploy-local deploy-prod

help: ## Show this help
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}'
	@echo; $(MAKE) --no-print-directory images

images: ## Print the fully-qualified image refs (pinned versions)
	@echo "base    -> $(call img,base,$(BASE_VERSION))"
	@echo "coding  -> $(call img,coding,$(CODING_VERSION))"
	@echo "datasci -> $(call img,datasci,$(DATASCI_VERSION))"
	@echo "pentest -> $(call img,pentest,$(PENTEST_VERSION))"

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

all: base $(VARIANTS) ## Build base + every variant

load: ## kind-load the pinned base + all variants into the cluster
	@kind load docker-image "$(call img,base,$(BASE_VERSION))"       --name "$(KIND_CLUSTER)"
	@kind load docker-image "$(call img,coding,$(CODING_VERSION))"   --name "$(KIND_CLUSTER)"
	@kind load docker-image "$(call img,datasci,$(DATASCI_VERSION))" --name "$(KIND_CLUSTER)"
	@kind load docker-image "$(call img,pentest,$(PENTEST_VERSION))" --name "$(KIND_CLUSTER)"

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
	  -t $(call img,base,$(BASE_VERSION)) -t $(call latest,base) --push base/
	docker buildx build --platform $(PLATFORMS) --build-arg BASE=$(call img,base,$(BASE_VERSION)) \
	  --build-arg OVSCODE_VERSION="$(OVSCODE_VERSION)" \
	  -t $(call img,coding,$(CODING_VERSION)) -t $(call latest,coding) --push coding/
	docker buildx build --platform $(PLATFORMS) --build-arg BASE=$(call img,base,$(BASE_VERSION)) \
	  -t $(call img,datasci,$(DATASCI_VERSION)) -t $(call latest,datasci) --push datasci/
	docker buildx build --platform $(PLATFORMS) --build-arg BASE=$(call img,base,$(BASE_VERSION)) \
	  -t $(call img,pentest,$(PENTEST_VERSION)) -t $(call latest,pentest) --push pentest/

deploy-local: all load   ## Dev: build all + kind load
deploy-prod: push        ## Prod: multi-arch build + push to registry
