#!/usr/bin/bash
set -euxo pipefail
. ./env.sh

INPUT_PREFIX=$(systemd-escape "$IMAGE_PREFIX")
for INPUT in $(basename -s .digest input/${INPUT_PREFIX}*); do
    DIGEST1=$(cat "input/${INPUT}.digest")
    export BASE_IMAGE=$(systemd-escape -u "$INPUT")
    DIGEST2=$(skopeo inspect --format='{{.Digest}}' "docker://${BASE_IMAGE}")
    [ "$DIGEST1" == "$DIGEST2" ] || ./build.sh
done
