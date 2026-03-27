# GoesBerry Reference Configuration

This document records verified working parameters for common hardware setups.

## Reference Setup (GOES-16, LNA + SAW + RTL-SDR v3)

| Parameter              | Value          | Notes                                               |
|------------------------|----------------|-----------------------------------------------------|
| `CENTER_FREQUENCY_HZ`  | `1694100000`   | GOES HRIT downlink (1694.1 MHz)                     |
| `SAMPLE_RATE`          | `2400000`      | 2.4 Msps — sufficient for HRIT symbol rate          |
| `RTL_PPM`              | `0`            | Depends on your dongle; run `rtl_test -p` to check  |
| `RTL_GAIN`             | `40`           | LNA ahead of RTL-SDR; lower if over-driven          |
| `RETENTION_DAYS`       | `14`           | ~28 GB/day × 14 days ≈ ~390 GB minimum SSD needed   |

## Recommended Hardware

- **RTL-SDR**: RTL-SDR Blog V3 (0bda:2838)
- **LNA**: Nooelec SAWbird+ GOES or similar filtered LNA at 1694 MHz
- **Dish**: 80–120 cm offset dish aimed at GOES-16 (75.2°W) or GOES-18 (137.0°W)
- **SSD**: 1 TB USB3 SSD mounted at `/mnt/goesberry` (ext4, `noatime`)

## Calibrating PPM Offset

```bash
rtl_test -p 60   # let it run 60 s; note the reported PPM value
```

Set `RTL_PPM` in `/boot/goesberry.conf` to the reported value (e.g. `RTL_PPM=3`), then reboot.

## Checking Lock Status

```bash
# Check goesrecv health port (UDP stats broadcast)
nc -u 127.0.0.1 5004

# Follow logs
journalctl -fu goesrecv
journalctl -fu goesproc
journalctl -fu goesberry-web
```

## Directory Layout on SSD

```
/mnt/goesberry/
├── products/
│   ├── GOES-16/
│   │   └── 2026/03/27/
│   │       ├── GOES16_FD_CH13_20260327T120000Z.png
│   │       └── ...
│   └── GOES-18/
├── raw/            # optional raw VCDUs
├── cache/          # generated GIFs (auto-cleaned)
└── log/            # reserved for optional file-based logging
```
