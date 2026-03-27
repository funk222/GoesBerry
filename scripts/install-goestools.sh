#!/usr/bin/env bash
# Build and install goestools (goesrecv + goesproc) from source on Raspberry Pi OS 64-bit.
# Tested: Raspberry Pi OS Bookworm (Debian 12) aarch64.
set -euo pipefail

INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BUILD_DIR="${BUILD_DIR:-/tmp/goestools-build}"
GOESTOOLS_REPO="${GOESTOOLS_REPO:-https://github.com/pietern/goestools.git}"

log() { echo "==> [install-goestools] $*"; }

# ── Build dependencies ────────────────────────────────────────────────────
log "Updating package lists..."
apt-get update -qq

log "Installing build dependencies (this may take a few minutes)..."
apt-get install -y --no-install-recommends \
  git cmake build-essential pkg-config \
  libusb-1.0-0-dev \
  libopencv-dev \
  libnng-dev \
  libprotobuf-dev protobuf-compiler \
  libssl-dev \
  zlib1g-dev \
  gettext-base

# ── rtl-sdr ──────────────────────────────────────────────────────────────
log "Installing rtl-sdr..."
apt-get install -y --no-install-recommends librtlsdr-dev rtl-sdr

# ── Clone ─────────────────────────────────────────────────────────────────
log "Cloning goestools from ${GOESTOOLS_REPO}..."
rm -rf "$BUILD_DIR"
git clone --depth=1 "$GOESTOOLS_REPO" "$BUILD_DIR"

# ── CMake build ───────────────────────────────────────────────────────────
log "Configuring with CMake..."
cmake \
  -S "$BUILD_DIR" \
  -B "${BUILD_DIR}/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"

log "Compiling (using $(nproc) cores — this takes ~30 min on Pi 5)..."
cmake --build "${BUILD_DIR}/build" -j"$(nproc)"

log "Installing to ${INSTALL_PREFIX}/bin/..."
cmake --install "${BUILD_DIR}/build"

# ── Verify ────────────────────────────────────────────────────────────────
log "Installed binaries:"
ls -lh "${INSTALL_PREFIX}/bin/goesrecv" "${INSTALL_PREFIX}/bin/goesproc"

# ── Clean up ──────────────────────────────────────────────────────────────
log "Removing build directory..."
rm -rf "$BUILD_DIR"

log "goestools installation complete."
