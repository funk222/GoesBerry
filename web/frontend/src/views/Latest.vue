<template>
  <div>
    <h2>Latest Images</h2>

    <div class="controls">
      <select v-model="selectedSat" @change="loadImages">
        <option value="">— select satellite —</option>
        <option v-for="s in satellites" :key="s" :value="s">{{ s }}</option>
      </select>
      <button @click="loadImages" :disabled="!selectedSat || loading">↻ Refresh</button>
    </div>

    <p v-if="loading"          class="muted">Loading…</p>
    <p v-else-if="error"       class="error">{{ error }}</p>
    <p v-else-if="!selectedSat" class="muted">Select a satellite above to see its latest images.</p>
    <p v-else-if="!images.length" class="muted">No images found for {{ selectedSat }}.</p>

    <div v-else class="image-grid">
      <div class="image-card" v-for="img in images" :key="img.url">
        <a :href="img.url" target="_blank" rel="noopener">
          <img :src="img.url" :alt="img.product" loading="lazy" />
        </a>
        <div class="image-meta">
          <strong>{{ img.product }}</strong><br />
          <small>{{ fmtTime(img.time) }}</small>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { api } from '../api/index.js';

const satellites  = ref([]);
const selectedSat = ref('');
const images      = ref([]);
const loading     = ref(false);
const error       = ref(null);

onMounted(async () => {
  try {
    const data = await api.satellites();
    satellites.value = data.satellites || [];
    if (satellites.value.length === 1) {
      selectedSat.value = satellites.value[0];
      await loadImages();
    }
  } catch (e) {
    error.value = e.message;
  }
});

async function loadImages() {
  if (!selectedSat.value) return;
  loading.value = true;
  error.value   = null;
  try {
    const data    = await api.latest(selectedSat.value, 20);
    images.value  = data.images || [];
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
.controls { display: flex; gap: 0.75rem; margin-bottom: 1.25rem; align-items: center; }
</style>
