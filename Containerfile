ARG BASE_IMAGE
FROM $BASE_IMAGE as base

FROM base as sealed-uki
ARG KARGS=
RUN \
    --mount=type=tmpfs,target=/run \
    --mount=type=tmpfs,target=/tmp \
    --mount=type=bind,from=base,target=/target \
    --mount=type=bind,source=scripts,target=/scripts \
    --mount=type=secret,id=secureboot.key \
    --mount=type=secret,id=secureboot.pem \
KARGS="$KARGS" /scripts/ukify

FROM base
COPY --from=sealed-uki /out/*.efi /boot/EFI/Linux/
