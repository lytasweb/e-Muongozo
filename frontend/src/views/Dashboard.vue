<template>
  <AppShell :variant="variant" page-title="Dashboard">
    <!-- Stat cards -->
    <div class="grid grid-3" style="margin-bottom:24px">
      <div class="stat-card">
        <div class="stat-icon">
          <svg viewBox="0 0 24 24" fill="none">
            <path d="M4 5C4 3.89543 4.89543 3 6 3H18C19.1046 3 20 3.89543 20 5V19C20 20.1046 19.1046 21 18 21H6C4.89543 21 4 20.1046 4 19V5Z" stroke="currentColor" stroke-width="1.5"/>
            <path d="M8 3V21M12 8H16M12 12H16" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
          </svg>
        </div>
        <div class="stat-label">Total Content</div>
        <div class="stat-value">{{ counts.total }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon-success">
          <svg viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.5"/>
            <path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
        <div class="stat-label">Approved</div>
        <div class="stat-value">{{ counts.approved }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-icon stat-icon-warning">
          <svg viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.5"/>
            <path d="M12 7V12L15 15" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
          </svg>
        </div>
        <div class="stat-label">Pending Review</div>
        <div class="stat-value">{{ counts.pending }}</div>
      </div>
    </div>

    <!-- Carousel -->
    <DashboardCarousel
      title="Recent Content"
      :items="carouselItems"
      :variant="variant"
    />

    <div v-if="items.length === 0" class="empty-state" style="margin-top:24px">
      <div class="empty-icon">
        <svg viewBox="0 0 24 24" fill="none" width="48" height="48">
          <path d="M3 7C3 5.89543 3.89543 5 5 5H9L11 7H19C20.1046 7 21 7.89543 21 9V19C21 20.1046 20.1046 21 19 21H5C3.89543 21 3 20.1046 3 19V7Z" stroke="currentColor" stroke-width="1.2"/>
        </svg>
      </div>
      <p>No content yet. Click <strong>Upload Content</strong> to add your first guide.</p>
    </div>
  </AppShell>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import api from '../api.js';
import AppShell from '../components/AppShell.vue';
import DashboardCarousel from '../components/DashboardCarousel.vue';

const user = JSON.parse(localStorage.getItem('user') || '{}');
const variant = computed(() => user.role || 'SCHOOL');
const items = ref([]);

const counts = computed(() => ({
  total: items.value.length,
  approved: items.value.filter((i) => i.status === 'approved').length,
  pending: items.value.filter((i) => i.status === 'pending').length,
}));

const subjectIcons = {
  Physics: `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="2.5" stroke="currentColor" stroke-width="1.5"/><ellipse cx="12" cy="12" rx="9" ry="4" stroke="currentColor" stroke-width="1.5"/><ellipse cx="12" cy="12" rx="9" ry="4" transform="rotate(60 12 12)" stroke="currentColor" stroke-width="1.5"/><ellipse cx="12" cy="12" rx="9" ry="4" transform="rotate(120 12 12)" stroke="currentColor" stroke-width="1.5"/></svg>`,
  Mathematics: `<svg viewBox="0 0 24 24" fill="none"><path d="M5 8H11M8 5V11" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M14 8H19" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="8" cy="17" r="3" stroke="currentColor" stroke-width="1.5"/><path d="M14 17H19" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>`,
  Chemistry: `<svg viewBox="0 0 24 24" fill="none"><path d="M10 3H14V8L19 19C19.5 20.5 18 21 17 21H7C6 21 4.5 20.5 5 19L10 8V3Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/><path d="M8 15H16" stroke="currentColor" stroke-width="1.5"/></svg>`,
  Biology: `<svg viewBox="0 0 24 24" fill="none"><path d="M12 3C8 3 6 6 6 9C6 13 9 15 12 21C15 15 18 13 18 9C18 6 16 3 12 3Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/><path d="M12 3V13" stroke="currentColor" stroke-width="1.5"/></svg>`,
  default: `<svg viewBox="0 0 24 24" fill="none"><path d="M4 5C4 3.89543 4.89543 3 6 3H18C19.1046 3 20 3.89543 20 5V19C20 20.1046 19.1046 21 18 21H6C4.89543 21 4 20.1046 4 19V5Z" stroke="currentColor" stroke-width="1.5"/></svg>`,
};

const carouselItems = computed(() =>
  items.value.slice(0, 12).map((i) => ({
    id: i.id,
    title: i.title,
    meta: `${i.subject} · ${i.level}`,
    icon: subjectIcons[i.subject] || subjectIcons.default,
  }))
);

onMounted(async () => {
  try {
    const { data } = await api.get('/content');
    items.value = data;
  } catch {}
});
</script>
