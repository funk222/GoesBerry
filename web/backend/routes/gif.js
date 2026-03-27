'use strict';

const express    = require('express');
const router     = express.Router();
const fs         = require('fs');
const path       = require('path');
const crypto     = require('crypto');
const { execFile } = require('child_process');

// In-memory job store (survives for the lifetime of the process)
const JOBS = new Map(); // jobId → { status, url?, error? }
let activeJobs = 0;
const MAX_CONCURRENT = 2;

function parseWindow(w) {
  const m = /^(\d+)(h|m)$/.exec(w);
  if (!m) return null;
  return parseInt(m[1], 10) * (m[2] === 'h' ? 3_600_000 : 60_000);
}

function makeJobId(sat, product, win, endHour) {
  return crypto.createHash('md5').update(`${sat}|${product}|${win}|${endHour}`).digest('hex');
}

// Collect matching images within [start, end]
function collectImages(dir, product, startMs, endMs, out) {
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      collectImages(full, product, startMs, endMs, out);
    } else if (/\.(png|jpg)$/i.test(e.name)) {
      if (product && !e.name.includes(product)) continue;
      try {
        const { mtimeMs } = fs.statSync(full);
        if (mtimeMs >= startMs && mtimeMs <= endMs) out.push({ path: full, mtimeMs });
      } catch {}
    }
  }
}

async function buildGif({ jobId, satDir, product, startMs, endMs, outFile }) {
  activeJobs++;
  JOBS.set(jobId, { status: 'running' });
  try {
    const imgs = [];
    collectImages(satDir, product, startMs, endMs, imgs);
    imgs.sort((a, b) => a.mtimeMs - b.mtimeMs);
    if (imgs.length === 0) throw new Error('No images found in the specified time window');

    fs.mkdirSync(path.dirname(outFile), { recursive: true });

    // Use ImageMagick convert (must be installed on Pi)
    await new Promise((resolve, reject) => {
      execFile('convert', ['-delay', '20', '-loop', '0', ...imgs.map(i => i.path), outFile],
        { timeout: 120_000 },
        (err) => err ? reject(err) : resolve());
    });

    JOBS.set(jobId, { status: 'done', url: `/cache/${path.basename(outFile)}` });
  } catch (err) {
    JOBS.set(jobId, { status: 'error', error: err.message });
  } finally {
    activeJobs--;
  }
}

// POST /api/gif   { sat, product, window: "1h"|"3h"|"6h"|"12h"|"24h", endTime? }
router.post('/', (req, res) => {
  const PRODUCTS_DIR = req.app.locals.PRODUCTS_DIR;
  const CACHE_DIR    = req.app.locals.CACHE_DIR;
  const { sat, product, window: win, endTime } = req.body;

  if (!sat || !product || !win)
    return res.status(400).json({ error: 'sat, product and window are required' });
  if (!/^[a-zA-Z0-9_-]+$/.test(sat))
    return res.status(400).json({ error: 'invalid sat' });
  if (!/^[a-zA-Z0-9_.-]+$/.test(product))
    return res.status(400).json({ error: 'invalid product' });

  const windowMs = parseWindow(win);
  if (!windowMs) return res.status(400).json({ error: 'invalid window (use e.g. 1h, 3h, 6h)' });

  const end      = endTime ? new Date(endTime) : new Date();
  const endHour  = end.toISOString().slice(0, 13); // bucket by hour for cache key
  const jobId    = makeJobId(sat, product, win, endHour);
  const outFile  = path.join(CACHE_DIR, `${jobId}.gif`);

  if (fs.existsSync(outFile))
    return res.json({ jobId, status: 'done', url: `/cache/${jobId}.gif` });

  if (JOBS.has(jobId)) {
    const job = JOBS.get(jobId);
    return res.json({ jobId, status: job.status, url: job.url || null, pollUrl: `/api/gif/${jobId}` });
  }

  if (activeJobs >= MAX_CONCURRENT)
    return res.status(429).json({ error: 'Too many concurrent GIF jobs. Please try again shortly.' });

  const satDir   = path.join(PRODUCTS_DIR, sat);
  const startMs  = end.getTime() - windowMs;
  const endMs    = end.getTime();

  JOBS.set(jobId, { status: 'pending' });
  buildGif({ jobId, satDir, product, startMs, endMs, outFile });

  res.json({ jobId, status: 'pending', pollUrl: `/api/gif/${jobId}` });
});

// GET /api/gif/:jobId
router.get('/:jobId', (req, res) => {
  const CACHE_DIR = req.app.locals.CACHE_DIR;
  const { jobId }  = req.params;

  if (!/^[a-f0-9]{32}$/.test(jobId))
    return res.status(400).json({ error: 'invalid jobId' });

  const outFile = path.join(CACHE_DIR, `${jobId}.gif`);
  if (fs.existsSync(outFile))
    return res.json({ jobId, status: 'done', url: `/cache/${jobId}.gif` });

  if (!JOBS.has(jobId))
    return res.status(404).json({ error: 'Job not found' });

  const job = JOBS.get(jobId);
  res.json({ jobId, status: job.status, url: job.url || null, error: job.error || null });
});

module.exports = router;
