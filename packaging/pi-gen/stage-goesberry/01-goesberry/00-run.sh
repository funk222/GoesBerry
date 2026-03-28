#!/bin/bash -e
# GoesBerry pi-gen stage: copy app files into rootfs (runs on BUILD HOST).
# pi-gen sets $ROOTFS_DIR to the chroot root being assembled.
# PWD when this script runs = stage-goesberry/01-goesberry/
#
# The CI workflow (or build-image.sh) must populate ./files/ before running pi-gen:
#   files/web/backend/      – Node backend (with node_modules pre-installed)
#   files/web/frontend/dist – Built Vue3 frontend
#   files/config/           – Config templates
#   files/scripts/          – Shell scripts
#   files/systemd/          – systemd units

GBFILES="$(pwd)/files"

# ── /opt/goesberry ────────────────────────────────────────────────────────
install -d "${ROOTFS_DIR}/opt/goesberry/web/frontend"
cp -r "${GBFILES}/web/backend"        "${ROOTFS_DIR}/opt/goesberry/web/"
cp -r "${GBFILES}/web/frontend/dist"  "${ROOTFS_DIR}/opt/goesberry/web/frontend/"
cp -r "${GBFILES}/config"             "${ROOTFS_DIR}/opt/goesberry/"

# ── /usr/local/bin helper scripts ─────────────────────────────────────────
install -m 755 "${GBFILES}/scripts/firstboot.sh"         "${ROOTFS_DIR}/usr/local/bin/goesberry-firstboot.sh"
install -m 755 "${GBFILES}/scripts/cleanup.sh"           "${ROOTFS_DIR}/usr/local/bin/goesberry-cleanup.sh"
install -m 755 "${GBFILES}/scripts/install-goestools.sh" "${ROOTFS_DIR}/usr/local/bin/goesberry-install-goestools.sh"

# ── systemd units ─────────────────────────────────────────────────────────
install -d "${ROOTFS_DIR}/etc/systemd/system"
for f in "${GBFILES}/systemd/"*.service "${GBFILES}/systemd/"*.timer; do
  [[ -e "$f" ]] || continue
  install -m 644 "$f" "${ROOTFS_DIR}/etc/systemd/system/"
done

# ── /boot/goesberry.conf (editable on FAT32 partition from any OS) ────────
install -m 644 "${GBFILES}/config/goesberry.conf.template" "${ROOTFS_DIR}/boot/goesberry.conf"

# ── RTL-SDR udev rule (non-root access) ──────────────────────────────────
install -d "${ROOTFS_DIR}/etc/udev/rules.d"
cat > "${ROOTFS_DIR}/etc/udev/rules.d/20-rtlsdr.rules" <<'EOF'
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", GROUP="plugdev", MODE="0664"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", GROUP="plugdev", MODE="0664"
EOF

# ── DVB kernel module blacklist (prevents DVB driver grabbing RTL-SDR) ────
install -d "${ROOTFS_DIR}/etc/modprobe.d"
cat > "${ROOTFS_DIR}/etc/modprobe.d/blacklist-dvb.conf" <<'EOF'
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
EOF
