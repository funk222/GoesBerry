'use strict';

const express = require('express');
const router  = express.Router();
const fs      = require('fs');
const path    = require('path');

// GET /api/history?sat=GOES-16&date=2026-03-27&product=FD_CH13
router.get('/', (req, res) => {
  const PRODUCTS_DIR = req.app.locals.PRODUCTS_DIR;
  const { sat, date, product } = req.query;

  if (!sat) return res.status(400).json({ error: 'sat required' });
  if (!/^[a-zA-Z0-9_-]+$/.test(sat))
    return res.status(400).json({ error: 'invalid sat value' });
  if (date && !/^\d{4}-\d{2}-\d{2}$/.test(date))
    return res.status(400).json({ error: 'invalid date (expected YYYY-MM-DD)' });
  if (product && !/^[a-zA-Z0-9_.-]+$/.test(product))
    return res.status(400).json({ error: 'invalid product value' });

  // Build search root: PRODUCTS_DIR/SAT[/YYYY/MM/DD][/product]
  let searchDir = path.join(PRODUCTS_DIR, sat);
  if (date) searchDir = path.join(searchDir, date.replace(/-/g, '/'));
  if (product) searchDir = path.join(searchDir, product);

  if (!fs.existsSync(searchDir)) return res.json({ satellite: sat, date, product, images: [] });

  const images = [];
  const walk = (dir) => {
    let entries;
    try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
    for (const e of entries) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) {
        walk(full);
      } else if (/\.(png|jpg)$/i.test(e.name)) {
        try {
          const { mtimeMs, size } = fs.statSync(full);
          const rel = path.relative(PRODUCTS_DIR, full).replace(/\\/g, '/');
          images.push({ url: '/products/' + rel, name: e.name, time: new Date(mtimeMs).toISOString(), size });
        } catch {}
      }
    }
  };
  walk(searchDir);
  images.sort((a, b) => b.time.localeCompare(a.time));

  res.json({ satellite: sat, date: date || null, product: product || null, images: images.slice(0, 200) });
});

module.exports = router;
