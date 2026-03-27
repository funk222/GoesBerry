<template>
  <div id="goesberry-app">
    <nav class="nav">
      <span class="nav-brand">🛰 GoesBerry</span>
      <div class="nav-links">
        <router-link to="/latest">Latest</router-link>
        <router-link to="/history">History</router-link>
        <router-link to="/animation">Animation</router-link>
        <router-link to="/status">Status</router-link>
      </div>
    </nav>
    <main class="main">
      <router-view />
    </main>
    <footer class="footer">GoesBerry &mdash; GOES HRIT/GRB receiver on Raspberry Pi 5</footer>
  </div>
</template>

<style>
/* ── Reset ───────────────────────────────────────────── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body   { font-family: system-ui, -apple-system, sans-serif; background: #0d1117; color: #c9d1d9; }

/* ── Layout ─────────────────────────────────────────── */
#goesberry-app { display: flex; flex-direction: column; min-height: 100vh; }
.nav           { display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 1.5rem; background: #161b22; border-bottom: 1px solid #30363d; }
.nav-brand     { font-size: 1.15rem; font-weight: 700; color: #58a6ff; }
.nav-links     { display: flex; gap: 1.5rem; }
.nav-links a   { color: #8b949e; text-decoration: none; font-size: 0.9rem; }
.nav-links a.router-link-active { color: #58a6ff; border-bottom: 2px solid #58a6ff; }
.main          { flex: 1; padding: 1.5rem 2rem; max-width: 1200px; width: 100%; margin: 0 auto; }
.footer        { text-align: center; padding: 0.75rem; font-size: 0.8rem; color: #484f58; border-top: 1px solid #21262d; }

/* ── Shared utilities ────────────────────────────────── */
h2             { font-size: 1.25rem; color: #e6edf3; margin-bottom: 1rem; }
h3             { font-size: 1rem;   color: #e6edf3; margin: 1rem 0 0.5rem; }
select, input  { background: #21262d; border: 1px solid #30363d; color: #c9d1d9; border-radius: 6px; padding: 0.4rem 0.75rem; font-size: 0.9rem; }
button         { background: #21262d; border: 1px solid #30363d; color: #c9d1d9; border-radius: 6px; padding: 0.4rem 1rem; font-size: 0.9rem; cursor: pointer; }
button:hover   { background: #30363d; }
button.primary { background: #1f6feb; border-color: #1f6feb; color: #fff; }
button.primary:hover { background: #388bfd; }
button:disabled { opacity: 0.5; cursor: not-allowed; }
.error         { color: #f85149; font-size: 0.9rem; margin-top: 0.5rem; }
.muted         { color: #8b949e; font-style: italic; }
.image-grid    { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 1rem; }
.image-card    { background: #161b22; border: 1px solid #30363d; border-radius: 8px; overflow: hidden; }
.image-card img { width: 100%; height: 160px; object-fit: cover; display: block; }
.image-meta    { padding: 0.5rem; font-size: 0.78rem; color: #8b949e; word-break: break-word; }
</style>
