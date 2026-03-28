#!/bin/bash -e
# GoesBerry pi-gen stage: chroot configuration.
# Runs INSIDE the ARM64 chroot via systemd-nspawn.

# ── Enable GoesBerry systemd services ─────────────────────────────────────
# goesrecv/goesproc are NOT enabled here; they are started by
# goesberry-install-tools.service after goestools is compiled on first boot.
systemctl enable goesberry-firstboot.service
systemctl enable goesberry-install-tools.service
systemctl enable goesberry-web.service
systemctl enable goesberry-cleanup.timer

# ── Add 'pi' user to plugdev so RTL-SDR is accessible without root ─────────
usermod -aG plugdev pi 2>/dev/null || true

# ── Set hostname ───────────────────────────────────────────────────────────
echo "goesberry" > /etc/hostname
sed -i 's/127\.0\.1\.1\s.*/127.0.1.1\tgoesberry/' /etc/hosts 2>/dev/null || \
  echo "127.0.1.1	goesberry" >> /etc/hosts

# ── /etc/motd ─────────────────────────────────────────────────────────────
cat > /etc/motd <<'MOTD'

  ╔══════════════════════════════════════════════════╗
  ║   🛰  GoesBerry – GOES HRIT/GRB on Raspberry Pi  ║
  ║   Web UI : http://<this-ip>:8080                 ║
  ║   Logs   : journalctl -fu goesrecv               ║
  ╚══════════════════════════════════════════════════╝
  First boot: goestools is being compiled (~30 min).
  Follow progress: journalctl -fu goesberry-install-tools

MOTD

# ── Disable swap (extend SD/SSD lifespan) ─────────────────────────────────
systemctl disable dphys-swapfile 2>/dev/null || true
