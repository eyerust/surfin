#!/bin/bash

set -ouex pipefail

## 1. Remove ASUS
rpm --erase --nodeps asusctl asusctl-rog-gui

## 2. Fix Screen Rotation

# Install security policy
checkmodule -M -m -o /tmp/fix-iio-sensor-proxy.mod /tmp/fix-iio-sensor-proxy.te
semodule_package -o /tmp/fix-iio-sensor-proxy.pp -m /tmp/fix-iio-sensor-proxy.mod
semodule -i /tmp/fix-iio-sensor-proxy.pp

# Autostart service
systemctl enable iio-sensor-proxy

## 3. Theme GTK3 apps with Adwaita

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

## 4. Add Mullvad VPN Repo and WireGuard stuff

curl -Lo /etc/yum.repos.d/mullvad.repo https://repository.mullvad.net/rpm/stable/mullvad.repo

rpm-ostree install wireguard-tools

## 5. Microsoft Surface Pen should be tablet or touch

# Udev rule for Surface Pen
RULE_FILE="99-surface-pen-as-touch-or-tablet.rules"
RULE_PATH="/usr/lib/udev/rules.d/$RULE_FILE"

cat > "$RULE_PATH" << 'EOF'
ACTION=="add", SUBSYSTEM=="input", \
ATTR{name}=="*[Ss]tylus*", \
ENV{ID_INPUT_TABLET}=="1", \
PROGRAM="/bin/cat /var/run/pen-mode-state", \
RESULT=="touch", \
ENV{ID_INPUT_TABLET}="0", \
ENV{ID_INPUT_TOUCHSCREEN}="1"
EOF

chmod 644 "$RULE_PATH"

# Script to switch mode
SCRIPT_PATH="/usr/local/bin/toggle-pen-mode.sh"
cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
STATE_FILE="/var/run/pen-mode-state"

# Initialize state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "touch" > "$STATE_FILE"
fi

# Toggle state
current_state=$(cat "$STATE_FILE")
if [ "$current_state" = "touch" ]; then
    echo "tablet" > "$STATE_FILE"
    # Set tablet mode
    udevadm trigger --subsystem-match=input
else
    echo "touch" > "$STATE_FILE"
    # Set touch mode
    udevadm trigger --subsystem-match=input
fi
EOF

chmod +x "$SCRIPT_PATH"

# On eraser button press, toggle pen mode
# Python script to handle eraser button
BUTTON_SCRIPT="/usr/local/bin/pen-button-monitor.py"
cat > "$BUTTON_SCRIPT" << 'EOF'
#!/usr/bin/env python3
from evdev import InputDevice, categorize, ecodes
import sys
import os
import time
from datetime import datetime

def log(message):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{timestamp}] {message}")

def find_pen_keyboard():
    from evdev import list_devices, InputDevice
    for path in list_devices():
        try:
            device = InputDevice(path)
            if "surface pen keyboard" in device.name.lower():
                log(f"Found device: {device.name}")
                return device
        except PermissionError:
            continue
    return None

def main():
    while True:
        device = find_pen_keyboard()
        if device:
            log(f"Watching {device.name}")
            try:
                meta_pressed = False
                for event in device.read_loop():
                    if event.type == ecodes.EV_KEY:
                        key_event = categorize(event)
                        log(f"Key event: {key_event.keycode}, value: {event.value}")
                        
                        if event.code == ecodes.KEY_LEFTMETA:
                            meta_pressed = event.value == 1
                            log(f"Meta key {'pressed' if meta_pressed else 'released'}")
                        elif event.code == ecodes.KEY_F20 and event.value == 1 and meta_pressed:
                            log("Toggling pen mode...")
                            os.system('/usr/local/bin/toggle-pen-mode.sh')
            except OSError:
                log("Device disconnected. Waiting for reconnection...")
        else:
            log("Waiting for Surface Pen keyboard...")
        
        time.sleep(2)

if __name__ == "__main__":
    main()
EOF

chmod +x "$BUTTON_SCRIPT"

# Create systemd service
SERVICE_FILE="/etc/systemd/system/pen-button-monitor.service"
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Surface Pen Button Monitor
After=bluetooth.service

[Service]
ExecStart=$BUTTON_SCRIPT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

chmod 644 "$SERVICE_FILE"

systemctl enable pen-button-monitor

rpm-ostree install python3-evdev libnotify

# Visual feedback

echo "Done"
