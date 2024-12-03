#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

### Modifications
# TODO

## Install/Pin Kernel

# Remove Existing Kernel

for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
do
    rpm --erase $pkg --nodeps
done

rpm --erase libwacom libwacom-data --nodeps

for pkg in $(rpm -qa | grep -E 'kmod-xone|kmod-xpadneo|kmod-openrazer|kmod-framework-laptop|kmod-wl|kmod-v4l2loopback')
do
    rpm --erase $pkg --nodeps
done

# Install New Kernel

curl -Lo /etc/yum.repos.d/linux-surface.repo https://pkg.surfacelinux.com/fedora/linux-surface.repo

rpm-ostree install kernel-surface iptsd libwacom-surface libwacom-surface-data surface-secureboot

## Uninstall Asus Packages
ASUS_PACKAGES=(
    asusctl
    asusctl-rog-gui
)

rpm --erase "${ASUS_PACKAGES[@]}" --nodeps

## Fix Screen Rotation

# Install security policy
checkmodule -M -m -o /tmp/fix-iio-sensor-proxy.mod /tmp/fix-iio-sensor-proxy.te
semodule_package -o /tmp/fix-iio-sensor-proxy.pp -m /tmp/fix-iio-sensor-proxy.mod
semodule -i /tmp/fix-iio-sensor-proxy.pp

# Autostart service
systemctl enable iio-sensor-proxy

## Theme GTK3 apps with Adwaita

# Install system-wide theme
rpm-ostree install adw-gtk3-theme

# Install flatpak
flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --system --noninteractive -y org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark

# Configure theme
cat > /usr/share/glib-2.0/schemas/00-custom-theme.gschema.override << EOF
[org.gnome.desktop.interface]
gtk-theme='adw-gtk3-dark'
color-scheme='prefer-dark'
EOF

glib-compile-schemas /usr/share/glib-2.0/schemas/

## Add Mullvad VPN Repo and WireGuard stuff

curl -Lo /etc/yum.repos.d/mullvad.repo https://repository.mullvad.net/rpm/stable/mullvad.repo

rpm-ostree install wireguard-tools

# TODO: Maybe fix OOM Freeze if it happens maybe?

## Install Howdy

# Already installed in Containerfile

## Fix Camera

rpm-ostree install libcamera libcamera-tools libcamera-qcam libcamera-gstreamer libcamera-ipa pipewire-plugin-libcamera

# TODO: Loopback

# TODO: camera quality

# TODO: Wireplumber doesn't use libcamera backend so no app can use the camera.

# TODO: Make user configure howdy
