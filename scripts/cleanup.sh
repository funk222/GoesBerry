#!/usr/bin/env bash
# GoesBerry daily cleanup — remove files older than RETENTION_DAYS.
# Invoked by goesberry-cleanup.timer / goesberry-cleanup.service.
set -euo pipefail

RETENTION_DAYS="${RETENTION_DAYS:-14}"
PRODUCTS_DIR="${PRODUCTS_DIR:-/mnt/goesberry/products}"
CACHE_DIR="${CACHE_DIR:-/mnt/goesberry/cache}"

log() { echo "[goesberry-cleanup] $*"; }

log "Starting cleanup (retention = ${RETENTION_DAYS} days)"

if [[ -d "$PRODUCTS_DIR" ]]; then
  # Delete old image files
  COUNT=$(find "$PRODUCTS_DIR" -type f \( -name "*.png" -o -name "*.jpg" \) \
    -mtime "+${RETENTION_DAYS}" -delete -print 2>/dev/null | wc -l)
  log "Deleted ${COUNT} product files older than ${RETENTION_DAYS} days"

  # Prune empty date directories (mindepth 3 = SAT/YYYY/MM/DD)
  find "$PRODUCTS_DIR" -mindepth 3 -maxdepth 4 -type d -empty -delete 2>/dev/null || true
  log "Pruned empty directories under $PRODUCTS_DIR"
else
  log "PRODUCTS_DIR not found: $PRODUCTS_DIR (skipping)"
fi

if [[ -d "$CACHE_DIR" ]]; then
  COUNT=$(find "$CACHE_DIR" -type f -name "*.gif" \
    -mtime "+${RETENTION_DAYS}" -delete -print 2>/dev/null | wc -l)
  log "Deleted ${COUNT} cached GIF files older than ${RETENTION_DAYS} days"
else
  log "CACHE_DIR not found: $CACHE_DIR (skipping)"
fi

log "Cleanup complete."
