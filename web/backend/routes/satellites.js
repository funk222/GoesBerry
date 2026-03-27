'use strict';

const express = require('express');
const router  = express.Router();
const fs      = require('fs');

// GET /api/satellites
// Scans PRODUCTS_DIR for sub-directories — each represents a satellite.
router.get('/', (req, res) => {
  const dir = req.app.locals.PRODUCTS_DIR;
  try {
    if (!fs.existsSync(dir)) return res.json({ satellites: [] });
    const satellites = fs.readdirSync(dir, { withFileTypes: true })
      .filter(e => e.isDirectory())
      .map(e => e.name)
      .sort();
    res.json({ satellites });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
