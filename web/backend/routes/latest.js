'use strict';

const express = require('express');
const router  = express.Router();
const fs      = require('fs');
const path    = require('path');

// Recursively collect image files, recording mtime
function collectImages(dir, results) {
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); }
  catch { return; }
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      collectImages(full, results);
    } else if (/\.(png|jpg)$/i.test(e.name)) {
      try {
        const { mtimeMs, size } = fs.statSync(full);
        results.push({ path: full, mtimeMs, size });
      } catch {}
    }
  }
}

// GET /api/latest?sat=GOES-16&limit=10
router.get('/', (req, res) => {
  const PRODUCTS_DIR = req.app.locals.PRODUCTS_DIR;
  const { sat, limit: limitStr } = req.query;

  if (!sat) return res.status(400).json({ error: 'sat parameter required' });
  // Validate sat to prevent path traversal
  if (!/^[a-zA-Z0-9_-]+$/.test(sat))
    return res.status(400).json({ error: 'invalid sat value' });

  const limit  = Math.min(parseInt(limitStr, 10) || 10, 100);
  const satDir = path.join(PRODUCTS_DIR, sat);

  if (!fs.existsSync(satDir)) return res.json({ satellite: sat, images: [] });

  const all = [];
  collectImages(satDir, all);
  all.sort((a, b) => b.mtimeMs - a.mtimeMs);
  const top = all.slice(0, limit);

  const images = top.map(item => {
    const rel     = path.relative(PRODUCTS_DIR, item.path).replace(/\\/g, '/');
    const parts   = rel.split('/');
    const product = parts.length >= 5 ? parts[4] : parts[parts.length - 1];
    return {
      url:     '/products/' + rel,
      product,
      time:    new Date(item.mtimeMs).toISOString(),
      size:    item.size,
    };
  });

  res.json({ satellite: sat, images });
});

module.exports = router;
