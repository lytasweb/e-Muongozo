<template>
  <div class="shell" :class="{ 'shell-collapsed': collapsed, 'shell-mobile-open': mobileOpen }">
    <div v-if="mobileOpen" class="shell-overlay" @click="mobileOpen = false"></div>

    <aside class="shell-sidebar" :class="`shell-sidebar-${variantClass}`">
      <div class="shell-sidebar-top">
        <div class="shell-brand">
          <div class="shell-brand-logo">
            <img :src="variantLogo" :alt="variant" />
          </div>
          <div class="shell-brand-text">
            <div class="shell-brand-name">{{ variantLabel }}</div>
            <div class="shell-brand-sub">e-Muongozo</div>
          </div>
        </div>
      </div>

      <nav class="shell-nav">
        <router-link
          v-for="item in navItems"
          :key="item.path"
          :to="item.path"
          class="shell-nav-item"
          :class="{ 'shell-nav-item-active': isActive(item.path) }"
          @click="mobileOpen = false"
        >
          <span class="shell-nav-icon" v-html="item.icon"></span>
          <span class="shell-nav-label">{{ item.label }}</span>
          <span v-if="collapsed && !isMobile" class="shell-tooltip">{{ item.label }}</span>
        </router-link>
      </nav>

      <div class="shell-sidebar-bottom">
        <div class="shell-user-chip" :title="user.full_name">
          <div class="shell-user-avatar">{{ initials }}</div>
          <div class="shell-user-text">
            <div class="shell-user-name">{{ user.full_name }}</div>
            <div class="shell-user-role">{{ roleLabel }}</div>
          </div>
        </div>
      </div>
    </aside>

    <div class="shell-main">
      <header class="shell-topbar">
        <div class="shell-topbar-left">
          <button class="shell-mobile-btn" @click="mobileOpen = !mobileOpen" aria-label="Menu">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M4 7H20M4 12H20M4 17H20" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
          </button>

          <button
            class="shell-collapse-btn"
            @click="collapsed = !collapsed; saveCollapsed()"
            :aria-label="collapsed ? 'Expand sidebar' : 'Collapse sidebar'"
          >
            <svg viewBox="0 0 24 24" fill="none">
              <rect x="3" y="4" width="18" height="16" rx="2.5" stroke="currentColor" stroke-width="1.6"/>
              <line x1="9" y1="4" x2="9" y2="20" stroke="currentColor" stroke-width="1.6"/>
              <path
                :d="collapsed ? 'M12 9L14 12L12 15' : 'M15 9L13 12L15 15'"
                stroke="currentColor"
                stroke-width="1.8"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
          </button>

          <div class="shell-page-title">{{ pageTitle }}</div>
        </div>

        <div class="shell-topbar-right">
          <button class="shell-icon-btn" aria-label="Search" @click="openSearch">
            <svg viewBox="0 0 24 24" fill="none">
              <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="1.8"/>
              <path d="M20 20L17 17" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
            </svg>
          </button>

          <div class="shell-notif" ref="notifRef">
            <button class="shell-icon-btn shell-icon-btn-badge" aria-label="Notifications" @click="toggleNotif">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M18 16V11C18 7.68629 15.3137 5 12 5C8.68629 5 6 7.68629 6 11V16L4 18H20L18 16Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
                <path d="M10 21H14" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
              </svg>
              <span v-if="unreadCount > 0" class="shell-notif-dot">{{ unreadCount }}</span>
            </button>

            <transition name="drop">
              <div v-if="notifOpen" class="shell-notif-menu">
                <div class="shell-notif-head">
                  <div class="shell-notif-title">Notifications</div>
                  <button class="shell-notif-mark" @click="markAllRead" v-if="notifications.length">
                    Mark all read
                  </button>
                </div>

                <div v-if="loadingNotifs" class="shell-notif-empty">
                  <p>Loading…</p>
                </div>

                <div v-else-if="notifications.length === 0" class="shell-notif-empty">
                  <svg viewBox="0 0 24 24" fill="none" width="32" height="32">
                    <path d="M18 16V11C18 7.68629 15.3137 5 12 5C8.68629 5 6 7.68629 6 11V16L4 18H20L18 16Z" stroke="currentColor" stroke-width="1.5"/>
                  </svg>
                  <p>You're all caught up</p>
                </div>

                <div v-else class="shell-notif-list">
                  <div
                    v-for="n in notifications"
                    :key="n.id"
                    class="shell-notif-item"
                    :class="{ 'shell-notif-item-unread': !n.read }"
                    @click="openNotification(n)"
                  >
                    <div class="shell-notif-icon" :class="`shell-notif-icon-${n.type}`" v-html="notifIcon(n.type)"></div>
                    <div class="shell-notif-body">
                      <div class="shell-notif-text">{{ n.text }}</div>
                      <div class="shell-notif-time">{{ n.time }}</div>
                    </div>
                  </div>
                </div>

                <div class="shell-notif-foot">
                  <router-link to="/notifications" class="shell-notif-viewall" @click="notifOpen = false">
                    View all notifications
                  </router-link>
                </div>
              </div>
            </transition>
          </div>

          <div class="shell-profile" ref="profileRef">
            <button class="shell-profile-btn" @click="toggleProfile">
              <div class="shell-profile-avatar">{{ initials }}</div>
              <svg class="shell-profile-caret" viewBox="0 0 24 24" fill="none">
                <path d="M6 9L12 15L18 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </button>

            <transition name="drop">
              <div v-if="profileOpen" class="shell-profile-menu">
                <div class="shell-profile-head">
                  <div class="shell-profile-head-avatar">{{ initials }}</div>
                  <div>
                    <div class="shell-profile-head-name">{{ user.full_name }}</div>
                    <div class="shell-profile-head-email">{{ user.email }}</div>
                  </div>
                </div>

                <div class="shell-profile-divider"></div>

                <router-link to="/notifications" class="shell-profile-item" @click="profileOpen = false">
                  <svg viewBox="0 0 24 24" fill="none">
                    <path d="M18 16V11C18 7.68629 15.3137 5 12 5C8.68629 5 6 7.68629 6 11V16L4 18H20L18 16Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
                    <path d="M10 21H14" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                  </svg>
                  <span>Notifications</span>
                  <span v-if="unreadCount > 0" class="shell-profile-badge">{{ unreadCount }}</span>
                </router-link>

                <router-link to="/profile" class="shell-profile-item" @click="profileOpen = false">
                  <svg viewBox="0 0 24 24" fill="none">
                    <circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.5"/>
                    <path d="M4 21V19C4 16.7909 5.79086 15 8 15H16C18.2091 15 20 16.7909 20 19V21" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                  </svg>
                  <span>My Profile</span>
                </router-link>

                <div class="shell-profile-divider"></div>

                <button class="shell-profile-item shell-profile-item-danger" @click="logout">
                  <svg viewBox="0 0 24 24" fill="none">
                    <path d="M9 21H5C4.44772 21 4 20.5523 4 20V4C4 3.44772 4.44772 3 5 3H9" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                    <path d="M16 17L21 12L16 7" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                    <path d="M21 12H9" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                  </svg>
                  <span>Logout</span>
                </button>
              </div>
            </transition>
          </div>
        </div>
      </header>

      <main class="shell-content">
        <slot />
      </main>
    </div>

    <transition name="fade">
      <div v-if="searchOpen" class="search-modal" @click.self="searchOpen = false">
        <div class="search-panel">
          <div class="search-input-row">
            <svg viewBox="0 0 24 24" fill="none" width="20" height="20">
              <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="1.8"/>
              <path d="M20 20L17 17" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
            </svg>
            <input
              ref="searchInput"
              v-model="searchQuery"
              type="text"
              placeholder="Search content, topics, subjects…"
              @keydown.esc="searchOpen = false"
            />
            <button class="search-close" @click="searchOpen = false">Esc</button>
          </div>

          <div class="search-results">
            <div v-if="searching" class="search-hint">Searching…</div>
            <div v-else-if="searchQuery && searchResults.length === 0" class="search-empty">
              No results for "{{ searchQuery }}"
            </div>
            <div v-else-if="!searchQuery" class="search-hint">
              Start typing to search across curriculum, reports, and content.
              <div class="search-kbd-hint">Tip: press <kbd>Ctrl</kbd> + <kbd>K</kbd> anytime.</div>
            </div>
            <div v-else class="search-list">
              <div
                v-for="item in searchResults"
                :key="item.id"
                class="search-item"
                @click="openContent(item)"
              >
                <div class="search-item-icon">
                  <svg viewBox="0 0 24 24" fill="none" width="18" height="18">
                    <path d="M4 5C4 3.89543 4.89543 3 6 3H18C19.1046 3 20 3.89543 20 5V19C20 20.1046 19.1046 21 18 21H6C4.89543 21 4 20.1046 4 19V5Z" stroke="currentColor" stroke-width="1.5"/>
                  </svg>
                </div>
                <div style="min-width:0; flex:1">
                  <div class="search-item-title">{{ item.title }}</div>
                  <div class="search-item-meta">{{ item.subject }} · {{ item.level }} · {{ item.topic }}</div>
                </div>
                <span :class="badgeClass(item.badge)">{{ item.badge }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api from '../api.js';
import logoEmuongozo from '../assets/logos/emuongozo.png';
import logoTie from '../assets/logos/tie.png';
import logoNecta from '../assets/logos/necta.png';

const props = defineProps({
  variant: { type: String, default: 'SCHOOL' },
  pageTitle: { type: String, default: 'Dashboard' },
});

const route = useRoute();
const router = useRouter();

const collapsed = ref(localStorage.getItem('shell-collapsed') === 'true');
const profileOpen = ref(false);
const notifOpen = ref(false);
const mobileOpen = ref(false);
const searchOpen = ref(false);
const searchQuery = ref('');
const searchResults = ref([]);
const searching = ref(false);
const isMobile = ref(false);
const profileRef = ref(null);
const notifRef = ref(null);
const searchInput = ref(null);

const user = JSON.parse(localStorage.getItem('user') || '{}');

const notifications = ref([]);
const loadingNotifs = ref(false);

let searchTimer = null;

const unreadCount = computed(() => notifications.value.filter((n) => !n.read).length);

const initials = computed(() => {
  const full = (user.full_name || '').trim();
  if (!full) return '?';
  const parts = full.split(/\s+/);
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
});

// Normalize variant class: TIESTAFF shares TIE visual skin
const variantClass = computed(() => {
  if (props.variant === 'TIESTAFF') return 'TIE';
  return props.variant;
});

const variantLabel = computed(() => ({
  TIE: 'TIE Portal',
  TIESTAFF: 'TIE Portal',
  NECTA: 'NECTA Portal',
  SCHOOL: 'School Portal',
  REVIEWER: 'Reviewer Portal',
}[props.variant] || 'Portal'));

const variantLogo = computed(() => {
  if (props.variant === 'TIE' || props.variant === 'TIESTAFF') return logoTie;
  if (props.variant === 'NECTA') return logoNecta;
  return logoEmuongozo;
});

const roleLabel = computed(() => ({
  TIE: 'TIE Admin',
  TIESTAFF: 'TIE Staff',
  NECTA: 'NECTA Admin',
  SCHOOL: 'School Contributor',
  REVIEWER: 'TIE Reviewer',
}[user.role] || ''));

const icons = {
  home: `<svg viewBox="0 0 24 24" fill="none"><path d="M3 11L12 3L21 11V20C21 20.5523 20.5523 21 20 21H15V15H9V21H4C3.44772 21 3 20.5523 3 20V11Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>`,
  upload: `<svg viewBox="0 0 24 24" fill="none"><path d="M12 4V16" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M7 9L12 4L17 9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><path d="M5 20H19" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>`,
  folder: `<svg viewBox="0 0 24 24" fill="none"><path d="M3 7C3 5.89543 3.89543 5 5 5H9L11 7H19C20.1046 7 21 7.89543 21 9V19C21 20.1046 20.1046 21 19 21H5C3.89543 21 3 20.1046 3 19V7Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/></svg>`,
  check: `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.5"/><path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  clock: `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/><path d="M12 7V12L15 15" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>`,
  people: `<svg viewBox="0 0 24 24" fill="none"><circle cx="9" cy="8" r="3.2" stroke="currentColor" stroke-width="1.6"/><path d="M3 20V18C3 15.7909 4.79086 14 7 14H11C13.2091 14 15 15.7909 15 18V20" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/><circle cx="17" cy="8" r="2.6" stroke="currentColor" stroke-width="1.6"/><path d="M16 14H18C20.2091 14 22 15.7909 22 18V20" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>`,
};

// ============================================================
// NAV ITEMS — check is_admin for admin-only links
// ============================================================
const navItems = computed(() => {
  // REVIEWER
  if (props.variant === 'REVIEWER') {
    return [
      { path: '/dashboard', label: 'Dashboard', icon: icons.home },
      { path: '/review', label: 'Review Queue', icon: icons.check },
    ];
  }

  // TIE (admin + staff share the same visual variant)
  if (props.variant === 'TIE' || props.variant === 'TIESTAFF') {
    const isTieAdmin = user.role === 'TIE' && user.is_admin === true;

    const base = [{ path: '/tie', label: 'Dashboard', icon: icons.home }];

    if (isTieAdmin) {
      base.push({ path: '/tie/members', label: 'Members', icon: icons.people });
      base.push({ path: '/tie/registered', label: 'Registered Schools', icon: icons.folder });
    }

    base.push({ path: '/upload', label: 'Upload Curriculum', icon: icons.upload });
    base.push({ path: '/my-content', label: 'My Content', icon: icons.folder });

    return base;
  }

  // NECTA
  if (props.variant === 'NECTA') {
    const isNectaAdmin = user.role === 'NECTA' && user.is_admin === true;

    const base = [{ path: '/necta', label: 'Dashboard', icon: icons.home }];

    if (isNectaAdmin) {
      base.push({ path: '/necta/pending', label: 'Pending Schools', icon: icons.clock });
      base.push({ path: '/necta/registered', label: 'Registered Schools', icon: icons.folder });
      base.push({ path: '/necta/members', label: 'Members', icon: icons.people });
    }

    base.push({ path: '/upload', label: 'Upload Reports', icon: icons.upload });
    base.push({ path: '/my-content', label: 'My Content', icon: icons.folder });

    return base;
  }

  // SCHOOL
  return [
    { path: '/dashboard', label: 'Dashboard', icon: icons.home },
    { path: '/upload', label: 'Upload Content', icon: icons.upload },
    { path: '/my-content', label: 'My Content', icon: icons.folder },
  ];
});

function isActive(path) {
  return route.path === path;
}

function saveCollapsed() {
  localStorage.setItem('shell-collapsed', collapsed.value);
}

function toggleProfile() {
  profileOpen.value = !profileOpen.value;
  if (profileOpen.value) {
    notifOpen.value = false;
    loadNotifications();
  }
}

function toggleNotif() {
  notifOpen.value = !notifOpen.value;
  if (notifOpen.value) {
    profileOpen.value = false;
    loadNotifications();
  }
}

function badgeClass(badge) {
  return {
    'TIE-Official': 'badge badge-tie',
    'NECTA-Official': 'badge badge-necta',
    'TIE-Reviewed': 'badge badge-reviewed',
    'Pending': 'badge badge-pending',
  }[badge] || 'badge';
}

function notifIcon(type) {
  if (type === 'approval') return `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/><path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
  if (type === 'review') return `<svg viewBox="0 0 24 24" fill="none"><path d="M6 2H18C19.1046 2 20 2.89543 20 4V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.8"/><path d="M8 7H16M8 11H16M8 15H13" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>`;
  return `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/><path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>`;
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

async function loadNotifications() {
  loadingNotifs.value = true;
  try {
    const { data } = await api.get('/notifications');
    notifications.value = (data || []).map((n) => ({
      id: n.id,
      type: n.type,
      text: n.text,
      time: relativeTime(n.created_at),
      read: n.read,
      link: n.link,
    }));
  } catch {
    notifications.value = [];
  } finally {
    loadingNotifs.value = false;
  }
}

async function markAllRead() {
  try {
    await api.post('/notifications/mark-all-read');
    notifications.value = notifications.value.map((n) => ({ ...n, read: true }));
  } catch {}
}

async function openNotification(n) {
  if (!n.read) {
    try {
      await api.post(`/notifications/${n.id}/read`);
      n.read = true;
    } catch {}
  }
  notifOpen.value = false;
  if (n.link) {
    router.push(n.link);
  } else {
    router.push('/notifications');
  }
}

function openSearch() {
  searchOpen.value = true;
  searchQuery.value = '';
  searchResults.value = [];
}

function openContent(item) {
  searchOpen.value = false;
  searchQuery.value = '';
  searchResults.value = [];
  router.push('/my-content');
}

function logout() {
  localStorage.removeItem('token');
  localStorage.removeItem('user');
  router.push('/login');
}

function handleClickOutside(e) {
  if (profileRef.value && !profileRef.value.contains(e.target)) profileOpen.value = false;
  if (notifRef.value && !notifRef.value.contains(e.target)) notifOpen.value = false;
}

function checkMobile() {
  isMobile.value = window.innerWidth < 900;
  if (!isMobile.value) mobileOpen.value = false;
}

function handleKeydown(e) {
  if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
    e.preventDefault();
    openSearch();
  }
  if (e.key === 'Escape') {
    searchOpen.value = false;
  }
}

watch(searchQuery, (q) => {
  if (searchTimer) clearTimeout(searchTimer);
  const term = q.trim();
  if (!term) {
    searchResults.value = [];
    searching.value = false;
    return;
  }
  searching.value = true;
  searchTimer = setTimeout(async () => {
    try {
      const { data } = await api.get('/search', { params: { q: term } });
      searchResults.value = data.results || [];
    } catch {
      searchResults.value = [];
    } finally {
      searching.value = false;
    }
  }, 250);
});

watch(searchOpen, async (val) => {
  if (val) {
    await nextTick();
    searchInput.value?.focus();
  }
});

onMounted(async () => {
  checkMobile();
  window.addEventListener('resize', checkMobile);
  document.addEventListener('click', handleClickOutside);
  document.addEventListener('keydown', handleKeydown);

  await loadNotifications();
});

onBeforeUnmount(() => {
  window.removeEventListener('resize', checkMobile);
  document.removeEventListener('click', handleClickOutside);
  document.removeEventListener('keydown', handleKeydown);
  if (searchTimer) clearTimeout(searchTimer);
});
</script>
