<template>
  <AppShell :variant="variant" page-title="Notifications">
    <div class="notif-page">
      <div class="notif-page-head">
        <div>
          <h1>Notifications</h1>
          <p>{{ items.length }} total · {{ unreadCount }} unread</p>
        </div>
        <button
          class="btn btn-ghost btn-sm"
          @click="markAllRead"
          :disabled="unreadCount === 0"
        >
          Mark all read
        </button>
      </div>

      <div v-if="loading" class="empty-state">
        <p>Loading…</p>
      </div>

      <div v-else-if="items.length === 0" class="empty-state">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" width="48" height="48">
            <path d="M18 16V11C18 7.68629 15.3137 5 12 5C8.68629 5 6 7.68629 6 11V16L4 18H20L18 16Z" stroke="currentColor" stroke-width="1.2"/>
          </svg>
        </div>
        <p>You're all caught up.</p>
      </div>

      <div v-else class="notif-page-list">
        <div
          v-for="n in items"
          :key="n.id"
          class="notif-page-item"
          :class="{ 'notif-page-item-unread': !n.read }"
          @click="openItem(n)"
        >
          <div
            class="notif-page-icon"
            :class="`notif-page-icon-${n.type}`"
            v-html="notifIcon(n.type)"
          ></div>
          <div class="notif-page-body">
            <div class="notif-page-title">{{ n.title }}</div>
            <div class="notif-page-text">{{ n.text }}</div>
            <div class="notif-page-time">{{ relativeTime(n.created_at) }}</div>
          </div>
          <button class="notif-page-delete" @click.stop="removeItem(n.id)" title="Delete">
            <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
              <path d="M6 6L18 18M6 18L18 6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
          </button>
        </div>
      </div>
    </div>
  </AppShell>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import api from '../api.js';
import AppShell from '../components/AppShell.vue';

const router = useRouter();
const user = JSON.parse(localStorage.getItem('user') || '{}');
const variant = computed(() => user.role || 'SCHOOL');
const items = ref([]);
const loading = ref(true);

const unreadCount = computed(() => items.value.filter((i) => !i.read).length);

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

async function load() {
  loading.value = true;
  try {
    const { data } = await api.get('/notifications');
    items.value = data;
  } catch {
    items.value = [];
  } finally {
    loading.value = false;
  }
}

async function markAllRead() {
  try {
    await api.post('/notifications/mark-all-read');
    items.value = items.value.map((i) => ({ ...i, read: true }));
  } catch {}
}

async function removeItem(id) {
  try {
    await api.delete(`/notifications/${id}`);
    items.value = items.value.filter((i) => i.id !== id);
  } catch {}
}

async function openItem(n) {
  if (!n.read) {
    try {
      await api.post(`/notifications/${n.id}/read`);
      n.read = true;
    } catch {}
  }
  if (n.link) router.push(n.link);
}

onMounted(load);
</script>
