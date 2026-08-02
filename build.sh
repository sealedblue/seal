#!/usr/bin/bash
set -euxo pipefail
. ./env.sh

IMAGE="${BASE_IMAGE%-unsealed}"

podman pull  "$BASE_IMAGE"
mkdir -p build
podman inspect "$BASE_IMAGE" > build/config.json
PREPARED_IMAGE="${IMAGE}-prepared"
podman build \
    $BUILD_ARGS \
    --security-opt label=disable \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    --build-arg CONFIG_FILE="build/config.json" \
    --secret=id=secureboot.key,src=${SIGSTORE_PREFIX}-db.key \
    --secret=id=secureboot.pem,src=${SIGSTORE_PREFIX}-db.pem \
    -f Containerfile.prepare \
    -t "${PREPARED_IMAGE}" .
podman run --rm \
    --security-opt label=disable \
    -v ./build:/build \
    "${PREPARED_IMAGE}" \
    cp -a /out /build/.
SEALED_IMAGE="${IMAGE}-sealed"
podman build \
    --security-opt label=disable \
    --build-arg BASE_IMAGE="oci:build/out" \
    --secret=id=secureboot.key,src=${SIGSTORE_PREFIX}-db.key \
    --secret=id=secureboot.pem,src=${SIGSTORE_PREFIX}-db.pem \
    -t "${SEALED_IMAGE}" .

for i in {9..0..-1}; do
    NEXT="-$(($i+1))"
    THIS="-$i"
    [ $i -gt 0 ] || THIS=""
    skopeo copy --sign-by-sigstore-private-key ${SIGSTORE_PREFIX}-staged.private \
        --sign-passphrase-file ${SIGSTORE_PREFIX}-staged.passphrase \
        "docker://${SEALED_IMAGE}${THIS}" "docker://${SEALED_IMAGE}${NEXT}" || true
    skopeo copy --sign-by-sigstore-private-key ${SIGSTORE_PREFIX}.private \
        --sign-passphrase-file ${SIGSTORE_PREFIX}.passphrase \
        "docker://${SEALED_IMAGE}${NEXT}" "docker://${IMAGE}${NEXT}" || true
done

DIGEST_NAME=$(systemd-escape "$IMAGE")
podman push --sign-by-sigstore-private-key ${SIGSTORE_PREFIX}-staged.private \
    --sign-passphrase-file ${SIGSTORE_PREFIX}-staged.passphrase \
    --digestfile "${DIGEST_NAME}.digest" \
    "${SEALED_IMAGE}"
skopeo copy --sign-by-sigstore-private-key ${SIGSTORE_PREFIX}.private \
    --sign-passphrase-file ${SIGSTORE_PREFIX}.passphrase \
    "docker://${SEALED_IMAGE}" "docker://$IMAGE"

BASE_DIGEST_NAME=$(systemd-escape "$BASE_IMAGE")
mkdir -p input
podman image inspect --format {{.Digest}} "$BASE_IMAGE" > "input/${BASE_DIGEST_NAME}.digest"

git add "${DIGEST_NAME}.digest"
git add "input/${BASE_DIGEST_NAME}.digest"
git commit -m "${IMAGE} pushed" || true
git push
