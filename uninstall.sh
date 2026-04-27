#!/bin/bash
# uninstall.sh — Remove all components installed by install.sh

set -e
[ "$(id -u)" -ne 0 ] && { echo "Run as root: sudo bash uninstall.sh"; exit 1; }

echo "Removing Predator Helios Neo 16 AI Linux performance fix..."

systemctl disable --now predator-button 2>/dev/null || true
systemctl stop nvidia-powerd 2>/dev/null || true

rm -f /usr/local/bin/predator-mode
rm -f /usr/local/lib/predator/predator-button.py
rmdir /usr/local/lib/predator 2>/dev/null || true
rm -f /etc/systemd/system/predator-button.service
rm -f /etc/systemd/system/nvidia-powerd.service
rm -f /etc/dbus-1/system.d/nvidia-powerd.conf
rm -f /etc/modules-load.d/acpi-call.conf
rm -f /var/tmp/predator_mode

systemctl daemon-reload

echo "Done. Reboot to restore defaults."
