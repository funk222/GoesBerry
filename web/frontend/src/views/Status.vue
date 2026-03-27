<template>
  <div>
    <h2>System Status</h2>

    <button @click="load" :disabled="loading">↻ Refresh</button>

    <p v-if="loading"   class="muted" style="margin-top:1rem">Loading…</p>
    <p v-else-if="error" class="error">{{ error }}</p>

    <div v-else-if="health" class="panel">
      <div class="row">
        <span class="label">Timestamp</span>
        <span>{{ fmtTime(health.timestamp) }}</span>
      </div>
      <div class="row">
        <span class="label">CPU Temperature</span>
        <span>{{ health.temperature || '—' }}</span>
      </div>
      <div class="row" v-if="health.disk">
        <span class="label">Disk (products)</span>
        <span>{{ fmtDisk(health.disk) }}</span>
      </div>
      <div class="row">
        <span class="label">Last image received</span>
        <span>{{ health.lastUpdate ? fmtTime(health.lastUpdate) : '—' }}</span>
      </div>

      <h3>Services</h3>
      <div class="row" v-for="(status, name) in health.services" :key="name">
        <span class="label">{{ name }}</span>
        <span :class="status === 'active' ? 'ok' : 'warn'">{{ status }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { api } from '../api/index.js';

const health  = ref(null);
const loading = ref(false);
const error   = ref(null);

let autoRefresh = null;

onMounted(async () => {
  await load();
  // Auto-refresh every 30 seconds
  autoRefresh = setInterval(load, 30_000);
});
onUnmounted(() => clearInterval(autoRefresh));

async function load() {
  loading.value = true;
  error.value   = null;
  try {
    health.value = await api.health();
  } catch (e) {
    error.value = e.message;
  } finally {
    loading.value = false;
  }
}

function fmtTime(iso) {
  return new Date(iso).toLocaleString();
}

function fmtDisk(d) {
  const gb  = (n) => (n / 1e9).toFixed(1) + ' GB';
  const pct = Math.round((d.used / d.total) * 100);
  return `${gb(d.used)} / ${gb(d.total)}  (${pct}% used, ${gb(d.available)} free)`;
}
</script>

<style scoped>
button         { margin-bottom: 1.25rem; }
.panel         { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem; max-width: 640px; }
.row           { display: flex; justify-content: space-between; padding: 0.45rem 0; border-bottom: 1px solid #21262d; font-size: 0.9rem; }
.row:last-child { border-bottom: none; }
.label         { color: #8b949e; }
.ok            { color: #3fb950; font-weight: 600; }
.warn          { color: #f85149; font-weight: 600; }
</style>
