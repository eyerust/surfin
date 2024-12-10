#!/bin/bash

set -ouex pipefail

## Fix Screen Rotation

# Install security policy
# checkmodule -M -m -o /tmp/fix-iio-sensor-proxy.mod /tmp/fix-iio-sensor-proxy.te
# semodule_package -o /tmp/fix-iio-sensor-proxy.pp -m /tmp/fix-iio-sensor-proxy.mod
# semodule -i /tmp/fix-iio-sensor-proxy.pp

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

echo "Done"
