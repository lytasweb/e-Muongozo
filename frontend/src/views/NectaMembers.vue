<template>
  <AppShell :variant="variant" page-title="NECTA Members">
    <div class="tie-page">
      <div class="tie-header">
        <div>
          <h1>NECTA Members</h1>
          <p>NECTA staff and all registered schools. Manage access and permissions.</p>
        </div>
        <div class="tie-header-stat">
          <div class="tie-header-stat-value">{{ members.length }}</div>
          <div class="tie-header-stat-label">Total</div>
        </div>
      </div>

      <div class="tie-members-stats">
        <div class="tie-stat-mini">
          <div class="tie-stat-mini-value">{{ counts.necta }}</div>
          <div class="tie-stat-mini-label">NECTA</div>
        </div>
        <div class="tie-stat-mini">
          <div class="tie-stat-mini-value">{{ counts.admins }}</div>
          <div class="tie-stat-mini-label">Admins</div>
        </div>
        <div class="tie-stat-mini">
          <div class="tie-stat-mini-value">{{ counts.schools }}</div>
          <div class="tie-stat-mini-label">Schools</div>
        </div>
        <div class="tie-stat-mini">
          <div class="tie-stat-mini-value">{{ counts.suspended }}</div>
          <div class="tie-stat-mini-label">Suspended</div>
        </div>
      </div>

      <div class="tie-filters">
        <div class="tie-search">
          <svg viewBox="0 0 24 24" fill="none" width="18" height="18">
            <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="1.8"/>
            <path d="M20 20L17 17" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
          </svg>
          <input v-model="query" placeholder="Search by name, email, school…" />
        </div>

        <select v-model="roleFilter" class="tie-filter-select">
          <option value="">All roles</option>
          <option value="NECTA">NECTA staff</option>
          <option value="SCHOOL">Schools</option>
        </select>

        <select v-model="statusFilter" class="tie-filter-select">
          <option value="">All statuses</option>
          <option value="approved">Approved</option>
          <option value="pending">Pending</option>
          <option value="suspended">Suspended</option>
          <option value="rejected">Rejected</option>
        </select>

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

      <div v-else-if="filtered.length === 0" class="empty-state">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" width="56" height="56">
            <circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.2"/>
            <path d="M4 21V19C4 16.7909 5.79086 15 8 15H16C18.2091 15 20 16.7909 20 19V21" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
          </svg>
        </div>
        <p>No members found.</p>
      </div>

      <div v-else class="tie-members-list">
        <div v-for="m in filtered" :key="`${m.role}-${m.id}`" class="tie-member-row">
          <div class="tie-member-avatar" :class="`tie-member-avatar-${m.role.toLowerCase()}`">
            {{ initials(m.full_name) }}
          </div>

          <div class="tie-member-info">
            <div class="tie-member-name">
              {{ m.full_name }}
              <span v-if="m.is_admin" class="tie-admin-badge">Admin</span>
            </div>
            <div class="tie-member-meta">
              {{ m.email }}
              <template v-if="m.school_name"> · {{ m.school_name }}</template>
            </div>
            <div class="tie-member-last-login">
              <template v-if="m.last_login_at">Last login: {{ relativeTime(m.last_login_at) }}</template>
              <template v-else>Never logged in</template>
            </div>
          </div>

          <span class="tie-member-role" :class="`tie-member-role-${m.role.toLowerCase()}`">
            {{ roleLabel(m.role) }}
          </span>

          <span class="tie-member-status" :class="`tie-member-status-${m.approval_status}`">
            {{ m.approval_status }}
          </span>

          <div class="tie-member-actions">
            <button class="tie-action-btn" @click="openReminder(m)" title="Send reminder">
              <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                <path d="M4 4H20V16H13L8 20V16H4V4Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
              </svg>
            </button>

            <button
              v-if="canMakeAdmin(m)"
              class="tie-action-btn tie-action-btn-admin"
              @click="makeAdmin(m)"
              title="Make admin"
            >
              <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                <path d="M12 2L15 9L22 10L17 15L18 22L12 19L6 22L7 15L2 10L9 9L12 2Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
              </svg>
            </button>

            <button
              v-if="canRevokeAdmin(m)"
              class="tie-action-btn tie-action-btn-demote"
              @click="revokeAdmin(m)"
              title="Revoke admin"
            >
              <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                <path d="M12 5V19M5 12L12 19L19 12" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </button>

            <button
              v-if="canSuspend(m)"
              class="tie-action-btn tie-action-btn-danger"
              @click="openSuspend(m)"
              title="Suspend"
            >
              <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/>
                <path d="M9 9L15 15M15 9L9 15" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
              </svg>
            </button>

            <button
              v-if="canActivate(m)"
              class="tie-action-btn tie-action-btn-success"
              @click="activate(m)"
              title="Activate"
            >
              <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/>
                <path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </button>
          </div>

          <div class="tie-member-date">{{ formatDate(m.created_at) }}</div>
        </div>
      </div>
    </div>

    <ReminderModal
      v-if="reminderTarget"
      :target="reminderTarget"
      :endpoint="reminderTarget.role === 'SCHOOL'
        ? `/schools/${reminderTarget.id}/remind`
        : `/members/${reminderTarget.id}/remind`"
      @close="reminderTarget = null"
      @sent="onReminderSent"
    />

    <transition name="fade">
      <div v-if="suspendTarget" class="preview-modal" @click.self="suspendTarget = null">
        <div class="preview-panel" style="max-width: 480px;">
          <div class="preview-header">
            <div class="preview-header-text">
              <div class="preview-title">Suspend member</div>
              <div class="preview-meta">{{ suspendTarget.full_name }} · {{ suspendTarget.email }}</div>
            </div>
            <button class="preview-close" @click="suspendTarget = null">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M6 6L18 18M6 18L18 6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
              </svg>
            </button>
          </div>
          <div style="padding: 20px;">
            <label style="display:block; font-size:13px; font-weight:600; margin-bottom:6px;">Reason (optional)</label>
            <textarea v-model="suspendReason" rows="4" placeholder="e.g. Policy violation" style="width:100%; padding:10px 12px; border:1px solid #e2e8f0; border-radius:10px; font-size:14px; font-family:inherit;"></textarea>
          </div>
          <div class="preview-footer">
            <div class="preview-footer-info"></div>
            <div class="preview-footer-actions">
              <button class="force-btn force-btn-ghost force-btn-sm" @click="suspendTarget = null">Cancel</button>
              <button class="force-btn force-btn-sm" style="background:#dc2626 !important; color:#fff !important;" @click="suspend">Confirm suspend</button>
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
import ReminderModal from '../components/ReminderModal.vue';

const user = JSON.parse(localStorage.getItem('user') || '{}');
const variant = computed(() => user.role || 'NECTA');

const members = ref([]);
const loading = ref(true);
const query = ref('');
const roleFilter = ref('');
const statusFilter = ref('');
const reminderTarget = ref(null);
const suspendTarget = ref(null);
const suspendReason = ref('');

const counts = computed(() => ({
  necta: members.value.filter((m) => m.role === 'NECTA').length,
  admins: members.value.filter((m) => m.role === 'NECTA' && m.is_admin).length,
  schools: members.value.filter((m) => m.role === 'SCHOOL').length,
  suspended: members.value.filter((m) => m.approval_status === 'suspended').length,
}));

const filtered = computed(() => {
  const q = query.value.trim().toLowerCase();
  return members.value.filter((m) => {
    if (roleFilter.value && m.role !== roleFilter.value) return false;
    if (statusFilter.value && m.approval_status !== statusFilter.value) return false;
    if (q && ![m.full_name, m.email, m.school_name].some((f) => String(f || '').toLowerCase().includes(q))) return false;
    return true;
  });
});

function initials(name) {
  const s = String(name || '?').trim();
  if (!s) return '?';
  const p = s.split(/\s+/);
  if (p.length === 1) return p[0].slice(0, 2).toUpperCase();
  return (p[0][0] + p[p.length - 1][0]).toUpperCase();
}

function roleLabel(role) {
  return { NECTA: 'NECTA', SCHOOL: 'School' }[role] || role;
}

function formatDate(iso) {
  if (!iso) return '';
  return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
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

// ---- Permission checks ----
function canMakeAdmin(m) {
  // Only NECTA staff that are NOT admins, and not yourself
  return m.role === 'NECTA' && !m.is_admin && m.id !== user.id;
}

function canRevokeAdmin(m) {
  // Only NECTA admins, and not yourself
  return m.role === 'NECTA' && m.is_admin && m.id !== user.id;
}

function canSuspend(m) {
  return m.approval_status !== 'suspended' && m.id !== user.id;
}

function canActivate(m) {
  return m.approval_status === 'suspended';
}

async function load() {
  loading.value = true;
  try {
    const [memRes, schRes] = await Promise.allSettled([
      api.get('/members'),
      api.get('/schools/registered'),
    ]);

    const members_ = memRes.status === 'fulfilled' ? memRes.value.data : [];
    const schools_ = schRes.status === 'fulfilled'
      ? schRes.value.data.map((s) => ({
          id: s.id, email: s.email, full_name: s.full_name,
          school_name: s.school_name, role: 'SCHOOL', is_admin: false,
          approval_status: s.approval_status, created_at: s.created_at,
          last_login_at: s.last_login_at,
        }))
      : [];

    const seen = new Set();
    members.value = [...members_, ...schools_].filter((m) => {
      const key = `${m.role}-${m.id}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  } catch {
    members.value = [];
  } finally {
    loading.value = false;
  }
}

function openReminder(m) { reminderTarget.value = m; }
function onReminderSent() { reminderTarget.value = null; }
function openSuspend(m) { suspendTarget.value = m; suspendReason.value = ''; }

async function makeAdmin(m) {
  if (!confirm(`Make ${m.full_name} an admin?`)) return;
  try {
    await api.post(`/members/${m.id}/make-admin`);
    await load();
  } catch (e) {
    alert(e.response?.data?.error || 'Make admin failed');
  }
}

async function revokeAdmin(m) {
  if (!confirm(`Revoke admin privileges from ${m.full_name}?`)) return;
  try {
    await api.post(`/members/${m.id}/revoke-admin`);
    await load();
  } catch (e) {
    alert(e.response?.data?.error || 'Revoke admin failed');
  }
}

async function suspend() {
  if (!suspendTarget.value) return;
  const target = suspendTarget.value;
  try {
    const endpoint = target.role === 'SCHOOL'
      ? `/schools/${target.id}/suspend`
      : `/members/${target.id}/suspend`;
    await api.post(endpoint, { reason: suspendReason.value });
    suspendTarget.value = null;
    await load();
  } catch (e) { alert(e.response?.data?.error || 'Suspend failed'); }
}

async function activate(m) {
  try {
    const endpoint = m.role === 'SCHOOL'
      ? `/schools/${m.id}/activate`
      : `/members/${m.id}/activate`;
    await api.post(endpoint);
    await load();
  } catch (e) { alert(e.response?.data?.error || 'Activate failed'); }
}

onMounted(load);
</script>
