<template>
  <div>
    <h2>History</h2>

    <div class="controls">
      <select v-model="sat">
        <option value="">— satellite —</option>
        <option v-for="s in satellites" :key="s" :value="s">{{ s }}</option>
      </select>
      <input type="date" v-model="date" :max="today" />
      <input type="text" v-model="product" placeholder="product filter (optional, e.g. FD_CH13)" />
      <button class="primary" @click="search" :disabled="!sat || loading">Search</button>
    </div>

    <p v-if="loading"          class="muted">Loading…</p>
    <p v-else-if="error"       class="error">{{ error }}</p>
    <p v-else-if="searched && !images.length" class="muted">No images found.</p>

    <div v-else class="image-grid">
      <div class="image-card" v-for="img in images" :key="img.url">
        <a :href="img.url" target="_blank" rel="noopener">
          <img :src="img.url" :alt="img.name" loading="lazy" />
        </a>
        <div class="image-meta">
          {{ img.name }}<br />
          <small>{{ fmtTime(img.time) }}</small>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { api } from '../api/index.js';

const today      = new Date().toISOString().slice(0, 10);
const satellites = ref([]);
const sat        = ref('');
const date       = ref(today);
const product    = ref('');
const images     = ref([]);
const loading    = ref(false);
const error      = ref(null);
const searched   = ref(false);

onMounted(async () => {
  try {
    const data = await api.satellites();
    satellites.value = data.satellites || [];
  } catch {}
});

async function search() {
  if (!sat.value) return;
  loading.value = true;
  error.value   = null;
  searched.value = false;
  try {
    const data    = await api.history(sat.value, date.value || undefined, product.value || undefined);
    images.value  = data.images || [];
    searched.value = true;
  } catch (e) {
    error.value = e.message;
  } finally {
    loading.value = false;
  }
}

function fmtTime(iso) {
  return new Date(iso).toLocaleString();
}
</script>

<style scoped>
.controls { display: flex; flex-wrap: wrap; gap: 0.75rem; margin-bottom: 1.25rem; align-items: center; }
input[type="text"] { min-width: 240px; }
</style>
