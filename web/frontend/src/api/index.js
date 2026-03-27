// Thin wrapper around fetch for all GoesBerry API calls.
const BASE = '/api';

async function get(path) {
  const res = await fetch(BASE + path);
  if (!res.ok) {
    const msg = await res.text().catch(() => res.statusText);
    throw new Error(msg || `HTTP ${res.status}`);
  }
  return res.json();
}

async function post(path, body) {
  const res = await fetch(BASE + path, {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify(body),
  });
  if (!res.ok) {
    const msg = await res.text().catch(() => res.statusText);
    throw new Error(msg || `HTTP ${res.status}`);
  }
  return res.json();
}

export const api = {
  health:     ()                             => get('/health'),
  satellites: ()                             => get('/satellites'),
  latest:     (sat, limit = 10)             => get(`/latest?sat=${encodeURIComponent(sat)}&limit=${limit}`),
  history:    (sat, date, product) => {
    let url = `/history?sat=${encodeURIComponent(sat)}`;
    if (date)    url += `&date=${encodeURIComponent(date)}`;
    if (product) url += `&product=${encodeURIComponent(product)}`;
    return get(url);
  },
  createGif: (sat, product, window, endTime) =>
    post('/gif', { sat, product, window, endTime: endTime || null }),
  pollGif: (jobId) => get(`/gif/${encodeURIComponent(jobId)}`),
};
