<template>
  <div class="carousel">
    <div class="carousel-header">
      <h2>{{ title }}</h2>
      <div class="carousel-controls">
        <button class="carousel-btn" @click="scroll('left')" aria-label="Scroll left">
          <svg viewBox="0 0 24 24" fill="none"><path d="M15 6L9 12L15 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
        </button>
        <button class="carousel-btn" @click="scroll('right')" aria-label="Scroll right">
          <svg viewBox="0 0 24 24" fill="none"><path d="M9 6L15 12L9 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
        </button>
      </div>
    </div>

    <div class="carousel-track" ref="trackRef">
      <div
        v-for="item in items"
        :key="item.id"
        class="carousel-card"
        :class="`carousel-card-${variant}`"
        @click="openItem(item)"
        role="button"
        tabindex="0"
        @keydown.enter="openItem(item)"
        @keydown.space.prevent="openItem(item)"
      >
        <div class="carousel-card-icon" v-html="item.icon"></div>

        <div class="carousel-card-overlay">
          <div class="carousel-card-title">{{ item.title }}</div>
          <div class="carousel-card-meta">{{ item.meta }}</div>

          <div class="carousel-card-action">
            <svg viewBox="0 0 24 24" fill="none" width="14" height="14">
              <path d="M14 5H19V10M19 5L11 13M14 4H7C5.89543 4 5 4.89543 5 6V18C5 19.1046 5.89543 20 7 20H17C18.1046 20 19 19.1046 19 18V11" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
            Read in new tab
          </div>
        </div>

        <div class="carousel-card-label">{{ item.title }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';

const props = defineProps({
  title: { type: String, default: 'Recent' },
  items: { type: Array, default: () => [] },
  variant: { type: String, default: 'SCHOOL' },
});

const emit = defineEmits(['select']);
const router = useRouter();
const trackRef = ref(null);

function scroll(dir) {
  if (!trackRef.value) return;
  const amount = 320;
  trackRef.value.scrollBy({
    left: dir === 'right' ? amount : -amount,
    behavior: 'smooth',
  });
}

function openItem(item) {
  // Notify parent (optional)
  emit('select', item);

  // Open reader in a new tab
  const resolved = router.resolve({ path: `/read/${item.id}` });
  const url = window.location.origin + window.location.pathname + '#' + resolved.href.split('#').slice(-1)[0];
  window.open(url, '_blank', 'noopener,noreferrer');
}
</script>
