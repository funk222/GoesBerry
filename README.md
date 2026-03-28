# GoesBerry

**Headless GOES HRIT/GRB receiver and Web UI for Raspberry Pi 5.**

Plug in an RTL-SDR (+ LNA + SAW filter + dish), flash the card, edit one config file, power on — sit back and watch GOES-16/18 imagery appear in your browser.

---

## Features

| | |
|---|---|
| 📡 | Auto-demodulates GOES HRIT via `goesrecv` + `goesproc` (goestools) |
| 🖼 | Web UI at `http://<pi>:8080` — Latest / History / Animation / Status |
| 🔄 | Animated GIF builder with background jobs + cache |
| 🩺 | System health panel (temperature, disk, service status) |
| 💾 | Writes to SSD (`/mnt/goesberry`) by default |
| 🤖 | Fully headless / unattended via `systemd` (`Restart=always`) |

---

## Quick Start

### 1. Requirements

- Raspberry Pi 5 (4 GB or 8 GB)
- Raspberry Pi OS 64-bit (Bookworm)
- RTL-SDR Blog V3 + GOES-band LNA + SAW filter + dish
- USB SSD (≥ 512 GB recommended, mounted at `/mnt/goesberry`)
- Node.js ≥ 18 (`sudo apt install nodejs npm`)

### 2. Install goestools

```bash
sudo bash scripts/install-goestools.sh
```

> First-time build takes ~30 minutes on Pi 5. Progress is shown in the terminal.

### 3. Install GoesBerry

```bash
sudo bash scripts/install.sh
```

### 4. Configure

Edit the file on the **boot partition** (readable from any OS):

```bash
sudo nano /boot/goesberry.conf
```

Minimum viable config:

```bash
CENTER_FREQUENCY_HZ=1694100000
SAMPLE_RATE=2400000
RTL_PPM=0          # calibrate with: rtl_test -p
RTL_GAIN=40        # leave empty for AGC
DATA_ROOT=/mnt/goesberry
WEB_PORT=8080
RETENTION_DAYS=14
```

See [docs/reference-config.md](docs/reference-config.md) for hardware-specific values.

### 5. Reboot

```bash
sudo reboot
```

The `goesberry-firstboot` service runs once, generates all configs, then starts the pipeline. Open `http://<pi-ip>:8080` after ~30 seconds.

---

## SD Card Experiment Workflow

Use this flow for end-to-end validation on real hardware.

### 1. Download and verify image

From GitHub Releases (or Actions artifacts), download:

- `GoesBerry-*.img.xz`
- `GoesBerry-*.img.xz.sha256`

Verify checksum on Windows:

```powershell
certutil -hashfile .\GoesBerry-xxx.img.xz SHA256
```

Compare the printed hash with the value in `.sha256`.

### 2. Flash SD card

Flash `.img.xz` with Raspberry Pi Imager or balenaEtcher.

After flashing, reinsert the SD card and open the `boot` partition.

### 3. Edit `/boot/goesberry.conf`

Minimum settings:

```bash
CENTER_FREQUENCY_HZ=1694100000
SAMPLE_RATE=2400000
RTL_PPM=0
RTL_GAIN=40
DATA_ROOT=/mnt/goesberry
WEB_PORT=8080
RETENTION_DAYS=14
```

If SSD mount is not ready yet, use temporary test path:

```bash
DATA_ROOT=/home/pi/goesberry-test
```

### 4. Power on and wait for first boot setup

Connect SD card + RTL-SDR + LNA/SAW + antenna + SSD, then boot Pi 5.

First boot behavior:

1. `goesberry-firstboot` generates `/etc/goesberry/*`
2. `goesberry-install-tools` compiles goestools (~20–40 min on Pi 5)
3. `goesrecv` and `goesproc` auto-start after build completes
4. Web UI serves on port `8080`

### 5. Validate from SSH

```bash
hostname -I
systemctl status goesberry-firstboot --no-pager
systemctl status goesberry-install-tools --no-pager
journalctl -fu goesberry-install-tools
systemctl status goesberry-web --no-pager
curl http://127.0.0.1:8080/api/health
curl http://127.0.0.1:8080/api/satellites
```

### 6. Acceptance checklist

- `goesberry-firstboot` is `active (exited)`
- `goesberry-install-tools` completed successfully
- `goesrecv` and `goesproc` are `active (running)`
- `http://<pi-ip>:8080` opens
- `/api/health` returns `ok: true`
- Imagery appears in latest/history once signal lock is achieved

### 7. Troubleshooting commands

```bash
journalctl -u goesberry-install-tools -n 200 --no-pager
journalctl -u goesrecv -n 200 --no-pager
journalctl -u goesproc -n 200 --no-pager
journalctl -u goesberry-web -n 200 --no-pager
```

---

## Repository Layout

```
GoesBerry/
├── .github/workflows/ci.yml     # GitHub Actions: build + shellcheck
├── config/
│   ├── goesberry.conf.template  # User-facing boot config template
│   ├── goesrecv.conf.template   # goesrecv TOML template (envsubst)
│   └── goesproc.conf.template   # goesproc TOML template (envsubst)
├── docs/
│   └── reference-config.md      # Verified hardware parameters
├── packaging/systemd/           # systemd .service and .timer units
├── scripts/
│   ├── firstboot.sh             # Invoked once by systemd on first boot
│   ├── install-goestools.sh     # Builds goesrecv + goesproc from source
│   ├── install.sh               # Installs GoesBerry onto a running Pi OS
│   └── cleanup.sh               # Daily housekeeping (called by timer)
└── web/
    ├── backend/                 # Node/Express API (health/satellites/latest/history/gif)
    └── frontend/                # Vue 3 + Vite SPA (Latest/History/Animation/Status)
```

---

## Web API

| Method | Path | Description |
|--------|------|-------------|
| `GET`  | `/api/health` | System temperature, disk, service statuses |
| `GET`  | `/api/satellites` | List detected satellites (from products dir) |
| `GET`  | `/api/latest?sat=GOES-16&limit=10` | Latest N product images |
| `GET`  | `/api/history?sat=GOES-16&date=YYYY-MM-DD&product=FD_CH13` | Historical index |
| `POST` | `/api/gif` `{sat, product, window, endTime?}` | Start GIF generation job |
| `GET`  | `/api/gif/:jobId` | Poll job status / get result URL |

---

## Milestones

- [x] **M0** — Repo skeleton: backend API + Vue3 frontend + systemd units + scripts
- [ ] **M1** — Pi 5 integration: goestools running, health.json live, products landing on SSD
- [ ] **M2** — Web UI MVP: latest/history browsable, multi-satellite auto-discovery
- [ ] **M3** — Animation GIF + cache + retention fully operational
- [ ] **M4** — Image build (pi-gen/rpi-image-gen) + GitHub Releases

---

## License

MIT — see [LICENSE](LICENSE).
