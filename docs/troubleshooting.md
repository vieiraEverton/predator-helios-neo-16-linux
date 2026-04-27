# Troubleshooting

## `/proc/acpi/call: No such file or directory`

The `acpi_call` module is not loaded.

```bash
sudo modprobe acpi_call
ls /proc/acpi/call   # should exist now
```

If `modprobe` fails, reinstall the package:

```bash
sudo apt install --reinstall acpi-call-dkms
sudo modprobe acpi_call
```

After a kernel update, DKMS must rebuild the module:

```bash
sudo dkms autoinstall
```

---

## GPU still capped at 80W after install

**Check 1** — Is nvidia-powerd running in turbo mode?

```bash
sudo predator-mode turbo
systemctl status nvidia-powerd
```

**Check 2** — Verify the power cap changed:

```bash
nvidia-smi -q | grep -E "Current Power Limit|Max Power Limit"
```

Expected: `Current Power Limit: 115.00 W`

**Check 3** — If `nvidia-powerd.service` was not found during install, verify the path for your driver version:

```bash
find /usr/share/doc -name "nvidia-powerd.service"
```

Then manually copy it:

```bash
sudo cp <found-path> /etc/systemd/system/nvidia-powerd.service
sudo systemctl daemon-reload
sudo predator-mode turbo
```

---

## Button press does nothing

**Check 1** — Is the service running?

```bash
systemctl status predator-button
sudo journalctl -u predator-button --no-pager | tail -20
```

**Check 2** — Test the script directly:

```bash
sudo python3 /usr/local/lib/predator/predator-button.py
# Press the button — you should see "PredatorSense button pressed"
```

**Check 3** — Verify the device is detected:

```bash
sudo evtest /dev/input/event2
# Press the button — look for: type 1 (EV_KEY), code 425 (KEY_PRESENTATION)
```

If code 425 appears on a different device, the daemon will find it automatically via the bustype+name search. If it still fails, check for USB keyboards that also advertise KEY_PRESENTATION and disconnect them temporarily to verify.

---

## `predator-button` service crashes repeatedly

```bash
sudo journalctl -u predator-button --no-pager | tail -30
```

Common causes:
- `python3-evdev` not installed: `sudo apt install python3-evdev`
- Device path changed after adding/removing USB keyboards: restart the service after changing USB config

---

## After NVIDIA driver update

The `nvidia-powerd` binary path or the service file may have changed. Re-run the installer:

```bash
sudo bash install.sh
```

---

## Check overall status

```bash
sudo predator-mode status
systemctl status predator-button nvidia-powerd
lsmod | grep acpi_call
nvidia-smi | grep Pwr
```
