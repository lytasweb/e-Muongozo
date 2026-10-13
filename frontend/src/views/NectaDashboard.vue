<template>
<AppShell :variant="variant" page-title="NECTA Dashboard">
      <!-- HERO -->
    <div class="entity-hero entity-hero-necta">
      <div class="entity-hero-left">
        <div class="entity-hero-logo">
          <img :src="logoNecta" alt="NECTA" />
        </div>
        <div>
          <div class="entity-hero-eyebrow">National Examinations Council of Tanzania</div>
          <h1 class="entity-hero-title">Welcome, NECTA</h1>
          <p class="entity-hero-sub">Exam diagnostics, SIRA reports, and answering scheme standards.</p>
        </div>
      </div>
      <div class="entity-hero-right">
        <div class="entity-hero-badge">NECTA OFFICIAL</div>
      </div>
    </div>

    <!-- STAT CARDS -->
    <div class="grid grid-3" style="margin-bottom:24px">
      <div class="stat-card">
        <div class="stat-icon stat-icon-necta">
          <svg viewBox="0 0 24 24" fill="none">
            <path d="M6 2H18C19.1046 2 20 2.89543 20 4V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.5"/>
            <path d="M8 7H16M8 11H16M8 15H13" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
          </svg>
        </div>
        <div class="stat-label">Reports Published</div>
        <div class="stat-value">{{ counts.total }}</div>
        <div class="stat-sub">SIRA, CIRA, and answering schemes</div>
      </div>

      <div class="stat-card">
        <div class="stat-icon stat-icon-success">
          <svg viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.5"/>
            <path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
        <div class="stat-label">Active Reports</div>
        <div class="stat-value">{{ counts.approved }}</div>
        <div class="stat-sub">Currently visible to students</div>
      </div>

      <div class="stat-card">
        <div class="stat-icon stat-icon-warning">
          <svg viewBox="0 0 24 24" fill="none">
            <path d="M12 4L3 19H21L12 4Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
            <path d="M12 10V14M12 17H12.01" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
          </svg>
        </div>
        <div class="stat-label">Failure Points</div>
        <div class="stat-value">{{ counts.pending }}</div>
        <div class="stat-sub">Diagnosed across past exams</div>
      </div>
    </div>

    <!-- QUICK ACTIONS -->
    <div class="entity-section" style="margin-bottom:24px">
      <div class="entity-section-head">
        <h2>Quick Actions</h2>
      </div>
      <div class="entity-quick">
        <router-link to="/upload" class="entity-quick-item">
          <div class="entity-quick-icon entity-quick-icon-primary">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M12 5V19M5 12H19" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
          </div>
          <div class="entity-quick-title">Upload Report</div>
          <div class="entity-quick-sub">Publish SIRA diagnostics</div>
        </router-link>

        <router-link to="/my-content" class="entity-quick-item">
          <div class="entity-quick-icon entity-quick-icon-secondary">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M3 7C3 5.89543 3.89543 5 5 5H9L11 7H19C20.1046 7 21 7.89543 21 9V19C21 20.1046 20.1046 21 19 21H5C3.89543 21 3 20.1046 3 19V7Z" stroke="currentColor" stroke-width="1.6"/>
            </svg>
          </div>
          <div class="entity-quick-title">My Content</div>
          <div class="entity-quick-sub">Reports you've published</div>
        </router-link>

        <router-link to="/notifications" class="entity-quick-item">
          <div class="entity-quick-icon entity-quick-icon-warn">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M18 16V11C18 7.68629 15.3137 5 12 5C8.68629 5 6 7.68629 6 11V16L4 18H20L18 16Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
              <path d="M10 21H14" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
            </svg>
          </div>
          <div class="entity-quick-title">Notifications</div>
          <div class="entity-quick-sub">{{ unreadCount }} unread updates</div>
        </router-link>

        <router-link to="/profile" class="entity-quick-item">
          <div class="entity-quick-icon entity-quick-icon-purple">
            <svg viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.6"/>
              <path d="M4 21V19C4 16.7909 5.79086 15 8 15H16C18.2091 15 20 16.7909 20 19V21" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
            </svg>
          </div>
          <div class="entity-quick-title">My Profile</div>
          <div class="entity-quick-sub">Account & security settings</div>
        </router-link>
      </div>
    </div>

    <!-- CAROUSEL -->
    <DashboardCarousel
      title="Recent Reports"
      :items="carouselItems"
      variant="NECTA"
      style="margin-bottom:24px"
    />

    <!-- RECENT ACTIVITY -->
    <div v-if="recentItems.length" class="entity-section" style="margin-bottom:24px">
      <div class="entity-section-head">
        <h2>Recent Activity</h2>
        <router-link to="/my-content" class="entity-section-link">View all →</router-link>
      </div>
      <div class="entity-activity-list">
        <div
          v-for="item in recentItems"
          :key="item.id"
          class="entity-activity-item"
          @click="openInNewTab(item)"
        >
          <div class="entity-activity-dot" :class="`entity-activity-dot-${item.status}`"></div>
          <div class="entity-activity-body">
            <div class="entity-activity-title">{{ item.title }}</div>
            <div class="entity-activity-meta">
              {{ item.subject }} · {{ item.level }} · {{ formatDate(item.created_at) }}
            </div>
          </div>
          <span :class="badgeClass(item.badge)">{{ item.badge }}</span>
        </div>
      </div>
    </div>

    <!-- EMPTY STATE -->
    <div v-if="items.length === 0" class="empty-state">
      <div class="empty-icon">
        <svg viewBox="0 0 24 24" fill="none" width="56" height="56">
          <path d="M6 2H18C19.1046 2 20 2.89543 20 4V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.2"/>
        </svg>
      </div>
      <p style="margin-bottom:16px">No reports uploaded yet. Start by uploading your first SIRA diagnostic.</p>
      <router-link to="/upload" class="force-btn force-btn-primary">
        <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
          <path d="M12 5V19M5 12H19" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
        </svg>
        Upload your first report
      </router-link>
    </div>
  </AppShell>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import api from '../api.js';
import AppShell from '../components/AppShell.vue';
import DashboardCarousel from '../components/DashboardCarousel.vue';
import logoNecta from '../assets/logos/necta.png';

const user = JSON.parse(localStorage.getItem('user') || '{}');
const variant = computed(() => user.role || 'NECTA');

const router = useRouter();
const items = ref([]);
const notifications = ref([]);

const counts = computed(() => ({
  total: items.value.length,
  approved: items.value.filter((i) => i.status === 'approved').length,
  pending: items.value.filter((i) => i.status === 'pending').length,
}));

const unreadCount = computed(() => notifications.value.filter((n) => !n.read).length);

const recentItems = computed(() => items.value.slice(0, 5));

const subjectIcons = {
  Physics: `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="2.5" stroke="currentColor" stroke-width="1.5"/><ellipse cx="12" cy="12" rx="9" ry="4" stroke="currentColor" stroke-width="1.5"/></svg>`,
  Mathematics: `<svg viewBox="0 0 24 24" fill="none"><path d="M5 8H11M8 5V11" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="8" cy="17" r="3" stroke="currentColor" stroke-width="1.5"/></svg>`,
  Chemistry: `<svg viewBox="0 0 24 24" fill="none"><path d="M10 3H14V8L19 19C19.5 20.5 18 21 17 21H7C6 21 4.5 20.5 5 19L10 8V3Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>`,
  Biology: `<svg viewBox="0 0 24 24" fill="none"><path d="M12 3C8 3 6 6 6 9C6 13 9 15 12 21C15 15 18 13 18 9C18 6 16 3 12 3Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>`,
  default: `<svg viewBox="0 0 24 24" fill="none"><path d="M6 2H18C19.1046 2 20 2.89543 20 4V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.5"/></svg>`,
};

const carouselItems = computed(() =>
  items.value.slice(0, 12).map((i) => ({
    id: i.id,
    title: i.title,
    meta: `${i.subject} · ${i.level}`,
    icon: subjectIcons[i.subject] || subjectIcons.default,
  }))
);

function badgeClass(badge) {
  return {
    'TIE-Official': 'badge badge-tie',
    'NECTA-Official': 'badge badge-necta',
    'TIE-Reviewed': 'badge badge-reviewed',
    'Pending': 'badge badge-pending',
  }[badge] || 'badge';
}

function formatDate(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
}

function openInNewTab(item) {
  const resolved = router.resolve({ path: `/read/${item.id}` });
  const url = window.location.origin + window.location.pathname + '#' + resolved.href.split('#').slice(-1)[0];
  window.open(url, '_blank', 'noopener,noreferrer');
}

onMounted(async () => {
  try {
    const { data } = await api.get('/content');
    items.value = data;
  } catch {}
  try {
    const { data } = await api.get('/notifications');
    notifications.value = data;
  } catch {}
});
</script>
const user = JSON.parse(localStorage.getItem('user') || '{}');
const variant = computed(() => user.role || 'NECTA');