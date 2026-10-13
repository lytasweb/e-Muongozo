<template>
<AppShell :variant="variant" page-title="Pending Schools">
      <div class="tie-page">
      <div class="tie-header">
        <div>
          <h1>Pending School Registrations</h1>
          <p>Schools awaiting NECTA approval. Approve to grant upload access.</p>
        </div>
        <div class="tie-header-stat">
          <div class="tie-header-stat-value">{{ items.length }}</div>
          <div class="tie-header-stat-label">Pending</div>
        </div>
      </div>

      <div v-if="items.length" class="tie-filters">
        <div class="tie-search">
          <svg viewBox="0 0 24 24" fill="none" width="18" height="18">
            <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="1.8"/>
            <path d="M20 20L17 17" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
          </svg>
          <input v-model="query" placeholder="Search school, name, email…" />
        </div>
        <button class="force-btn force-btn-ghost force-btn-sm" @click="load">
          <svg viewBox="0 0 24 24" fill="none" width="14" height="14">
            <path d="M4 4V9H9M20 20V15H15M4 9C4.5 5 8 3 12 3C16.5 3 20 6 20 10M20 15C19.5 19 16 21 12 21C7.5 21 4 18 4 14" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          Refresh
        </button>
      </div>

      <div v-if="loading" class="empty-state">
        <div class="reader-spinner" style="margin: 0 auto;"></div>
        <p style="margin-top:12px">Loading…</p>
      </div>

      <div v-else-if="items.length === 0" class="empty-state">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" width="56" height="56">
            <path d="M4 20H20M4 20V8L12 4L20 8V20M4 20H9M20 20H15" stroke="currentColor" stroke-width="1.2"/>
            <rect x="9" y="12" width="6" height="8" stroke="currentColor" stroke-width="1.2"/>
          </svg>
        </div>
        <p>All clear — no pending school registrations.</p>
      </div>

      <div v-else class="tie-list">
        <div v-for="item in filtered" :key="item.id" class="tie-card">
          <div class="tie-card-avatar">{{ initials(item.full_name) }}</div>
          <div class="tie-card-body">
            <div class="tie-card-title">{{ item.school_name || item.full_name }}</div>
            <div class="tie-card-meta">
              <span>{{ item.full_name }}</span>
              <span class="mc-dot">·</span>
              <span>{{ item.email }}</span>
            </div>
            <div class="tie-card-time">Registered {{ relativeTime(item.created_at) }}</div>
          </div>
          <div class="tie-card-actions">
            <button
              class="force-btn force-btn-sm"
              style="background:#fef2f2 !important; color:#dc2626 !important; border:1px solid #fecaca !important;"
              @click="openReject(item)"
            >
              Reject
            </button>
            <button
              class="force-btn force-btn-sm"
              style="background:#10b981 !important; color:#fff !important;"
              @click="approve(item)"
              :disabled="busyId === item.id"
            >
              {{ busyId === item.id ? 'Approving…' : 'Approve' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <transition name="fade">
      <div v-if="rejectItem" class="preview-modal" @click.self="closeReject">
        <div class="preview-panel" style="max-width: 480px;">
          <div class="preview-header">
            <div class="preview-header-text">
              <div class="preview-title">Reject registration</div>
              <div class="preview-meta">{{ rejectItem.school_name || rejectItem.full_name }}</div>
            </div>
            <button class="preview-close" @click="closeReject">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M6 6L18 18M6 18L18 6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
              </svg>
            </button>
          </div>
          <div style="padding: 20px;">
            <label style="display:block; font-size:13px; font-weight:600; margin-bottom:6px;">Reason (optional)</label>
            <textarea v-model="rejectReason" rows="4" placeholder="e.g. School could not be verified" style="width:100%; padding:10px 12px; border:1px solid #e2e8f0; border-radius:10px; font-size:14px; font-family:inherit;"></textarea>
          </div>
          <div class="preview-footer">
            <div class="preview-footer-info"></div>
            <div class="preview-footer-actions">
              <button class="force-btn force-btn-ghost force-btn-sm" @click="closeReject">Cancel</button>
              <button class="force-btn force-btn-sm" style="background:#dc2626 !important; color:#fff !important;" @click="reject" :disabled="busyId === rejectItem.id">
                {{ busyId === rejectItem.id ? 'Rejecting…' : 'Confirm reject' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </AppShell>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import api from '../api.js';
import AppShell from '../components/AppShell.vue';

const user = JSON.parse(localStorage.getItem('user') || '{}');
const variant = computed(() => user.role || 'NECTA');

const items = ref([]);
const loading = ref(true);
const query = ref('');
const busyId = ref(null);
const rejectItem = ref(null);
const rejectReason = ref('');

const filtered = computed(() => {
  const q = query.value.trim().toLowerCase();
  if (!q) return items.value;
  return items.value.filter((i) =>
    [i.school_name, i.full_name, i.email].some((f) => String(f || '').toLowerCase().includes(q))
  );
});

function initials(name) {
  const s = String(name || '?').trim();
  if (!s) return '?';
  const p = s.split(/\s+/);
  if (p.length === 1) return p[0].slice(0, 2).toUpperCase();
  return (p[0][0] + p[p.length - 1][0]).toUpperCase();
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
    const { data } = await api.get('/schools/pending');
    items.value = data;
  } catch {
    items.value = [];
  } finally {
    loading.value = false;
  }
}

async function approve(item) {
  if (!confirm(`Approve "${item.school_name || item.full_name}"?`)) return;
  busyId.value = item.id;
  try {
    await api.post(`/schools/${item.id}/approve`);
    items.value = items.value.filter((x) => x.id !== item.id);
  } catch (e) { alert(e.response?.data?.error || 'Approve failed'); }
  finally { busyId.value = null; }
}

function openReject(item) { rejectItem.value = item; rejectReason.value = ''; }
function closeReject() { rejectItem.value = null; rejectReason.value = ''; }

async function reject() {
  if (!rejectItem.value) return;
  busyId.value = rejectItem.value.id;
  try {
    await api.post(`/schools/${rejectItem.value.id}/reject`, { reason: rejectReason.value });
    items.value = items.value.filter((x) => x.id !== rejectItem.value.id);
    closeReject();
  } catch (e) { alert(e.response?.data?.error || 'Reject failed'); }
  finally { busyId.value = null; }
}

onMounted(load);
</script>
