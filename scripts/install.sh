#!/usr/bin/env bash
# Install GoesBerry web app + systemd units onto Raspberry Pi OS.
# Must be run as root after goestools is already installed.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="/opt/goesberry"
SYSTEMD_DIR="/etc/systemd/system"
NODE_BIN="${NODE_BIN:-/usr/bin/node}"

log() { echo "==> [install] $*"; }

# ── Pre-checks ────────────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: Please run as root (sudo)." >&2
  exit 1
fi
if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js not found. Install it first (e.g. apt install nodejs)." >&2
  exit 1
fi
if ! command -v npm &>/dev/null; then
  echo "ERROR: npm not found." >&2
  exit 1
fi

# ── Backend ───────────────────────────────────────────────────────────────
log "Installing backend npm dependencies..."
cd "${REPO_ROOT}/web/backend"
npm install --omit=dev

# ── Frontend ──────────────────────────────────────────────────────────────
log "Installing frontend npm dependencies..."
cd "${REPO_ROOT}/web/frontend"
npm install

log "Building frontend (Vite)..."
npm run build

# ── Copy to install dir ───────────────────────────────────────────────────
log "Copying files to ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}/web/backend"
mkdir -p "${INSTALL_DIR}/web/frontend/dist"
mkdir -p "${INSTALL_DIR}/config"

rsync -a --delete "${REPO_ROOT}/web/backend/"   "${INSTALL_DIR}/web/backend/"
rsync -a --delete "${REPO_ROOT}/web/frontend/dist/" "${INSTALL_DIR}/web/frontend/dist/"
rsync -a --delete "${REPO_ROOT}/config/"        "${INSTALL_DIR}/config/"

# ── Helper scripts ────────────────────────────────────────────────────────
log "Installing helper scripts to /usr/local/bin/..."
install -m 755 "${REPO_ROOT}/scripts/firstboot.sh" /usr/local/bin/goesberry-firstboot.sh
install -m 755 "${REPO_ROOT}/scripts/cleanup.sh"   /usr/local/bin/goesberry-cleanup.sh

# ── systemd units ────────────────────────────────────────────────────────
log "Installing systemd units..."
for f in "${REPO_ROOT}/packaging/systemd/"*.service \
          "${REPO_ROOT}/packaging/systemd/"*.timer; do
  install -m 644 "$f" "${SYSTEMD_DIR}/"
done

systemctl daemon-reload

log "Enabling systemd units..."
systemctl enable goesberry-firstboot.service
systemctl enable goesrecv.service
systemctl enable goesproc.service
systemctl enable goesberry-web.service
systemctl enable goesberry-cleanup.timer

log ""
log "GoesBerry installed successfully."
log "  1. Edit /boot/goesberry.conf"
log "  2. Reboot (firstboot script will configure everything)"
log "  3. Access Web UI at http://<pi-ip>:8080"
