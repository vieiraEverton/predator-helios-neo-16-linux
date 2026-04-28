#!/bin/bash
# install.sh — Automated installer for Predator Helios Neo 16 AI Linux performance fix
# Tested on: Ubuntu 24.04, kernel 6.17, driver NVIDIA 590.48.01

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

[ "$(id -u)" -ne 0 ] && err "Run as root: sudo bash install.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "=================================================="
echo " Predator Helios Neo 16 AI — Linux Performance Fix"
echo "=================================================="
echo ""

# ── 1. Dependencies ──────────────────────────────────────────────────────────
echo "[ 1/6 ] Installing dependencies..."
apt-get install -y acpi-call-dkms acpica-tools python3-evdev > /dev/null 2>&1
ok "Dependencies installed"

# ── 2. acpi_call module at boot ──────────────────────────────────────────────
echo "[ 2/6 ] Configuring kernel modules..."
cp "$SCRIPT_DIR/modules/acpi-call.conf" /etc/modules-load.d/acpi-call.conf
if modprobe acpi_call 2>/dev/null; then
    ok "acpi_call loaded"
else
    warn "acpi_call load failed — possible causes:"
    warn "  1. Reboot required (module will load automatically on next boot)"
    warn "  2. Secure Boot is enabled and the MOK key is not enrolled"
    warn "     → See docs/troubleshooting.md section 'Secure Boot / MOK'"
fi

# ── 3. nvidia-powerd service ─────────────────────────────────────────────────
echo "[ 3/6 ] Setting up nvidia-powerd (Dynamic Boost 2.0)..."
mkdir -p /var/log/nvtopps

NVIDIA_SERVICE_SRC=$(find /usr/share/doc -name "nvidia-powerd.service" 2>/dev/null | head -1)
if [ -n "$NVIDIA_SERVICE_SRC" ]; then
    cp "$NVIDIA_SERVICE_SRC" /etc/systemd/system/nvidia-powerd.service
    ok "nvidia-powerd.service installed from $NVIDIA_SERVICE_SRC"
else
    cp "$SCRIPT_DIR/systemd/nvidia-powerd.service" /etc/systemd/system/nvidia-powerd.service
    warn "nvidia-powerd.service source not found — using bundled fallback"
fi

cp "$SCRIPT_DIR/dbus/nvidia-powerd.conf" /etc/dbus-1/system.d/nvidia-powerd.conf
ok "D-Bus policy installed"

# nvidia-powerd is NOT enabled at boot — predator-mode controls it
systemctl disable nvidia-powerd 2>/dev/null || true
systemctl daemon-reload

# ── 4. predator-mode script ──────────────────────────────────────────────────
echo "[ 4/6 ] Installing predator-mode..."
cp "$SCRIPT_DIR/scripts/predator-mode" /usr/local/bin/predator-mode
chmod +x /usr/local/bin/predator-mode
ok "predator-mode installed at /usr/local/bin/predator-mode"

# ── 5. predator-button daemon ────────────────────────────────────────────────
echo "[ 5/6 ] Installing button daemon..."
mkdir -p /usr/local/lib/predator
cp "$SCRIPT_DIR/scripts/predator-button.py" /usr/local/lib/predator/predator-button.py
cp "$SCRIPT_DIR/systemd/predator-button.service" /etc/systemd/system/predator-button.service
systemctl daemon-reload
systemctl enable --now predator-button
ok "predator-button.service enabled and started"

# ── 6. Verify ────────────────────────────────────────────────────────────────
echo "[ 6/6 ] Verifying installation..."
sleep 2

STATUS=$(systemctl is-active predator-button 2>/dev/null)
if [ "$STATUS" = "active" ]; then
    ok "predator-button service is running"
else
    warn "predator-button service status: $STATUS — check: sudo journalctl -u predator-button"
fi

if [ -f /proc/acpi/call ]; then
    ok "/proc/acpi/call is available"
else
    warn "/proc/acpi/call not found — acpi_call will load on next reboot"
fi

echo ""
echo "=================================================="
echo " Installation complete!"
echo ""
echo " Usage:"
echo "   sudo predator-mode turbo      # GPU 115W + max fans"
echo "   sudo predator-mode balanced   # GPU 80W + normal fans"
echo "   sudo predator-mode toggle     # toggle (also: physical button)"
echo "   sudo predator-mode status     # current state"
echo ""
echo " The PredatorSense button now toggles modes."
echo " On every boot the system starts in balanced mode."
echo "=================================================="
echo ""
