<template>
  <AppShell :variant="variant" page-title="My Content">
    <div class="mc-page">
      <!-- HEADER -->
      <div class="mc-header">
        <div>
          <h1>My Content</h1>
          <p>All content you have submitted, with its current status.</p>
        </div>
        <router-link to="/upload" class="force-btn force-btn-primary">
          <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
            <path d="M12 5V19M5 12H19" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
          </svg>
          Upload New
        </router-link>
      </div>

      <!-- STATS STRIP -->
      <div v-if="items.length" class="mc-stats">
        <div class="mc-stat">
          <div class="mc-stat-icon mc-stat-icon-total">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M3 7C3 5.89543 3.89543 5 5 5H9L11 7H19C20.1046 7 21 7.89543 21 9V19C21 20.1046 20.1046 21 19 21H5C3.89543 21 3 20.1046 3 19V7Z" stroke="currentColor" stroke-width="1.6"/>
            </svg>
          </div>
          <div>
            <div class="mc-stat-value">{{ items.length }}</div>
            <div class="mc-stat-label">Total</div>
          </div>
        </div>

        <div class="mc-stat">
          <div class="mc-stat-icon mc-stat-icon-approved">
            <svg viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/>
              <path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
          <div>
            <div class="mc-stat-value">{{ counts.approved }}</div>
            <div class="mc-stat-label">Approved</div>
          </div>
        </div>

        <div class="mc-stat">
          <div class="mc-stat-icon mc-stat-icon-pending">
            <svg viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/>
              <path d="M12 7V12L15 15" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
            </svg>
          </div>
          <div>
            <div class="mc-stat-value">{{ counts.pending }}</div>
            <div class="mc-stat-label">Pending</div>
          </div>
        </div>

        <div class="mc-stat">
          <div class="mc-stat-icon mc-stat-icon-rejected">
            <svg viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/>
              <path d="M9 9L15 15M15 9L9 15" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
            </svg>
          </div>
          <div>
            <div class="mc-stat-value">{{ counts.rejected }}</div>
            <div class="mc-stat-label">Rejected</div>
          </div>
        </div>
      </div>

      <!-- FILTER BAR -->
      <div v-if="items.length" class="mc-filters">
        <div class="mc-search">
          <svg viewBox="0 0 24 24" fill="none" width="18" height="18">
            <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="1.8"/>
            <path d="M20 20L17 17" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
          </svg>
          <input v-model="query" placeholder="Search title, subject, topic…" />
        </div>

        <select v-model="filterStatus" class="mc-filter-select">
          <option value="">All statuses</option>
          <option value="approved">Approved</option>
          <option value="pending">Pending</option>
          <option value="rejected">Rejected</option>
          <option value="draft">Draft</option>
        </select>

        <select v-model="filterSubject" class="mc-filter-select">
          <option value="">All subjects</option>
          <option v-for="s in subjects" :key="s">{{ s }}</option>
        </select>

        <select v-model="filterLevel" class="mc-filter-select">
          <option value="">All levels</option>
          <option>Primary</option>
          <option>O-Level</option>
          <option>A-Level</option>
        </select>

        <select v-model="sortBy" class="mc-filter-select">
          <option value="newest">Newest first</option>
          <option value="oldest">Oldest first</option>
          <option value="title">Title (A–Z)</option>
        </select>

        <button v-if="hasFilters" class="library-clear" @click="clearFilters">Clear</button>
      </div>

      <!-- BULK ACTION BAR -->
      <div v-if="selectedIds.length" class="mc-bulk">
        <div class="mc-bulk-info">
          <label class="library-checkbox">
            <input type="checkbox" :checked="allSelected" @change="toggleSelectAll" />
            <span></span>
          </label>
          <span><strong>{{ selectedIds.length }}</strong> item{{ selectedIds.length > 1 ? 's' : '' }} selected</span>
        </div>
        <div class="mc-bulk-actions">
          <button class="force-btn force-btn-ghost force-btn-sm" @click="selectedIds = []">Cancel</button>
          <button
            class="force-btn force-btn-sm"
            style="background:#dc2626 !important; color:#fff !important; box-shadow:0 6px 18px rgba(220,38,38,0.35) !important;"
            @click="deleteSelected"
          >
            Delete selected
          </button>
        </div>
      </div>

      <!-- SELECT-ALL ROW -->
      <div v-if="filteredAll.length && !selectedIds.length" class="mc-select-all-row">
        <label class="library-checkbox">
          <input type="checkbox" :checked="false" @change="toggleSelectAll" />
          <span></span>
        </label>
        <span class="mc-select-all-hint">Select all on this page</span>
      </div>

      <!-- EMPTY STATES -->
      <div v-if="items.length === 0" class="empty-state">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" width="56" height="56">
            <path d="M3 7C3 5.89543 3.89543 5 5 5H9L11 7H19C20.1046 7 21 7.89543 21 9V19C21 20.1046 20.1046 21 19 21H5C3.89543 21 3 20.1046 3 19V7Z" stroke="currentColor" stroke-width="1.2"/>
          </svg>
        </div>
        <p style="margin-bottom:16px">You haven't uploaded any content yet.</p>
        <router-link to="/upload" class="force-btn force-btn-primary">
          <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
            <path d="M12 5V19M5 12H19" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
          </svg>
          Upload your first guide
        </router-link>
      </div>

      <!-- NO MATCHES -->
      <div v-else-if="filteredAll.length === 0" class="empty-state">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" width="56" height="56">
            <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="1.5"/>
            <path d="M20 20L17 17" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
          </svg>
        </div>
        <p>No matches for your filters.</p>
        <button class="force-btn force-btn-ghost" style="margin-top:12px" @click="clearFilters">Clear filters</button>
      </div>

      <!-- CONTENT GRID -->
      <div v-else class="mc-grid">
        <div
          v-for="item in paginatedItems"
          :key="item.id"
          class="mc-card"
          :class="{ 'mc-card-selected': selectedIds.includes(item.id) }"
        >
          <label class="mc-card-checkbox library-checkbox" @click.stop>
            <input type="checkbox" :value="item.id" v-model="selectedIds" />
            <span></span>
          </label>

          <div class="mc-card-head">
            <span :class="badgeClass(item.badge)">{{ item.badge }}</span>
            <span class="mc-card-status" :class="`mc-card-status-${item.status}`">{{ item.status }}</span>
          </div>

          <div class="mc-card-title">{{ item.title }}</div>
          <div class="mc-card-meta">
            <span>{{ item.subject }}</span>
            <span class="mc-dot">·</span>
            <span>{{ item.level }}</span>
            <span class="mc-dot">·</span>
            <span>{{ item.topic }}</span>
          </div>

          <!-- Body preview — clean of base64 -->
          <div v-if="hasFile(item)" class="mc-card-file-badge">
            <svg viewBox="0 0 24 24" fill="none" width="12" height="12">
              <path d="M6 2H14L20 8V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
              <path d="M14 2V8H20" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
            </svg>
            {{ fileKind(item) }} attached
          </div>

          <div v-if="cleanPreview(item)" class="mc-card-body">{{ cleanPreview(item) }}</div>

          <div v-if="item.review_notes" class="mc-card-notes">
            <svg viewBox="0 0 24 24" fill="none" width="14" height="14">
              <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/>
              <path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
            </svg>
            <div>
              <strong>Reviewer notes:</strong> {{ item.review_notes }}
            </div>
          </div>

          <div class="mc-card-footer">
            <div class="mc-card-date">
              <svg viewBox="0 0 24 24" fill="none" width="12" height="12">
                <rect x="3" y="5" width="18" height="16" rx="2" stroke="currentColor" stroke-width="1.6"/>
                <path d="M8 3V7M16 3V7M3 11H21" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
              </svg>
              {{ formatDate(item.created_at) }}
            </div>
            <div class="mc-card-actions">
              <button class="mc-icon-btn" @click="openInNewTab(item)" title="Read in new tab">
                <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                  <path d="M14 5H19V10M19 5L11 13M14 4H7C5.89543 4 5 4.89543 5 6V18C5 19.1046 5.89543 20 7 20H17C18.1046 20 19 19.1046 19 18V11" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </button>
              <button class="mc-icon-btn mc-icon-btn-danger" @click="remove(item.id)" title="Delete">
                <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                  <path d="M4 7H20M10 11V17M14 11V17M5 7L6 20C6 20.5523 6.44772 21 7 21H17C17.5523 21 18 20.5523 18 20L19 7M9 7V4C9 3.44772 9.44772 3 10 3H14C14.5523 3 15 3.44772 15 4V7" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- PAGINATION -->
      <div v-if="totalPages > 1" class="pagination">
        <button class="pagination-btn" :disabled="currentPage === 1" @click="currentPage--">
          <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
            <path d="M15 6L9 12L15 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          Prev
        </button>

        <div class="pagination-pages">
          <button
            v-for="p in totalPages"
            :key="p"
            class="pagination-page"
            :class="{ 'pagination-page-active': p === currentPage }"
            @click="currentPage = p"
          >
            {{ p }}
          </button>
        </div>

        <button class="pagination-btn" :disabled="currentPage === totalPages" @click="currentPage++">
          Next
          <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
            <path d="M9 6L15 12L9 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>

        <span class="pagination-info">
          Page {{ currentPage }} of {{ totalPages }} · {{ filteredAll.length }} items
        </span>
      </div>
    </div>
  </AppShell>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import api from '../api.js';
import AppShell from '../components/AppShell.vue';

const router = useRouter();
const user = JSON.parse(localStorage.getItem('user') || '{}');
const variant = computed(() => user.role || 'SCHOOL');

const items = ref([]);

// Filters
const query = ref('');
const filterStatus = ref('');
const filterSubject = ref('');
const filterLevel = ref('');
const sortBy = ref('newest');

// Pagination
const currentPage = ref(1);
const perPage = 10;

// Selection
const selectedIds = ref([]);

// Derived
const subjects = computed(() => [...new Set(items.value.map((i) => i.subject))].sort());

const hasFilters = computed(() =>
  !!(query.value || filterStatus.value || filterSubject.value || filterLevel.value || sortBy.value !== 'newest')
);

const counts = computed(() => ({
  approved: items.value.filter((i) => i.status === 'approved').length,
  pending: items.value.filter((i) => i.status === 'pending').length,
  rejected: items.value.filter((i) => i.status === 'rejected').length,
}));

const filteredAll = computed(() => {
  const q = query.value.trim().toLowerCase();
  let list = items.value.filter((i) => {
    if (q && ![i.title, i.subject, i.topic, i.body].some((f) => String(f || '').toLowerCase().includes(q))) return false;
    if (filterStatus.value && i.status !== filterStatus.value) return false;
    if (filterSubject.value && i.subject !== filterSubject.value) return false;
    if (filterLevel.value && i.level !== filterLevel.value) return false;
    return true;
  });

  if (sortBy.value === 'newest') {
    list = [...list].sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  } else if (sortBy.value === 'oldest') {
    list = [...list].sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
  } else if (sortBy.value === 'title') {
    list = [...list].sort((a, b) => String(a.title).localeCompare(String(b.title)));
  }

  return list;
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredAll.value.length / perPage)));

const paginatedItems = computed(() => {
  const start = (currentPage.value - 1) * perPage;
  return filteredAll.value.slice(start, start + perPage);
});

const allSelected = computed(() =>
  paginatedItems.value.length > 0 && paginatedItems.value.every((i) => selectedIds.value.includes(i.id))
);

watch([query, filterStatus, filterSubject, filterLevel, sortBy], () => {
  currentPage.value = 1;
  selectedIds.value = [];
});

function clearFilters() {
  query.value = '';
  filterStatus.value = '';
  filterSubject.value = '';
  filterLevel.value = '';
  sortBy.value = 'newest';
}

function toggleSelectAll() {
  if (allSelected.value) {
    selectedIds.value = selectedIds.value.filter((id) => !paginatedItems.value.some((i) => i.id === id));
  } else {
    const ids = paginatedItems.value.map((i) => i.id);
    selectedIds.value = Array.from(new Set([...selectedIds.value, ...ids]));
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

// Detect if body has an embedded file (base64)
function hasFile(item) {
  return /\[file:[^\]]+\]data:/.test(String(item.body || ''));
}

function fileKind(item) {
  const match = String(item.body || '').match(/\[file:([^\]]+)\]/);
  if (!match) return 'File';
  const mime = match[1];
  if (mime === 'application/pdf') return 'PDF';
  if (mime.startsWith('image/')) return 'Image';
  if (mime.startsWith('text/')) return 'Text';
  if (mime.includes('word')) return 'Word doc';
  return 'File';
}

// Strip file data and produce a clean preview
function cleanPreview(item) {
  let s = String(item.body || '');
  // Remove any "[file:mime]data:....." fragments
  s = s.replace(/\[file:[^\]]+\]data:[^\s]+/g, '');
  // Collapse whitespace
  s = s.replace(/\s+/g, ' ').trim();
  if (!s) return '';
  return s.length > 140 ? s.slice(0, 140) + '…' : s;
}

function formatDate(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
}

// Open content in a new browser tab using the full-page reader
function openInNewTab(item) {
  const resolved = router.resolve({ path: `/read/${item.id}` });
  const url = window.location.origin + window.location.pathname + '#' + resolved.href.split('#').slice(-1)[0];
  window.open(url, '_blank', 'noopener,noreferrer');
}

async function load() {
  try {
    const { data } = await api.get('/content');
    items.value = data;
  } catch {
    items.value = [];
  }
}

async function remove(id) {
  if (!confirm('Delete this content?')) return;
  try {
    await api.delete(`/content/${id}`);
    selectedIds.value = selectedIds.value.filter((x) => x !== id);
    await load();
  } catch (e) {
    alert(e.response?.data?.error || 'Delete failed');
  }
}

async function deleteSelected() {
  if (!selectedIds.value.length) return;
  if (!confirm(`Delete ${selectedIds.value.length} item${selectedIds.value.length > 1 ? 's' : ''}?`)) return;
  const ids = [...selectedIds.value];
  for (const id of ids) {
    try { await api.delete(`/content/${id}`); } catch {}
  }
  selectedIds.value = [];
  await load();
}

onMounted(load);
</script>

<style scoped>
.mc-page {
  width: 100%;
  max-width: 100%;
}

/* ============================================================
   HEADER
   ============================================================ */

.mc-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 24px;
  flex-wrap: wrap;
}
.mc-header h1 { margin: 0 0 4px; font-size: 22px; letter-spacing: -0.02em; }
.mc-header p { margin: 0; color: #64748b; font-size: 13px; }

/* ============================================================
   STATS
   ============================================================ */

.mc-stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
  margin-bottom: 20px;
  width: 100%;
}
.mc-stat {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  min-width: 0;
}
.mc-stat-icon {
  width: 44px;
  height: 44px;
  border-radius: 11px;
  display: grid;
  place-items: center;
  flex-shrink: 0;
}
.mc-stat-icon svg { width: 20px; height: 20px; }
.mc-stat-icon-total { background: #e0e7ff; color: #4f46e5; }
.mc-stat-icon-approved { background: #d1fae5; color: #059669; }
.mc-stat-icon-pending { background: #fef3c7; color: #d97706; }
.mc-stat-icon-rejected { background: #fee2e2; color: #dc2626; }

.mc-stat-value { font-size: 20px; font-weight: 700; letter-spacing: -0.02em; }
.mc-stat-label {
  font-size: 11px;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  font-weight: 600;
}

/* ============================================================
   FILTERS
   ============================================================ */

.mc-filters {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr 1fr auto;
  gap: 8px;
  align-items: center;
  margin-bottom: 16px;
  width: 100%;
}
.mc-search {
  position: relative;
  display: flex;
  align-items: center;
  color: #64748b;
  min-width: 0;
}
.mc-search svg { position: absolute; left: 12px; pointer-events: none; }
.mc-search input {
  width: 100%;
  padding: 9px 12px 9px 38px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13px;
  font-family: inherit;
  background: #fff;
  color: #0f172a;
  box-sizing: border-box;
}
.mc-search input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59,130,246,0.12);
}
.mc-filter-select {
  padding: 9px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13px;
  font-family: inherit;
  background: #fff;
  color: #0f172a;
  cursor: pointer;
  min-width: 0;
  width: 100%;
}
.mc-filter-select:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59,130,246,0.12);
}

/* ============================================================
   BULK / SELECT-ALL
   ============================================================ */

.mc-bulk {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 12px 16px;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 10px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}
.mc-bulk-info {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  color: #1e40af;
}
.mc-bulk-actions { display: flex; gap: 8px; flex-wrap: wrap; }

.mc-select-all-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 4px 14px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 16px;
}
.mc-select-all-hint { font-size: 12px; color: #64748b; font-weight: 500; }

/* ============================================================
   GRID
   ============================================================ */

.mc-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 16px;
  width: 100%;
}

/* ============================================================
   CARD
   ============================================================ */

.mc-card {
  position: relative;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 18px;
  transition: border-color 0.15s, box-shadow 0.15s, transform 0.15s;
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-width: 0;
  max-width: 100%;
  overflow: hidden;
}
.mc-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 8px 24px rgba(15,23,42,0.06);
  transform: translateY(-2px);
}
.mc-card-selected {
  border-color: #3b82f6;
  background: #eff6ff;
}

.mc-card-checkbox {
  position: absolute;
  top: 12px;
  left: 12px;
  opacity: 0;
  transition: opacity 0.15s;
  z-index: 2;
}
.mc-card:hover .mc-card-checkbox,
.mc-card-selected .mc-card-checkbox {
  opacity: 1;
}

.mc-card-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.mc-card-status {
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  padding: 3px 8px;
  border-radius: 999px;
}
.mc-card-status-approved { background: #d1fae5; color: #065f46; }
.mc-card-status-pending { background: #fef3c7; color: #92400e; }
.mc-card-status-rejected { background: #fee2e2; color: #991b1b; }
.mc-card-status-draft { background: #f1f5f9; color: #475569; }

.mc-card-title {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
  line-height: 1.35;
  letter-spacing: -0.01em;
  word-break: break-word;
  overflow-wrap: anywhere;
}

.mc-card-meta {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #64748b;
  flex-wrap: wrap;
  word-break: break-word;
}
.mc-dot { color: #cbd5e1; }

.mc-card-body {
  font-size: 13px;
  color: #475569;
  line-height: 1.55;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  word-break: break-word;
  overflow-wrap: anywhere;
}

.mc-card-file-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  background: #eff6ff;
  color: #1e40af;
  border: 1px solid #bfdbfe;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 700;
  align-self: flex-start;
}

.mc-card-notes {
  display: flex;
  gap: 8px;
  padding: 10px 12px;
  background: #fef3c7;
  border-radius: 8px;
  font-size: 12px;
  color: #78350f;
  line-height: 1.5;
  align-items: flex-start;
  word-break: break-word;
}
.mc-card-notes svg { flex-shrink: 0; margin-top: 2px; }
.mc-card-notes strong { color: #78350f; }

.mc-card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 12px;
  margin-top: auto;
  border-top: 1px solid #f1f5f9;
  gap: 8px;
  flex-wrap: wrap;
}
.mc-card-date {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: #94a3b8;
}

.mc-card-actions { display: flex; gap: 6px; }
.mc-icon-btn {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: #fff;
  border: 1px solid #e2e8f0;
  color: #64748b;
  cursor: pointer;
  display: grid;
  place-items: center;
  transition: background 0.15s, color 0.15s, border-color 0.15s;
}
.mc-icon-btn:hover {
  background: #eff6ff;
  color: #3b82f6;
  border-color: #bfdbfe;
}
.mc-icon-btn-danger:hover {
  background: #fef2f2;
  color: #dc2626;
  border-color: #fecaca;
}

/* ============================================================
   RESPONSIVE
   ============================================================ */

/* Tablet */
@media (max-width: 1100px) {
  .mc-filters {
    grid-template-columns: 1fr 1fr 1fr;
  }
  .mc-stats {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

/* Large phone / small tablet */
@media (max-width: 700px) {
  .mc-header {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }
  .mc-header .force-btn {
    width: 100%;
    justify-content: center;
  }
  .mc-filters {
    grid-template-columns: 1fr;
  }
  .mc-stats {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 10px;
  }
  .mc-grid {
    grid-template-columns: 1fr;
    gap: 12px;
  }
  .mc-card-checkbox { opacity: 1; }
  .mc-bulk {
    flex-direction: column;
    align-items: stretch;
  }
  .mc-bulk-actions .force-btn { flex: 1; }
}

/* Phones */
@media (max-width: 480px) {
  .mc-stats {
    grid-template-columns: 1fr;
    gap: 10px;
  }
  .mc-stat { padding: 12px; }
  .mc-stat-icon { width: 38px; height: 38px; }
  .mc-stat-value { font-size: 18px; }
  .mc-card { padding: 14px; }
  .mc-card-title { font-size: 14px; }
  .mc-card-body { font-size: 12px; }
  .mc-card-footer {
    flex-direction: column;
    align-items: stretch;
    gap: 10px;
  }
  .mc-card-actions { justify-content: flex-end; }
}
</style>
