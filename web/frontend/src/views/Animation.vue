<template>
  <div>
    <h2>Animation (GIF)</h2>

    <div class="controls">
      <select v-model="sat">
        <option value="">— satellite —</option>
        <option v-for="s in satellites" :key="s" :value="s">{{ s }}</option>
      </select>
      <input type="text" v-model="product" placeholder="product (e.g. FD_CH13)" />
      <select v-model="win">
        <option value="1h">1 hour</option>
        <option value="3h">3 hours</option>
        <option value="6h">6 hours</option>
        <option value="12h">12 hours</option>
        <option value="24h">24 hours</option>
      </select>
      <button class="primary" @click="generate" :disabled="!sat || !product || busy">
        {{ busy ? 'Generating…' : 'Generate GIF' }}
      </button>
    </div>

    <p v-if="error" class="error">{{ error }}</p>

    <div v-if="gifUrl" class="gif-result">
      <img :src="gifUrl" alt="Animated GIF" />
      <div class="gif-actions">
        <a :href="gifUrl" target="_blank" download>⬇ Download GIF</a>
      </div>
    </div>

    <div v-else-if="jobId && !error" class="job-status">
      <span>Status: <strong>{{ jobStatus }}</strong></span>
      <span v-if="busy" class="spinner">⏳</span>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import { api } from '../api/index.js';

const satellites = ref([]);
const sat        = ref('');
const product    = ref('');
const win        = ref('3h');
const busy       = ref(false);
const error      = ref(null);
const jobId      = ref(null);
const jobStatus  = ref('');
const gifUrl     = ref(null);

let poll = null;

onMounted(async () => {
  try {
    const data = await api.satellites();
    satellites.value = data.satellites || [];
  } catch {}
});

onUnmounted(() => clearInterval(poll));

async function generate() {
  error.value   = null;
  gifUrl.value  = null;
  jobId.value   = null;
  jobStatus.value = '';
  busy.value    = true;
  clearInterval(poll);

  try {
    const res = await api.createGif(sat.value, product.value, win.value, null);
    if (res.status === 'done') {
      gifUrl.value = res.url;
      busy.value   = false;
      return;
    }
    jobId.value    = res.jobId;
    jobStatus.value = res.status;
    startPolling();
  } catch (e) {
    error.value = e.message;
    busy.value  = false;
  }
}

function startPolling() {
  poll = setInterval(async () => {
    try {
      const res = await api.pollGif(jobId.value);
      jobStatus.value = res.status;
      if (res.status === 'done') {
        gifUrl.value = res.url;
        busy.value   = false;
        clearInterval(poll);
      } else if (res.status === 'error') {
        error.value = res.error || 'GIF generation failed';
        busy.value  = false;
        clearInterval(poll);
      }
    } catch (e) {
      error.value = e.message;
      busy.value  = false;
      clearInterval(poll);
    }
  }, 2000);
}
</script>

<style scoped>
.controls   { display: flex; flex-wrap: wrap; gap: 0.75rem; margin-bottom: 1.25rem; align-items: center; }
.gif-result { margin-top: 1rem; }
.gif-result img { max-width: 100%; border: 1px solid #30363d; border-radius: 8px; }
.gif-actions { margin-top: 0.5rem; }
.gif-actions a { color: #58a6ff; text-decoration: none; font-size: 0.9rem; }
.job-status { margin-top: 1rem; color: #8b949e; display: flex; gap: 0.5rem; align-items: center; }
</style>
