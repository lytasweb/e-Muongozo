<template>
<AppShell :variant="variant" page-title="Registered Schools">
      <div class="tie-page">
      <div class="tie-header">
        <div>
          <h1>Registered Schools</h1>
          <p>Schools approved by NECTA. View details, suspend, or send reminders.</p>
        </div>
        <div class="tie-header-stat">
          <div class="tie-header-stat-value">{{ items.length }}</div>
          <div class="tie-header-stat-label">Schools</div>
        </div>
      </div>

      <div v-if="items.length" class="tie-filters">
        <div class="tie-search">
          <svg viewBox="0 0 24 24" fill="none" width="18" height="18">
            <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="1.8"/>
            <path d="M20 20L17 17" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
          </svg>
          <input v-model="query" placeholder="Search school, contact, email…" />
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
        <p>No approved schools yet.</p>
      </div>

      <div v-else class="tie-grid">
        <div
          v-for="school in filtered"
          :key="school.id"
          class="tie-school-card"
        >
          <div class="tie-school-head">
            <div class="tie-school-avatar">{{ initials(school.full_name) }}</div>
            <div
              class="tie-school-status"
              :class="school.approval_status === 'suspended' ? 'tie-school-status-suspended' : ''"
            >
              {{ school.approval_status === 'suspended' ? 'Suspended' : 'Approved' }}
            </div>
          </div>
          <div class="tie-school-name">{{ school.school_name || school.full_name }}</div>
          <div class="tie-school-contact">{{ school.full_name }}</div>
          <div class="tie-school-email">{{ school.email }}</div>

          <div class="tie-school-meta">
            <div class="tie-school-meta-item">
              <svg viewBox="0 0 24 24" fill="none" width="14" height="14">
                <path d="M4 5C4 3.89543 4.89543 3 6 3H18C19.1046 3 20 3.89543 20 5V19C20 20.1046 19.1046 21 18 21H6C4.89543 21 4 20.1046 4 19V5Z" stroke="currentColor" stroke-width="1.6"/>
              </svg>
              {{ school.content_count }} guides
            </div>
            <div class="tie-school-meta-item">
              <svg viewBox="0 0 24 24" fill="none" width="14" height="14">
                <rect x="3" y="5" width="18" height="16" rx="2" stroke="currentColor" stroke-width="1.6"/>
                <path d="M8 3V7M16 3V7M3 11H21" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
              </svg>
              {{ formatDate(school.approved_at || school.created_at) }}
            </div>
          </div>

          <div class="tie-school-actions">
            <button class="force-btn force-btn-ghost force-btn-sm" @click="openDetail(school)">
              View
            </button>
            <button class="force-btn force-btn-ghost force-btn-sm" @click="openReminder(school)">
              Remind
            </button>
            <button
              v-if="school.approval_status !== 'suspended'"
              class="force-btn force-btn-sm"
              style="background:#fef2f2 !important; color:#dc2626 !important; border:1px solid #fecaca !important;"
              @click="openSuspend(school)"
            >
              Suspend
            </button>
            <button
              v-else
              class="force-btn force-btn-sm"
              style="background:#10b981 !important; color:#fff !important;"
              @click="activate(school)"
            >
              Activate
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- DETAIL MODAL -->
    <transition name="fade">
      <div v-if="detail" class="preview-modal" @click.self="closeDetail">
        <div class="preview-panel" style="max-width: 720px;">
          <div class="preview-header">
            <div class="preview-header-text">
              <div class="preview-title">{{ detail.school.school_name || detail.school.full_name }}</div>
              <div class="preview-meta">
                <span>{{ detail.school.full_name }}</span>
                <span class="preview-meta-dot">·</span>
                <span>{{ detail.school.email }}</span>
              </div>
            </div>
            <button class="preview-close" @click="closeDetail">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M6 6L18 18M6 18L18 6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
              </svg>
            </button>
          </div>

          <div class="preview-body" style="grid-template-columns: 1fr;">
            <div class="preview-content" style="padding: 20px;">
              <div v-if="detailLoading" style="padding:40px; text-align:center; color:#94a3b8;">
                Loading details…
              </div>

              <template v-else>
                <div style="margin-bottom: 24px;">
                  <div class="tie-section-title">Members ({{ detail.teachers.length }})</div>
                  <div class="tie-member-list">
                    <div v-for="t in detail.teachers" :key="t.id" class="tie-member">
                      <div class="tie-member-avatar">{{ initials(t.full_name) }}</div>
                      <div>
                        <div class="tie-member-name">{{ t.full_name }}</div>
                        <div class="tie-member-meta">{{ t.email }} · {{ t.role }}</div>
                      </div>
                    </div>
                  </div>
                </div>

                <div>
                  <div class="tie-section-title">Uploaded content ({{ detail.content.length }})</div>
                  <div v-if="detail.content.length === 0" style="padding:20px; text-align:center; color:#94a3b8; font-size:13px;">
                    No content uploaded yet.
                  </div>
                  <div v-else class="tie-content-list">
                    <div v-for="c in detail.content" :key="c.id" class="tie-content-item">
                      <div>
                        <div class="tie-content-title">{{ c.title }}</div>
                        <div class="tie-content-meta">{{ c.subject }} · {{ c.level }}</div>
                      </div>
                      <span :class="badgeClass(c.badge)">{{ c.badge }}</span>
                    </div>
                  </div>
                </div>
              </template>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- SUSPEND MODAL -->
    <transition name="fade">
      <div v-if="suspendTarget" class="preview-modal" @click.self="suspendTarget = null">
        <div class="preview-panel" style="max-width: 480px;">
          <div class="preview-header">
            <div class="preview-header-text">
              <div class="preview-title">Suspend school</div>
              <div class="preview-meta">{{ suspendTarget.school_name || suspendTarget.full_name }}</div>
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

    <!-- REMINDER MODAL -->
    <ReminderModal
      v-if="reminderTarget"
      :target="reminderTarget"
      :endpoint="`/schools/${reminderTarget.id}/remind`"
      @close="reminderTarget = null"
      @sent="reminderTarget = null"
    />
  </AppShell>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import api from '../api.js';
import AppShell from '../components/AppShell.vue';
import ReminderModal from '../components/ReminderModal.vue';

const user = JSON.parse(localStorage.getItem('user') || '{}');
const variant = computed(() => user.role || 'TIE');

const items = ref([]);
const loading = ref(true);
const query = ref('');
const detail = ref(null);
const detailLoading = ref(false);
const suspendTarget = ref(null);
const suspendReason = ref('');
const reminderTarget = ref(null);

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

function formatDate(iso) {
  if (!iso) return '';
  return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
}

function badgeClass(badge) {
  return {
    'TIE-Official': 'badge badge-tie',
    'NECTA-Official': 'badge badge-necta',
    'TIE-Reviewed': 'badge badge-reviewed',
    'Pending': 'badge badge-pending',
  }[badge] || 'badge';
}

async function load() {
  loading.value = true;
  try {
    const { data } = await api.get('/schools/registered');
    items.value = data;
  } catch {
    items.value = [];
  } finally {
    loading.value = false;
  }
}

async function openDetail(school) {
  detailLoading.value = true;
  detail.value = { school, teachers: [], content: [] };
  try {
    const { data } = await api.get(`/schools/${school.id}/teachers`);
    detail.value = data;
  } catch (e) {
    alert(e.response?.data?.error || 'Failed to load details');
    detail.value = null;
  } finally {
    detailLoading.value = false;
  }
}

function closeDetail() {
  detail.value = null;
}

function openSuspend(school) {
  suspendTarget.value = school;
  suspendReason.value = '';
}

async function suspend() {
  if (!suspendTarget.value) return;
  try {
    await api.post(`/schools/${suspendTarget.value.id}/suspend`, { reason: suspendReason.value });
    suspendTarget.value = null;
    await load();
  } catch (e) {
    alert(e.response?.data?.error || 'Suspend failed');
  }
}

async function activate(school) {
  try {
    await api.post(`/schools/${school.id}/activate`);
    await load();
  } catch (e) {
    alert(e.response?.data?.error || 'Activate failed');
  }
}

function openReminder(school) {
  reminderTarget.value = school;
}

onMounted(load);
</script>
