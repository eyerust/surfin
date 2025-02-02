ARG SOURCE_IMAGE="bluefin"
ARG SOURCE_SUFFIX="-hwe"
ARG SOURCE_TAG="41-20250202"

## Build Howdy
FROM ubuntu:24.04 AS builder

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
    git checkout 03e3efaee29db784d9781befede3a34ef8a3d92e && \
    meson setup build && \
    meson compile -C build && \
    DESTDIR=/tmp/howdy-install meson install -C build

## Build the final image
FROM ghcr.io/ublue-os/${SOURCE_IMAGE}${SOURCE_SUFFIX}:${SOURCE_TAG}

# Copy built files from builder
COPY --from=builder /tmp/howdy-install/ /

# Apply changes
COPY fix-iio-sensor-proxy.te /tmp/fix-iio-sensor-proxy.te
COPY ./build.sh /tmp/build.sh
RUN /tmp/build.sh && ostree container commit
