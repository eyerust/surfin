#!/bin/bash

set -ouex pipefail

# Remove Repos
rm /etc/yum.repos.d/_copr_lukenukem-asus-linux.repo

# Remove packages
ASUS_PACKAGES=(
    asusctl
    asusctl-rog-gui
)

SURFACE_PACKAGES=(
    libcamera
    libcamera-tools
    libcamera-gstreamer
    libcamera-ipa
    pipewire-plugin-libcamera
)

rpm --erase --nodeps \
    "${ASUS_PACKAGES[@]}" \
    "${SURFACE_PACKAGES[@]}"

echo "Removed all bluefin changes"
