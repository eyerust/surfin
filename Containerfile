ARG SOURCE_IMAGE="bluefin"
ARG SOURCE_SUFFIX="-hwe"
ARG SOURCE_TAG="latest"

FROM ghcr.io/ublue-os/${SOURCE_IMAGE}${SOURCE_SUFFIX}:${SOURCE_TAG}

COPY build.sh /tmp/build.sh
COPY fix-iio-sensor-proxy.te /tmp/fix-iio-sensor-proxy.te

RUN mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    ostree container commit
