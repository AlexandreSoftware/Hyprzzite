# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image — Bazzite DX (developer experience) variant
# For NVIDIA systems use: ghcr.io/ublue-os/bazzite-dx-nvidia:stable
FROM ghcr.io/ublue-os/bazzite-dx:stable

### [IM]MUTABLE /opt
## Uncomment if packages need to write to /opt and survive bootc deploys.
# RUN rm /opt && mkdir /opt

### MODIFICATIONS
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
RUN bootc container lint
