#!/usr/bin/bash
set -euo pipefail
SIGSTORE_PUB=keys/sealedblue.pub
SIGSTORE_PREFIX=${SIGSTORE_PUB%.*}
[ ${GITHUB_REPOSITORY-} ] && IMAGE_PREFIX=ghcr.io/${GITHUB_REPOSITORY%/*}