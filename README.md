# Predator Helios Neo 16 AI — Linux Performance Fix

> Unlock full GPU TGP (115W) and turbo fan control on the Acer Predator Helios Neo 16 AI under Linux.

**[Leia em Português](README.pt-BR.md)**

---

## The Problem

On Ubuntu (and other Linux distros), the RTX 5070 Laptop is hard-capped at **80W TGP**. On Windows, PredatorSense activates Turbo mode and the GPU operates at **115W**. Fans also don't reach max speed.

| | Linux (before) | Linux (after) | Windows |
|---|---|---|---|
| GPU Power Cap | 80W | **115W** | 115W |
| GPU under load | ~80W | **~97W** (Dynamic Boost) | ~115W |
| Turbo fans | ✗ | ✓ | ✓ |
| Physical button | ✗ | ✓ | ✓ |

---

## Hardware

| Component | Spec |
|---|---|
| Laptop | Acer Predator Helios Neo 16 AI |
| GPU | NVIDIA GeForce RTX 5070 Laptop |
| CPU | Intel Core Ultra 9 275HX |
| Tested kernel | 6.17.0-22-generic |
| Tested driver | NVIDIA 590.48.01 |
| Tested OS | Ubuntu 24.04 |

---

## Root Cause

Two issues were identified:

1. **nvidia-powerd not installed as a service** — NVIDIA's Dynamic Boost 2.0 daemon ships inside the `nvidia-kernel-common-*-server` package but its systemd unit is not auto-installed. Without it, the driver defaults to 80W TGP.

2. **No WMI driver for the gaming GUID** — The gaming WMI GUID `7A4DDFE7-5B5D-40B4-8595-4408E0CC7F56` (ACPI object_id `BH`) has no Linux driver. However, direct ACPI calls via `acpi_call` work and correctly control fan speed and LED mode.

---

## Quick Install

```bash
git clone https://github.com/YOUR_USERNAME/predator-helios-neo-16-linux.git
cd predator-helios-neo-16-linux
sudo bash install.sh
```

> **Secure Boot note:** If Secure Boot is enabled, the `acpi_call` kernel module must have its signing key enrolled in the MOK database. Ubuntu's `acpi-call-dkms` package handles signing automatically, but the key enrollment requires a one-time reboot confirmation in the MOK Manager. If the installer warns that `acpi_call` failed to load, see [Troubleshooting](docs/troubleshooting.md).

---

## What Gets Installed

| File | Location | Purpose |
|---|---|---|
| `predator-mode` | `/usr/local/bin/` | Mode management script |
| `predator-button.py` | `/usr/local/lib/predator/` | Physical button daemon |
| `predator-button.service` | `/etc/systemd/system/` | Systemd unit (auto-start) |
| `nvidia-powerd.service` | `/etc/systemd/system/` | Dynamic Boost service |
| `nvidia-powerd.conf` | `/etc/dbus-1/system.d/` | D-Bus policy |
| `acpi-call.conf` | `/etc/modules-load.d/` | Load acpi_call at boot |

---

## Usage

```bash
sudo predator-mode turbo      # GPU 115W + max fans + purple LED
sudo predator-mode balanced   # GPU 80W + normal fans + blue LED
sudo predator-mode toggle     # switch between modes
sudo predator-mode status     # show current mode and GPU power
```

The **PredatorSense button** (the one that opens PredatorSense on Windows) also toggles between modes.

---

## Boot Behaviour

The BIOS always resets to balanced mode on boot. The setup accounts for this:

| Event | State |
|---|---|
| Boot | Balanced mode, GPU 80W |
| `predator-button` service starts | Writes `balanced` to state file |
| 1st button press | → Turbo: GPU 115W, max fans |
| 2nd button press | → Balanced: GPU 80W, normal fans |

---

## How It Works

### GPU Power (nvidia-powerd)

`nvidia-powerd` is NVIDIA's Dynamic Boost 2.0 daemon. It redistributes the shared CPU+GPU power budget in real time. Without it, the driver uses a conservative static TGP of 80W.

- **Turbo mode** → `systemctl start nvidia-powerd` → GPU cap rises to 115W
- **Balanced mode** → `systemctl stop nvidia-powerd` → GPU cap returns to 80W

> `nvidia-powerd` is **not** enabled at boot. It is started/stopped by `predator-mode` to ensure the GPU only draws 115W when fans are at full speed.

### Fan & LED Control (ACPI/WMI)

The fan speed and LED colour are controlled via direct ACPI calls using the gaming WMI method `\_SB_.PC00.WMID.WMBH`:

| Mode byte | Effect |
|---|---|
| `0x01` | Balanced — blue LED, quiet fans |
| `0x05` | Turbo — purple LED, max fans |

### Physical Button

The PredatorSense button generates `EV_KEY` code **425** (`KEY_PRESENTATION`, scan `0xF5`) on the internal PS/2 keyboard (`bustype 0x11`, `AT Translated Set 2 keyboard`).

The `predator-button.py` daemon detects the device by bus type + name (not by `/dev/input/eventN` number, which can change with USB devices connected).

---

## After a Driver Update

After updating the NVIDIA driver, check if the service file path has changed:

```bash
find /usr/share/doc -name "nvidia-powerd.service"
```

If the version number changed (e.g. `590` → `600`), re-run the installer:

```bash
sudo bash install.sh
```

---

## Uninstall

```bash
sudo bash uninstall.sh
```

---

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md).

---

## Technical Reference

See [docs/technical-reference.md](docs/technical-reference.md).

---

## Contributing

Issues and PRs are welcome. If you have a different Predator model and the WMI paths differ, please open an issue with the output of:

```bash
sudo modprobe acpi_call
sudo bash -c 'printf "\_SB_.PC00.WMID.WMBH 0x01 0x16 {0x0B,0x05,0x00,0x00,0x00,0x00,0x00,0x00}\n" > /proc/acpi/call && cat /proc/acpi/call'
```

---

## License

MIT
