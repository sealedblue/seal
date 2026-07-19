#!/usr/bin/bash
set -euo pipefail
. ./env.sh

CONFIG="${HOME}/.config"
mkdir -p "${CONFIG}/containers/registries.d"
cat >"${CONFIG}/containers/registries.d/sigstore.yaml" <<EOC
docker:
    ${IMAGE_PREFIX}:
        use-sigstore-attachments: true
EOC
cat "${CONFIG}/containers/registries.d/sigstore.yaml"
jq >"${CONFIG}/containers/policy.json" <<EOC
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports": {
        "docker": {
            "${IMAGE_PREFIX}": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "$(realpath keys/sealedblue-staged.pub)",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ]
        }
    }
}
EOC
cat "${CONFIG}/containers/policy.json"

git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"

umask 0077
<<<"${SIGSTORE_PRIVATE}" cat >"${SIGSTORE_PREFIX}.private"
<<<"" cat >"${SIGSTORE_PREFIX}.passphrase"
<<<"${SECURE_BOOT_KEY}" cat >"${SIGSTORE_PREFIX}-db.key"
