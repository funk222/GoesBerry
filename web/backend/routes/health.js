'use strict';

const express      = require('express');
const router       = express.Router();
const fs           = require('fs');
const { execSync } = require('child_process');

const HEALTH_JSON = process.env.HEALTH_JSON || '/run/goesberry/health.json';

function readTemperature() {
  try {
    const raw = fs.readFileSync('/sys/class/thermal/thermal_zone0/temp', 'utf8');
    return (parseInt(raw.trim(), 10) / 1000).toFixed(1) + ' °C';
  } catch {
    return null;
  }
}

function readDiskUsage(dirPath) {
  // Restrict to safe path characters to avoid shell injection
  if (!/^[a-zA-Z0-9/_.-]+$/.test(dirPath)) return null;
  try {
    const out = execSync(
      `df -B1 --output=size,used,avail "${dirPath}" 2>/dev/null | tail -1`,
      { encoding: 'utf8', timeout: 3000 }
    ).trim();
    const [total, used, available] = out.split(/\s+/).map(Number);
    if (!Number.isFinite(total)) return null;
    return { total, used, available };
  } catch {
    return null;
  }
}

function serviceStatus(name) {
  // name is hardcoded in caller, no injection risk
  try {
    return execSync(`systemctl is-active ${name} 2>/dev/null`, {
      encoding: 'utf8', timeout: 2000,
    }).trim();
  } catch {
    return 'unknown';
  }
}

router.get('/', (req, res) => {
  const PRODUCTS_DIR = req.app.locals.PRODUCTS_DIR;

  // Merge any persisted health data (written by an external monitor)
  let persisted = {};
  try { persisted = JSON.parse(fs.readFileSync(HEALTH_JSON, 'utf8')); } catch {}

  const services = ['goesrecv', 'goesproc', 'goesberry-web'].reduce((acc, s) => {
    acc[s] = serviceStatus(s);
    return acc;
  }, {});

  // Find the most-recently modified product image
  let lastUpdate = null;
  try {
    const walkLatest = (dir, best = { t: 0, iso: null }) => {
      for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = `${dir}/${e.name}`;
        if (e.isDirectory()) walkLatest(full, best);
        else if (/\.(png|jpg)$/i.test(e.name)) {
          const { mtimeMs } = fs.statSync(full);
          if (mtimeMs > best.t) { best.t = mtimeMs; best.iso = new Date(mtimeMs).toISOString(); }
        }
      }
      return best;
    };
    lastUpdate = walkLatest(PRODUCTS_DIR).iso;
  } catch {}

  res.json({
    ok: true,
    timestamp:   new Date().toISOString(),
    temperature: readTemperature(),
    disk:        readDiskUsage(PRODUCTS_DIR),
    services,
    lastUpdate,
    ...persisted,
  });
});

module.exports = router;
