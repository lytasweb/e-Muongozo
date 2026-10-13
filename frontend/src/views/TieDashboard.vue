<template>
  <AppShell :variant="variant" page-title="TIE Dashboard">
    <!-- HERO -->
    <div class="entity-hero entity-hero-tie">
      <div class="entity-hero-left">
        <div class="entity-hero-logo">
          <img :src="logoTie" alt="TIE" />
        </div>
        <div>
          <div class="entity-hero-eyebrow">Tanzania Institute of Education</div>
          <h1 class="entity-hero-title">Welcome, TIE</h1>
          <p class="entity-hero-sub">Official curriculum, syllabus, and school oversight.</p>
        </div>
      </div>
      <div class="entity-hero-right">
        <div class="entity-hero-badge">TIE OFFICIAL</div>
      </div>
    </div>

    <!-- STAT CARDS -->
    <div class="grid grid-3" style="margin-bottom:24px">
      <div class="stat-card">
        <div class="stat-icon stat-icon-tie">
          <svg viewBox="0 0 24 24" fill="none">
            <path d="M4 5C4 3.89543 4.89543 3 6 3H18C19.1046 3 20 3.89543 20 5V19C20 20.1046 19.1046 21 18 21H6C4.89543 21 4 20.1046 4 19V5Z" stroke="currentColor" stroke-width="1.5"/>
            <path d="M8 3V21M12 8H16M12 12H16" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
          </svg>
        </div>
        <div class="stat-label">Curriculum Published</div>
        <div class="stat-value">{{ counts.total }}</div>
        <div class="stat-sub">Syllabi and textbooks</div>
      </div>

      <div class="stat-card">
        <div class="stat-icon stat-icon-success">
          <svg viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.5"/>
            <path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
        <div class="stat-label">TIE Staff</div>
        <div class="stat-value">{{ staffCount }}</div>
        <div class="stat-sub">{{ reviewerCount }} reviewers</div>
      </div>

      <div class="stat-card">
        <div class="stat-icon stat-icon-warning">
          <svg viewBox="0 0 24 24" fill="none">
            <path d="M4 20H20M4 20V8L12 4L20 8V20M4 20H9M20 20H15" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
            <rect x="9" y="12" width="6" height="8" stroke="currentColor" stroke-width="1.5"/>
          </svg>
        </div>
        <div class="stat-label">Registered Schools</div>
        <div class="stat-value">{{ schoolCount }}</div>
        <div class="stat-sub">Across the country</div>
      </div>
    </div>

    <!-- QUICK ACTIONS -->
    <div class="entity-section" style="margin-bottom:24px">
      <div class="entity-section-head">
        <h2>Quick Actions</h2>
      </div>
      <div class="entity-quick">
        <router-link v-if="isAdmin" to="/tie/members" class="entity-quick-item">
          <div class="entity-quick-icon entity-quick-icon-purple">
            <svg viewBox="0 0 24 24" fill="none">
              <circle cx="9" cy="8" r="3.2" stroke="currentColor" stroke-width="1.6"/>
              <path d="M3 20V18C3 15.7909 4.79086 14 7 14H11C13.2091 14 15 15.7909 15 18V20" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
              <circle cx="17" cy="8" r="2.6" stroke="currentColor" stroke-width="1.6"/>
              <path d="M16 14H18C20.2091 14 22 15.7909 22 18V20" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
            </svg>
          </div>
          <div class="entity-quick-title">Members</div>
          <div class="entity-quick-sub">Manage staff & reviewers</div>
        </router-link>

        <router-link v-if="isAdmin" to="/tie/registered" class="entity-quick-item">
          <div class="entity-quick-icon entity-quick-icon-secondary">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M4 20H20M4 20V8L12 4L20 8V20M4 20H9M20 20H15" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
              <rect x="9" y="12" width="6" height="8" stroke="currentColor" stroke-width="1.6"/>
            </svg>
          </div>
          <div class="entity-quick-title">Registered Schools</div>
          <div class="entity-quick-sub">View & manage schools</div>
        </router-link>

        <router-link to="/upload" class="entity-quick-item">
          <div class="entity-quick-icon entity-quick-icon-primary">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M12 5V19M5 12H19" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
          </div>
          <div class="entity-quick-title">Upload Curriculum</div>
          <div class="entity-quick-sub">Publish new guides</div>
        </router-link>

        <router-link to="/my-content" class="entity-quick-item">
          <div class="entity-quick-icon entity-quick-icon-secondary">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M3 7C3 5.89543 3.89543 5 5 5H9L11 7H19C20.1046 7 21 7.89543 21 9V19C21 20.1046 20.1046 21 19 21H5C3.89543 21 3 20.1046 3 19V7Z" stroke="currentColor" stroke-width="1.6"/>
            </svg>
          </div>
          <div class="entity-quick-title">My Content</div>
          <div class="entity-quick-sub">Your published guides</div>
        </router-link>
      </div>
    </div>

    <!-- RECENT STAFF ACTIVITY (admin only) -->
    <div v-if="isAdmin && recentStaff.length" class="entity-section" style="margin-bottom:24px">
      <div class="entity-section-head">
        <h2>Recent Staff Activity</h2>
        <router-link to="/tie/members" class="entity-section-link">View all →</router-link>
      </div>
      <div class="entity-activity-list">
        <div v-for="m in recentStaff" :key="m.id" class="entity-activity-item">
          <div class="entity-activity-dot" :class="m.role === 'REVIEWER' ? 'entity-activity-dot-approved' : 'entity-activity-dot-draft'"></div>
          <div class="entity-activity-body">
            <div class="entity-activity-title">{{ m.full_name }}</div>
            <div class="entity-activity-meta">
              {{ roleLabel(m.role) }} · Last login {{ relativeTime(m.last_login_at) }}
            </div>
          </div>
          <span class="tie-member-role" :class="`tie-member-role-${m.role.toLowerCase()}`">
            {{ roleLabel(m.role) }}
          </span>
        </div>
      </div>
    </div>

    <!-- RECENT CURRICULUM -->
    <div v-if="recentItems.length" class="entity-section" style="margin-bottom:24px">
      <div class="entity-section-head">
        <h2>Recent Curriculum</h2>
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

    <!-- CAROUSEL -->
    <DashboardCarousel
      title="Recent Uploads"
      :items="carouselItems"
      variant="TIE"
    />

    <div v-if="items.length === 0" class="empty-state" style="margin-top:24px">
      <div class="empty-icon">
        <svg viewBox="0 0 24 24" fill="none" width="56" height="56">
          <path d="M4 5C4 3.89543 4.89543 3 6 3H18C19.1046 3 20 3.89543 20 5V19C20 20.1046 19.1046 21 18 21H6C4.89543 21 4 20.1046 4 19V5Z" stroke="currentColor" stroke-width="1.2"/>
        </svg>
      </div>
      <p style="margin-bottom:16px">No curriculum uploaded yet.</p>
      <router-link to="/upload" class="force-btn force-btn-primary">
        <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
          <path d="M12 5V19M5 12H19" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
        </svg>
        Upload your first guide
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
import logoTie from '../assets/logos/tie.png';

const router = useRouter();
const user = JSON.parse(localStorage.getItem('user') || '{}');
const variant = computed(() => user.role || 'TIE');
const isAdmin = computed(() => user.role === 'TIE' && user.is_admin === true);

const items = ref([]);
const staffCount = ref(0);
const reviewerCount = ref(0);
const schoolCount = ref(0);
const recentStaff = ref([]);

const counts = computed(() => ({
  total: items.value.length,
  approved: items.value.filter((i) => i.status === 'approved').length,
  pending: items.value.filter((i) => i.status === 'pending').length,
}));

const recentItems = computed(() => items.value.slice(0, 5));

const subjectIcons = {
  Physics: `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="2.5" stroke="currentColor" stroke-width="1.5"/><ellipse cx="12" cy="12" rx="9" ry="4" stroke="currentColor" stroke-width="1.5"/></svg>`,
  Mathematics: `<svg viewBox="0 0 24 24" fill="none"><path d="M5 8H11M8 5V11" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="8" cy="17" r="3" stroke="currentColor" stroke-width="1.5"/></svg>`,
  Chemistry: `<svg viewBox="0 0 24 24" fill="none"><path d="M10 3H14V8L19 19C19.5 20.5 18 21 17 21H7C6 21 4.5 20.5 5 19L10 8V3Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>`,
  Biology: `<svg viewBox="0 0 24 24" fill="none"><path d="M12 3C8 3 6 6 6 9C6 13 9 15 12 21C15 15 18 13 18 9C18 6 16 3 12 3Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>`,
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

function badgeClass(badge) {
  return {
    'TIE-Official': 'badge badge-tie',
    'NECTA-Official': 'badge badge-necta',
    'TIE-Reviewed': 'badge badge-reviewed',
    'Pending': 'badge badge-pending',
  }[badge] || 'badge';
}

function roleLabel(role) {
  return {
    TIE: 'TIE Admin',
    TIESTAFF: 'TIE Staff',
    REVIEWER: 'Reviewer',
    NECTA: 'NECTA',
    SCHOOL: 'School',
  }[role] || role;
}

function relativeTime(iso) {
  if (!iso) return '';
  const diff = (Date.now() - new Date(iso).getTime()) / 1000;
  if (diff < 60) return 'just now';
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`;
  return new Date(iso).toLocaleDateString();
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

  if (isAdmin.value) {
    try {
      const { data } = await api.get('/members');
      staffCount.value = data.filter((m) => m.role === 'TIESTAFF').length;
      reviewerCount.value = data.filter((m) => m.role === 'REVIEWER').length;
      recentStaff.value = data
        .filter((m) => m.last_login_at)
        .sort((a, b) => new Date(b.last_login_at) - new Date(a.last_login_at))
        .slice(0, 5);
    } catch {}

    try {
      const { data } = await api.get('/schools/registered');
      schoolCount.value = data.length;
    } catch {}
  }
});
</script>
