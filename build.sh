#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

### Modifications
# TODO

## Pin Kernel
KERNEL="6.11.9-305.bazzite.fc41.x86_64"

# Remove Existing Kernel
for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra
do
    rpm --erase $pkg --nodeps
done

# Fetch Kernel
AKMODS_FLAVOR="bazzite"
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/"${AKMODS_FLAVOR}"-kernel:"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/kernel-rpms
KERNEL_TARGZ=$(jq -r '.layers[].digest' < /tmp/kernel-rpms/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/kernel-rpms/"$KERNEL_TARGZ" -C /
mv /tmp/rpms/* /tmp/kernel-rpms/

# Install Kernel
rpm-ostree install \
    /tmp/kernel-rpms/kernel-[0-9]*.rpm \
    /tmp/kernel-rpms/kernel-core-*.rpm \
    /tmp/kernel-rpms/kernel-modules-*.rpm

# Fetch Common AKMODS
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)"-"${KERNEL}" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' < /tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/

# Everyone
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

for pkg in $(rpm -qa | grep -E 'kmod-xone|kmod-xpadneo|kmod-openrazer|kmod-framework-laptop|kmod-wl|kmod-v4l2loopback')
do
    rpm --erase $pkg --nodeps
done

rpm-ostree install \
    /tmp/akmods/kmods/*xone*.rpm \
    /tmp/akmods/kmods/*xpadneo*.rpm \
    /tmp/akmods/kmods/*openrazer*.rpm \
    /tmp/akmods/kmods/*framework-laptop*.rpm

# RPMFUSION Dependent AKMODS
rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
rpm-ostree install \
    broadcom-wl /tmp/akmods/kmods/*wl*.rpm \
    v4l2loopback /tmp/akmods/kmods/*v4l2loopback*.rpm
rpm-ostree uninstall rpmfusion-free-release rpmfusion-nonfree-release

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
flatpak install --system --noninteractive -y org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark

# Configure theme
cat > /usr/share/glib-2.0/schemas/00-custom-theme.gschema.override << EOF
[org.gnome.desktop.interface]
gtk-theme='adw-gtk3-dark'
color-scheme='prefer-dark'
EOF

glib-compile-schemas /usr/share/glib-2.0/schemas/