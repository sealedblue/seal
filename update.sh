#!/usr/bin/bash
set -euxo pipefail
. ./env.sh

for INPUT in $(basename -s .digest input/*); do
    DIGEST1=$(cat "input/${INPUT}.digest")
    export BASE_IMAGE=$(systemd-escape -u "$INPUT")
    podman pull $BASE_IMAGE
    DIGEST2=$(podman inspect --format {{.Digest}} $BASE_IMAGE)
    [ "$DIGEST1" == "$DIGEST2" ] || ./build.sh
done
