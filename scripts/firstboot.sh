#!/usr/bin/env bash
# GoesBerry first-boot setup script
# Reads /boot/goesberry.conf, generates /etc/goesberry/* and creates data dirs.
# Idempotent: controlled by ConditionPathExists=!/etc/goesberry/.configured
set -euo pipefail

CONF_FILE="/boot/goesberry.conf"
ETC_DIR="/etc/goesberry"
RUNTIME_ENV="${ETC_DIR}/runtime.env"
GOESRECV_CONF="${ETC_DIR}/goesrecv.conf"
GOESPROC_CONF="${ETC_DIR}/goesproc.conf"
MARKER="${ETC_DIR}/.configured"
TEMPLATE_DIR="/opt/goesberry/config"

log() { echo "[goesberry-firstboot] $*" | tee -a /var/log/goesberry-firstboot.log >&2; }

# ── Guard ─────────────────────────────────────────────────────────────────
if [[ ! -f "$CONF_FILE" ]]; then
  log "ERROR: $CONF_FILE not found. Create it on the /boot partition and reboot."
  exit 1
fi

mkdir -p "$ETC_DIR"

# ── Load user config ──────────────────────────────────────────────────────
set -a
# shellcheck disable=SC1091
source /boot/goesberry.conf
set +a

# ── Apply defaults ────────────────────────────────────────────────────────
CENTER_FREQUENCY_HZ="${CENTER_FREQUENCY_HZ:-1694100000}"
SAMPLE_RATE="${SAMPLE_RATE:-2400000}"
RTL_PPM="${RTL_PPM:-0}"
RTL_GAIN="${RTL_GAIN:-}"          # empty → AGC
DATA_ROOT="${DATA_ROOT:-/mnt/goesberry}"
WEB_PORT="${WEB_PORT:-8080}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

PRODUCTS_DIR="${DATA_ROOT}/products"
RAW_DIR="${DATA_ROOT}/raw"
CACHE_DIR="${DATA_ROOT}/cache"
LOG_DIR="${DATA_ROOT}/log"
HEALTH_JSON="/run/goesberry/health.json"

# ── Create data directories ───────────────────────────────────────────────
for d in "$PRODUCTS_DIR" "$RAW_DIR" "$CACHE_DIR" "$LOG_DIR"; do
  mkdir -p "$d"
  log "Created $d"
done
mkdir -p /run/goesberry

# ── Write runtime.env (sourced by all systemd units) ──────────────────────
cat > "$RUNTIME_ENV" <<EOF
DATA_ROOT=${DATA_ROOT}
PRODUCTS_DIR=${PRODUCTS_DIR}
RAW_DIR=${RAW_DIR}
CACHE_DIR=${CACHE_DIR}
LOG_DIR=${LOG_DIR}
WEB_PORT=${WEB_PORT}
RETENTION_DAYS=${RETENTION_DAYS}
HEALTH_JSON=${HEALTH_JSON}
EOF
log "Wrote $RUNTIME_ENV"

# ── Generate goesrecv.conf ────────────────────────────────────────────────
if [[ -f "${TEMPLATE_DIR}/goesrecv.conf.template" ]]; then
  # When gain is empty, remove the "gain = " line entirely so RTL-SDR uses AGC
  GAIN_LINE=""
  [[ -n "$RTL_GAIN" ]] && GAIN_LINE="gain = ${RTL_GAIN}"
  CENTER_FREQUENCY_HZ="$CENTER_FREQUENCY_HZ" \
  SAMPLE_RATE="$SAMPLE_RATE" \
  RTL_GAIN="$RTL_GAIN" \
  RTL_PPM="$RTL_PPM" \
    envsubst < "${TEMPLATE_DIR}/goesrecv.conf.template" \
    | sed '/^gain = $/d' \
    > "$GOESRECV_CONF"
else
  # Inline fallback
  GAIN_LINE="# gain not set — RTL-SDR will use AGC"
  [[ -n "$RTL_GAIN" ]] && GAIN_LINE="gain = ${RTL_GAIN}"
  cat > "$GOESRECV_CONF" <<EOF
[demodulator]
mode = "hrit"

[rtlsdr]
frequency = ${CENTER_FREQUENCY_HZ}
sample_rate = ${SAMPLE_RATE}
${GAIN_LINE}
ppm = ${RTL_PPM}
bias = false

[monitor]
bind = "0.0.0.0:5004"

[packet_publisher]
bind = "0.0.0.0:5005"
EOF
fi
log "Wrote $GOESRECV_CONF"

# ── Generate goesproc.conf ────────────────────────────────────────────────
if [[ -f "${TEMPLATE_DIR}/goesproc.conf.template" ]]; then
  PRODUCTS_DIR="$PRODUCTS_DIR" envsubst < "${TEMPLATE_DIR}/goesproc.conf.template" > "$GOESPROC_CONF"
else
  cat > "$GOESPROC_CONF" <<EOF
[[handler]]
type = "image"
origin = "GOES-16"
region = { type = "full_disk" }
channel = { name = "CH13" }
directory = "${PRODUCTS_DIR}/GOES-16/{time:%Y/%m/%d}"
filename = "GOES16_FD_CH13_{time:%Y%m%dT%H%M%SZ}"
format = "png"

[[handler]]
type = "image"
origin = "GOES-18"
region = { type = "full_disk" }
channel = { name = "CH13" }
directory = "${PRODUCTS_DIR}/GOES-18/{time:%Y/%m/%d}"
filename = "GOES18_FD_CH13_{time:%Y%m%dT%H%M%SZ}"
format = "png"
EOF
fi
log "Wrote $GOESPROC_CONF"

# ── udev rule for RTL-SDR (non-root access) ───────────────────────────────
UDEV_RULE="/etc/udev/rules.d/20-rtlsdr.rules"
if [[ ! -f "$UDEV_RULE" ]]; then
  cat > "$UDEV_RULE" <<'EOF'
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", GROUP="plugdev", MODE="0664"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", GROUP="plugdev", MODE="0664"
EOF
  udevadm control --reload-rules 2>/dev/null || true
  log "Installed udev rule $UDEV_RULE"
fi

# ── Blacklist DVB kernel modules that grab the RTL-SDR device ────────────
BL="/etc/modprobe.d/blacklist-dvb.conf"
if [[ ! -f "$BL" ]]; then
  cat > "$BL" <<'EOF'
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
EOF
  log "DVB modules blacklisted ($BL)"
fi

# ── Mark configured (prevents re-run on next boot) ────────────────────────
touch "$MARKER"
log "First-boot setup complete — marker written to $MARKER"
