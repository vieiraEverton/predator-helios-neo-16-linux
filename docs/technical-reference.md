# Technical Reference

## WMI Gaming Interface

| Field | Value |
|---|---|
| Gaming WMI GUID | `7A4DDFE7-5B5D-40B4-8595-4408E0CC7F56` |
| ACPI object_id | `BH` |
| ACPI path | `\_SB_.PC00.WMID.WMBH` (found in SSDT18) |
| WMI methods | `WMBH` (set), `WQBH` (query), `WSBH` (method call) |

### WMBH Call Format

```
\_SB_.PC00.WMID.WMBH 0x01 0x16 {0x0B, <mode>, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
```

| Mode byte | LED colour | Fan speed | TGP |
|---|---|---|---|
| `0x01` | Blue | Normal | 80W |
| `0x04` | White | High | ~100W |
| `0x05` | Purple | Maximum | 115W (with nvidia-powerd) |

## NPCF (NVIDIA Platform Control Framework)

| Field | Value |
|---|---|
| Device | `NVDA0820:00` |
| Driver | `nv_platform` |
| ACPI fields | `ACBT`, `AMAT`, `ATPP`, `NVWM` |
| TGP unit | 0.5W per unit |
| ACBT=160 | 80W (160 × 0.5W) |
| ACBT=230 | 115W (230 × 0.5W) |

## Physical Button

| Field | Value |
|---|---|
| Input device | `AT Translated Set 2 keyboard` |
| Bus type | `0x11` (PS/2 / i8042) |
| Default path | `/dev/input/event2` (can vary) |
| Event type | `EV_KEY` (type 1) |
| Key code | `425` (`KEY_PRESENTATION`) |
| Scan code | `0xF5` |

## nvidia-powerd

| Field | Value |
|---|---|
| Binary | `/usr/bin/nvidia-powerd` |
| Service source | `/usr/share/doc/nvidia-kernel-common-<ver>-server/nvidia-powerd.service` |
| Log directory | `/var/log/nvtopps/` |
| D-Bus name | `nvidia.powerd.server` |
| Function | Dynamic Boost 2.0 — redistributes CPU+GPU power budget in real time |

## GPU Power Limits

| State | Power cap |
|---|---|
| Default (no nvidia-powerd) | 80W |
| nvidia-powerd running | 115W |
| Observed under OpenCL stress | ~97W (CPU takes some of the shared budget) |
| Max hardware | 115W |

## CPU Power (RAPL)

| Limit | Value |
|---|---|
| PL1 (sustained) | 200W |
| PL2 (boost) | 160W |

These values were already correctly configured and were not modified by this fix.
