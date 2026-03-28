#!/usr/bin/env bash
# ============================================================
#  GoesBerry – Local image build script
#  Builds a ready-to-flash .img.xz for Raspberry Pi 5.
#
#  Requirements (Ubuntu 22.04+ recommended):
#    - Docker (running, current user in docker group or run as root)
#    - Node.js >=18 + npm
#    - git, xz-utils
#
#  Usage:
#    sudo bash packaging/build-image.sh [--skip-frontend]
# ============================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIGEN_DIR="${PIGEN_DIR:-/tmp/goesberry-pi-gen}"
DEPLOY_DIR="${DEPLOY_DIR:-${REPO_ROOT}/deploy}"
SKIP_FRONTEND="${1:-}"

log()  { echo -e "\033[1;34m==>\033[0m $*"; }
ok()   { echo -e "\033[1;32m OK\033[0m $*"; }
die()  { echo -e "\033[1;31mERR\033[0m $*" >&2; exit 1; }

# ── Pre-checks ────────────────────────────────────────────────────────────
command -v docker &>/dev/null || die "Docker not found. Install Docker first."
command -v node   &>/dev/null || die "Node.js not found."
command -v npm    &>/dev/null || die "npm not found."
command -v xz     &>/dev/null || die "xz not found (apt install xz-utils)."

# ── Build Vue3 frontend ───────────────────────────────────────────────────
if [[ "$SKIP_FRONTEND" != "--skip-frontend" ]]; then
  log "Building Vue3 frontend..."
  cd "${REPO_ROOT}/web/frontend"
  npm install
  npm run build
  ok "Frontend built → web/frontend/dist/"
fi

# ── Pre-install backend node_modules on host (pure-JS, arch-independent) ──
log "Installing backend Node.js dependencies..."
cd "${REPO_ROOT}/web/backend"
npm install --omit=dev --no-audit --no-fund
ok "Backend node_modules installed"

# ── Clone pi-gen ─────────────────────────────────────────────────────────
if [[ -d "$PIGEN_DIR" ]]; then
  log "Updating existing pi-gen clone..."
  git -C "$PIGEN_DIR" pull --ff-only
else
  log "Cloning pi-gen..."
  git clone --depth=1 https://github.com/RPi-Distro/pi-gen.git "$PIGEN_DIR"
fi

# ── Skip intermediate stage images ───────────────────────────────────────
touch "${PIGEN_DIR}/stage0/SKIP_IMAGES"
touch "${PIGEN_DIR}/stage1/SKIP_IMAGES"
touch "${PIGEN_DIR}/stage2/SKIP_IMAGES"

# ── Populate stage-goesberry ─────────────────────────────────────────────
log "Populating stage-goesberry..."
STAGE_DIR="${PIGEN_DIR}/stage-goesberry/01-goesberry"
STAGE_FILES="${STAGE_DIR}/files"
mkdir -p "${STAGE_FILES}/web/frontend" "${STAGE_FILES}/config" \
         "${STAGE_FILES}/scripts"      "${STAGE_FILES}/systemd"

# App files
cp -r "${REPO_ROOT}/web/backend"        "${STAGE_FILES}/web/backend"
cp -r "${REPO_ROOT}/web/frontend/dist"  "${STAGE_FILES}/web/frontend/dist"
cp -r "${REPO_ROOT}/config/."           "${STAGE_FILES}/config/"
cp -r "${REPO_ROOT}/scripts/."          "${STAGE_FILES}/scripts/"
cp -r "${REPO_ROOT}/packaging/systemd/." "${STAGE_FILES}/systemd/"

# Stage definition scripts
cp "${REPO_ROOT}/packaging/pi-gen/stage-goesberry/00-packages" \
   "${PIGEN_DIR}/stage-goesberry/00-packages"
cp "${REPO_ROOT}/packaging/pi-gen/stage-goesberry/01-goesberry/00-run.sh" \
   "${STAGE_DIR}/00-run.sh"
cp "${REPO_ROOT}/packaging/pi-gen/stage-goesberry/01-goesberry/00-run-chroot.sh" \
   "${STAGE_DIR}/00-run-chroot.sh"

# pi-gen config
cp "${REPO_ROOT}/packaging/pi-gen/config" "${PIGEN_DIR}/config"
ok "Stage-goesberry ready"

# ── Run pi-gen Docker build ───────────────────────────────────────────────
log "Running pi-gen Docker build (this takes 30–90 minutes)..."
cd "$PIGEN_DIR"
sudo bash build-docker.sh

# ── Compress & checksum ───────────────────────────────────────────────────
IMAGE=$(find "${PIGEN_DIR}/deploy" -name "*.img" | head -1)
if [[ -z "$IMAGE" ]]; then
  die "No .img found in ${PIGEN_DIR}/deploy — build may have failed."
fi

log "Compressing image with xz (this may take a few minutes)..."
xz --threads=0 --best "$IMAGE"
sha256sum "${IMAGE}.xz" > "${IMAGE}.xz.sha256"

# ── Copy to repo deploy/ dir ──────────────────────────────────────────────
mkdir -p "$DEPLOY_DIR"
cp "${IMAGE}.xz"        "$DEPLOY_DIR/"
cp "${IMAGE}.xz.sha256" "$DEPLOY_DIR/"

ok "Image build complete!"
echo ""
echo "  Image    : ${DEPLOY_DIR}/$(basename "${IMAGE}.xz")"
echo "  Checksum : ${DEPLOY_DIR}/$(basename "${IMAGE}.xz.sha256")"
echo ""
echo "Flash with Raspberry Pi Imager, then edit /boot/goesberry.conf"
