ARG SOURCE_IMAGE="bluefin"
# ARG SOURCE_SUFFIX="-hwe"
ARG SOURCE_SUFFIX="-surface"
# ARG SOURCE_TAG="41-20241202.2"
ARG SOURCE_TAG="40-20240414"

FROM ubuntu:24.04 AS builder

## Build Howdy

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-setuptools python3-wheel \
    cmake make build-essential \
    libpam0g-dev libinih-dev libevdev-dev \
    python3-dev libopencv-dev \
    meson ninja-build \
    git

# Clone and build howdy
RUN git clone https://github.com/boltgolt/howdy.git && \
    cd howdy && \
    meson setup build && \
    meson compile -C build && \
    DESTDIR=/tmp/howdy-install meson install -C build

FROM ghcr.io/ublue-os/${SOURCE_IMAGE}${SOURCE_SUFFIX}:${SOURCE_TAG}

# Copy built files from builder
COPY --from=builder /tmp/howdy-install/ /

# Undo Bluefin changes
COPY ./undo_bluefin_changes.sh /tmp/undo_bluefin_changes.sh
RUN mkdir -p /var/lib/alternatives && \
    /tmp/undo_bluefin_changes.sh && \
    ostree container commit

# Install Linux Surface
COPY ./install_linux_surface.sh /tmp/install_linux_surface.sh
RUN mkdir -p /var/lib/alternatives && \
    /tmp/install_linux_surface.sh && \
    ostree container commit

# Initramfs
COPY ./initramfs.sh /tmp/initramfs.sh
RUN /tmp/initramfs.sh && \
    ostree container commit

# Additional changes
COPY fix-iio-sensor-proxy.te /tmp/fix-iio-sensor-proxy.te
COPY ./additional_changes.sh /tmp/additional_changes.sh
RUN /tmp/additional_changes.sh && \
    ostree container commit
