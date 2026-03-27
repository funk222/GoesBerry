'use strict';

const express = require('express');
const cors    = require('cors');
const path    = require('path');
const fs      = require('fs');

const app = express();
app.use(cors());
app.use(express.json());

const PORT        = process.env.WEB_PORT     || 8080;
const PRODUCTS_DIR = process.env.PRODUCTS_DIR || '/mnt/goesberry/products';
const CACHE_DIR    = process.env.CACHE_DIR    || '/mnt/goesberry/cache';

// Expose dirs to route handlers via app.locals
app.locals.PRODUCTS_DIR = PRODUCTS_DIR;
app.locals.CACHE_DIR    = CACHE_DIR;

// ── Static file serving ──────────────────────────────────────────────────
app.use('/products', express.static(PRODUCTS_DIR));
app.use('/cache',    express.static(CACHE_DIR));

// ── API routes ───────────────────────────────────────────────────────────
app.use('/api/health',     require('./routes/health'));
app.use('/api/satellites', require('./routes/satellites'));
app.use('/api/latest',     require('./routes/latest'));
app.use('/api/history',    require('./routes/history'));
app.use('/api/gif',        require('./routes/gif'));

// ── Serve Vue3 frontend build (production) ───────────────────────────────
const frontendDist = path.join(__dirname, '..', 'frontend', 'dist');
if (fs.existsSync(frontendDist)) {
  app.use(express.static(frontendDist));
  app.get('*', (_req, res) =>
    res.sendFile(path.join(frontendDist, 'index.html')));
}

app.listen(PORT, () => {
  console.log(`GoesBerry backend listening on :${PORT}`);
  console.log(`  PRODUCTS_DIR : ${PRODUCTS_DIR}`);
  console.log(`  CACHE_DIR    : ${CACHE_DIR}`);
});
