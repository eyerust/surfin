#!/bin/bash

set -ouex pipefail

# Add Repo
tee /etc/yum.repos.d/linux-surface.repo << EOF
[linux-surface]
name=linux-surface
baseurl=https://pkg.surfacelinux.com/fedora/f40/
enabled=1
skip_if_unavailable=1
gpgkey=https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc
gpgcheck=1
enabled_metadata=1
type=rpm-md
repo_gpgcheck=0
EOF

# Fetch Kernel
KERNEL_VERSION="6.10.10-1"
mkdir -p /tmp/kernel
curl -s https://pkg.surfacelinux.com/fedora/f40/ | grep -o 'href=".*rpm' | sed 's/href="//g' | grep 'kernel' | grep $KERNEL_VERSION | \
while read file; do
    echo "Downloading $file..."
    wget -q "https://pkg.surfacelinux.com/fedora/f40/$file" -P /tmp/kernel
done
ls /tmp/kernel

# Install Kernel
rpm-ostree install \
    /tmp/kernel/kernel-surface-[0-9]*.rpm \
    /tmp/kernel/kernel-surface-core-[0-9]*.rpm \
    /tmp/kernel/kernel-surface-modules-[0-9]*.rpm \
    /tmp/kernel/kernel-surface-modules-core-[0-9]*.rpm \
    /tmp/kernel/kernel-surface-modules-extra-[0-9]*.rpm \
    /tmp/kernel/kernel-surface-modules-internal-[0-9]*.rpm \
    /tmp/kernel/kernel-surface-devel-[0-9]*.rpm

# Fetch IPTSD
IPTSD_VERSION="3-1"
IPTSD_FEDORA_VERSION="f41"
mkdir -p /tmp/iptsd
curl -s https://pkg.surfacelinux.com/fedora/$IPTSD_FEDORA_VERSION/ | grep -o 'href=".*rpm' | sed 's/href="//g' | grep 'iptsd' | grep $IPTSD_VERSION | \
while read file; do
    echo "Downloading $file..."
    wget -q "https://pkg.surfacelinux.com/fedora/$IPTSD_FEDORA_VERSION/$file" -P /tmp/iptsd
done
ls /tmp/iptsd

# Install IPTSD
rpm-ostree install \
    /tmp/iptsd/iptsd-[0-9]*.rpm

## Libwacom
# Erase if installed
rpm --erase libwacom libwacom-data --nodeps

# Fetch Libwacom Surface
LIBWACOM_VERSION='2.13.0-2'
mkdir -p /tmp/libwacom
curl -s https://pkg.surfacelinux.com/fedora/f40/ | grep -o 'href=".*rpm' | sed 's/href="//g' | grep 'libwacom' |  grep $LIBWACOM_VERSION | \
while read file; do
    echo "Downloading $file..."
    wget -q "https://pkg.surfacelinux.com/fedora/f40/$file" -P /tmp/libwacom
done
ls /tmp/libwacom

# Install Libwacom Surface
rpm-ostree install \
    /tmp/libwacom/libwacom-surface-[0-9]*.rpm \
    /tmp/libwacom/libwacom-surface-data-[0-9]*.rpm \
    /tmp/libwacom/libwacom-surface-utils-[0-9]*.rpm

# Fetch the rest
mkdir -p /tmp/rest
curl -s https://pkg.surfacelinux.com/fedora/f40/ | grep -o 'href=".*rpm' | sed 's/href="//g' | grep -v 'kernel' | grep -v 'iptsd' | grep -v 'libwacom' | grep 'fc40' | \
while read file; do
    echo "Downloading $file..."
    wget -q "https://pkg.surfacelinux.com/fedora/f40/$file" -P /tmp/rest
done
ls /tmp/rest

# Install the rest
rpm-ostree install \
    /tmp/rest/*

# Load kernel modules
tee /usr/lib/modules-load.d/ublue-surface.conf << EOF
# Add modules necessary for Disk Encryption via keyboard
surface_aggregator
surface_aggregator_registry
surface_aggregator_hub
surface_hid_core
8250_dw

# Surface Laptop 3/Surface Book 3 and later
surface_hid
surface_kbd

# Only on AMD models
pinctrl_amd

# Only on Intel models
intel_lpss
intel_lpss_pci

# For Surface Laptop 3/Surface Book 3
pinctrl_icelake

# For Surface Laptop 4/Surface Laptop Studio
pinctrl_tigerlake
EOF

echo "Installed all linux surface changes"
