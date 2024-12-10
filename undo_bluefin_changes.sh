#!/bin/bash

set -ouex pipefail

# Remove Repos
rm -f /etc/yum.repos.d/_copr_lukenukem-asus-linux.repo
rm -f /etc/yum.repos.d/linux-surface.repo

# Remove packages
ASUS_PACKAGES=(
    # asusctl
    # asusctl-rog-gui
)

SURFACE_PACKAGES=(
    iptsd
    # libcamera
    # libcamera-tools
    # libcamera-gstreamer
    # libcamera-ipa
    # pipewire-plugin-libcamera
)

rpm --erase --nodeps \
    "${ASUS_PACKAGES[@]}" \
    "${SURFACE_PACKAGES[@]}"

# Remove modules
# rm /usr/lib/modules-load.d/ublue-surface.conf

# Remove Kernel
for pkg in kernel-surface kernel-surface-core kernel-surface-modules kernel-surface-modules-core
do
    rpm --erase $pkg --nodeps
done

# Remove AKMOD packages
rpm -qa | grep -E '^(xone|xpadneo|openrazer|framework-laptop)' | xargs rpm --erase --nodeps

rpm -qa | grep -E '^(broadcom-wl|wl|v4l2loopback)' | xargs rpm --erase --nodeps

echo "Removed all bluefin changes"
