#!/usr/bin/bash
set -euo pipefail
BUILD_ARGS="${BUILD_ARGS:-}"
SIGSTORE_PUB=keys/sealedblue.pub
SIGSTORE_PREFIX=${SIGSTORE_PUB%.*}
[ -z ${GITHUB_REPOSITORY-} ] || IMAGE_PREFIX=ghcr.io/${GITHUB_REPOSITORY%/*}
