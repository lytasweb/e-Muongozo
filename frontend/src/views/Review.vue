<template>
  <AppShell variant="REVIEWER" page-title="Review Queue">
    <div class="rv-page">
      <!-- HEADER -->
      <div class="rv-header">
        <div>
          <h1>Review Queue</h1>
          <p>Top School submissions awaiting TIE review. Approve to give a TIE-Reviewed badge, or reject with notes.</p>
        </div>
      </div>

      <!-- STATS STRIP -->
      <div v-if="items.length" class="rv-stats">
        <div class="rv-stat">
          <div class="rv-stat-icon rv-stat-icon-pending">
            <svg viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/>
              <path d="M12 7V12L15 15" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
            </svg>
          </div>
          <div>
            <div class="rv-stat-value">{{ items.length }}</div>
            <div class="rv-stat-label">Pending</div>
          </div>
        </div>

        <div class="rv-stat">
          <div class="rv-stat-icon rv-stat-icon-oldest">
            <svg viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/>
              <path d="M12 8V12L15 15" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
            </svg>
          </div>
          <div>
            <div class="rv-stat-value">{{ oldestDays }}d</div>
            <div class="rv-stat-label">Oldest</div>
          </div>
        </div>

        <div class="rv-stat">
          <div class="rv-stat-icon rv-stat-icon-today">
            <svg viewBox="0 0 24 24" fill="none">
              <rect x="3" y="5" width="18" height="16" rx="2" stroke="currentColor" stroke-width="1.6"/>
              <path d="M8 3V7M16 3V7M3 11H21" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
            </svg>
          </div>
          <div>
            <div class="rv-stat-value">{{ todayCount }}</div>
            <div class="rv-stat-label">Today</div>
          </div>
        </div>

        <div class="rv-stat">
          <div class="rv-stat-icon rv-stat-icon-school">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M4 20H20M4 20V8L12 4L20 8V20M4 20H9M20 20H15" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
              <rect x="9" y="12" width="6" height="8" stroke="currentColor" stroke-width="1.6"/>
            </svg>
          </div>
          <div>
            <div class="rv-stat-value">{{ uniqueSchools }}</div>
            <div class="rv-stat-label">Schools</div>
          </div>
        </div>
      </div>

      <!-- FILTERS -->
      <div v-if="items.length" class="rv-filters">
        <div class="rv-search">
          <svg viewBox="0 0 24 24" fill="none" width="18" height="18">
            <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="1.8"/>
            <path d="M20 20L17 17" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
          </svg>
          <input v-model="query" placeholder="Search title, subject, school…" />
        </div>

        <select v-model="filterSubject" class="rv-filter-select">
          <option value="">All subjects</option>
          <option v-for="s in subjects" :key="s">{{ s }}</option>
        </select>

        <select v-model="filterLevel" class="rv-filter-select">
          <option value="">All levels</option>
          <option>Primary</option>
          <option>O-Level</option>
          <option>A-Level</option>
        </select>

        <select v-model="filterSchool" class="rv-filter-select">
          <option value="">All schools</option>
          <option v-for="s in schools" :key="s">{{ s }}</option>
        </select>

        <button v-if="hasFilters" class="library-clear" @click="clearFilters">Clear</button>
      </div>

      <!-- BULK ACTION BAR -->
      <div v-if="selectedIds.length" class="rv-bulk">
        <div class="rv-bulk-info">
          <label class="library-checkbox">
            <input type="checkbox" :checked="allSelected" @change="toggleSelectAll" />
            <span></span>
          </label>
          <span><strong>{{ selectedIds.length }}</strong> item{{ selectedIds.length > 1 ? 's' : '' }} selected</span>
        </div>
        <div class="rv-bulk-actions">
          <button class="force-btn force-btn-ghost force-btn-sm" @click="selectedIds = []">Cancel</button>
          <button
            class="force-btn force-btn-sm"
            style="background:#dc2626 !important; color:#fff !important;"
            @click="bulkReject"
          >
            Reject selected
          </button>
          <button
            class="force-btn force-btn-sm"
            style="background:#10b981 !important; color:#fff !important;"
            @click="bulkApprove"
          >
            Approve selected
          </button>
        </div>
      </div>

      <!-- SELECT-ALL ROW -->
      <div v-if="filteredAll.length && !selectedIds.length" class="rv-select-all-row">
        <label class="library-checkbox">
          <input type="checkbox" :checked="false" @change="toggleSelectAll" />
          <span></span>
        </label>
        <span class="rv-select-all-hint">Select all on this page</span>
      </div>

      <!-- EMPTY STATES -->
      <div v-if="items.length === 0" class="empty-state">
        <div class="empty-icon">
          <svg viewBox="0 0 24 24" fill="none" width="56" height="56">
            <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.2"/>
            <path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
        <p>All clear — no pending submissions.</p>
      </div>

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
      <div v-else class="rv-grid">
        <div
          v-for="item in paginatedItems"
          :key="item.id"
          class="rv-card"
          :class="{ 'rv-card-selected': selectedIds.includes(item.id) }"
        >
          <label class="rv-card-checkbox library-checkbox" @click.stop>
            <input type="checkbox" :value="item.id" v-model="selectedIds" />
            <span></span>
          </label>

          <div class="rv-card-head">
            <span class="badge badge-pending">PENDING</span>
            <span class="rv-card-age" :class="ageClass(item.created_at)">
              {{ relativeTime(item.created_at) }}
            </span>
          </div>

          <div class="rv-card-title">{{ item.title }}</div>
          <div class="rv-card-meta">
            <span>{{ item.subject }}</span>
            <span class="mc-dot">·</span>
            <span>{{ item.level }}</span>
            <span class="mc-dot">·</span>
            <span>{{ item.topic }}</span>
          </div>

          <!-- School badge -->
          <div class="rv-card-school">
            <svg viewBox="0 0 24 24" fill="none" width="12" height="12">
              <path d="M4 20H20M4 20V8L12 4L20 8V20M4 20H9M20 20H15" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
            <span>{{ item.school_name || item.author_name }}</span>
          </div>

          <!-- File badge -->
          <div v-if="hasFile(item)" class="rv-card-file-badge">
            <svg viewBox="0 0 24 24" fill="none" width="12" height="12">
              <path d="M6 2H14L20 8V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
              <path d="M14 2V8H20" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
            </svg>
            {{ fileKind(item) }} attached
          </div>

          <!-- Body preview (clean) -->
          <div v-if="cleanPreview(item)" class="rv-card-body">{{ cleanPreview(item) }}</div>

          <!-- Reviewer notes input -->
          <div class="rv-card-notes-input">
            <label>Reviewer notes (optional)</label>
            <input v-model="notes[item.id]" placeholder="e.g. Aligned with TIE syllabus 2024" />
          </div>

          <!-- Card footer: actions -->
          <div class="rv-card-footer">
            <div class="rv-card-actions-left">
              <button
                class="rv-icon-btn"
                @click="openInNewTab(item)"
                title="Read in new tab"
              >
                <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                  <path d="M14 5H19V10M19 5L11 13M14 4H7C5.89543 4 5 4.89543 5 6V18C5 19.1046 5.89543 20 7 20H17C18.1046 20 19 19.1046 19 18V11" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </button>
              <button
                class="rv-icon-btn"
                @click="openPreview(item)"
                title="Quick preview"
              >
                <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                  <path d="M2 12C2 12 5 5 12 5C19 5 22 12 22 12C22 12 19 19 12 19C5 19 2 12 2 12Z" stroke="currentColor" stroke-width="1.7"/>
                  <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="1.7"/>
                </svg>
              </button>
            </div>

            <div class="rv-card-actions-right">
              <button class="force-btn force-btn-sm rv-btn-reject" @click="decide(item.id, 'reject')">
                <svg viewBox="0 0 24 24" fill="none" width="14" height="14">
                  <path d="M6 6L18 18M6 18L18 6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                </svg>
                Reject
              </button>
              <button class="force-btn force-btn-sm rv-btn-approve" @click="decide(item.id, 'approve')">
                <svg viewBox="0 0 24 24" fill="none" width="14" height="14">
                  <path d="M5 13L9 17L19 7" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                Approve
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

    <!-- PREVIEW MODAL -->
    <transition name="fade">
      <div v-if="previewItem" class="preview-modal" @click.self="closePreview">
        <div class="preview-panel">
          <div class="preview-header">
            <div class="preview-header-icon preview-header-icon-pending">
              <svg viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/>
                <path d="M12 7V12L15 15" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
              </svg>
            </div>
            <div class="preview-header-text">
              <div class="preview-title">{{ previewItem.title }}</div>
              <div class="preview-meta">
                <span>{{ previewItem.subject }}</span>
                <span class="preview-meta-dot">·</span>
                <span>{{ previewItem.level }}</span>
                <span class="preview-meta-dot">·</span>
                <span>{{ previewItem.topic }}</span>
              </div>
            </div>
            <button class="preview-close" @click="closePreview" aria-label="Close">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M6 6L18 18M6 18L18 6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
              </svg>
            </button>
          </div>

          <div class="preview-body">
            <div class="preview-content">
              <div class="preview-chapter-header">
                <div class="preview-chapter-num">
                  <span class="badge badge-pending">PENDING</span>
                </div>
                <div class="preview-chapter-pages">
                  From <strong>{{ previewItem.school_name || previewItem.author_name }}</strong>
                  · Submitted {{ relativeTime(previewItem.created_at) }}
                </div>
              </div>

              <div class="preview-body-content">
                <p v-for="(p, i) in previewParagraphs" :key="i" class="preview-paragraph">{{ p }}</p>

                <div v-if="hasFile(previewItem)" class="preview-file-notice">
                  <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                    <path d="M6 2H14L20 8V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
                    <path d="M14 2V8H20" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
                  </svg>
                  <span><strong>{{ fileKind(previewItem) }}</strong> attached. Open in a new tab to view the full file.</span>
                </div>
              </div>
            </div>
          </div>

          <div class="preview-footer">
            <div class="preview-footer-info">
              <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/>
                <path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
              </svg>
              Quick preview. Open in a new tab to read the full guide.
            </div>
            <div class="preview-footer-actions">
              <button class="force-btn force-btn-ghost force-btn-sm" @click="closePreview">Close</button>
              <button class="force-btn force-btn-outline force-btn-sm" @click="openInNewTab(previewItem); closePreview()">
                Open full view
              </button>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </AppShell>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import api from '../api.js';
import AppShell from '../components/AppShell.vue';

const router = useRouter();
const items = ref([]);
const notes = reactive({});

// Filters
const query = ref('');
const filterSubject = ref('');
const filterLevel = ref('');
const filterSchool = ref('');

// Pagination
const currentPage = ref(1);
const perPage = 10;

// Selection
const selectedIds = ref([]);

// Preview
const previewItem = ref(null);

// ============ DERIVED ============
const subjects = computed(() => [...new Set(items.value.map((i) => i.subject))].sort());
const schools = computed(() => [...new Set(items.value.map((i) => i.school_name || i.author_name).filter(Boolean))].sort());

const hasFilters = computed(() =>
  !!(query.value || filterSubject.value || filterLevel.value || filterSchool.value)
);

const oldestDays = computed(() => {
  if (!items.value.length) return 0;
  const oldest = items.value.reduce((min, i) => {
    const d = new Date(i.created_at).getTime();
    return d < min ? d : min;
  }, Date.now());
  return Math.max(1, Math.floor((Date.now() - oldest) / (1000 * 60 * 60 * 24)));
});

const todayCount = computed(() => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return items.value.filter((i) => new Date(i.created_at) >= today).length;
});

const uniqueSchools = computed(() => new Set(items.value.map((i) => i.school_name || i.author_name).filter(Boolean)).size);

const filteredAll = computed(() => {
  const q = query.value.trim().toLowerCase();
  return items.value.filter((i) => {
    if (q && ![i.title, i.subject, i.topic, i.school_name, i.author_name].some((f) => String(f || '').toLowerCase().includes(q))) return false;
    if (filterSubject.value && i.subject !== filterSubject.value) return false;
    if (filterLevel.value && i.level !== filterLevel.value) return false;
    if (filterSchool.value && (i.school_name || i.author_name) !== filterSchool.value) return false;
    return true;
  });
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredAll.value.length / perPage)));

const paginatedItems = computed(() => {
  const start = (currentPage.value - 1) * perPage;
  return filteredAll.value.slice(start, start + perPage);
});

const allSelected = computed(() =>
  paginatedItems.value.length > 0 && paginatedItems.value.every((i) => selectedIds.value.includes(i.id))
);

const previewParagraphs = computed(() => {
  if (!previewItem.value) return [];
  let s = String(previewItem.value.body || '');
  s = s.replace(/\[file:[^\]]+\]data:[^\s]+/g, '').trim();
  return s.split(/\n{2,}/).map((p) => p.trim()).filter(Boolean);
});

// ============ WATCHERS ============
watch([query, filterSubject, filterLevel, filterSchool], () => {
  currentPage.value = 1;
  selectedIds.value = [];
});

// ============ HELPERS ============
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

function cleanPreview(item) {
  let s = String(item.body || '');
  s = s.replace(/\[file:[^\]]+\]data:[^\s]+/g, '');
  s = s.replace(/\s+/g, ' ').trim();
  if (!s) return '';
  return s.length > 160 ? s.slice(0, 160) + '…' : s;
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

function ageClass(iso) {
  const diff = (Date.now() - new Date(iso).getTime()) / (1000 * 60 * 60 * 24);
  if (diff < 1) return 'rv-card-age-fresh';
  if (diff < 3) return 'rv-card-age-warn';
  return 'rv-card-age-old';
}

function clearFilters() {
  query.value = '';
  filterSubject.value = '';
  filterLevel.value = '';
  filterSchool.value = '';
}

function toggleSelectAll() {
  if (allSelected.value) {
    selectedIds.value = selectedIds.value.filter((id) => !paginatedItems.value.some((i) => i.id === id));
  } else {
    const ids = paginatedItems.value.map((i) => i.id);
    selectedIds.value = Array.from(new Set([...selectedIds.value, ...ids]));
  }
}

function openInNewTab(item) {
  const resolved = router.resolve({ path: `/read/${item.id}` });
  const url = window.location.origin + window.location.pathname + '#' + resolved.href.split('#').slice(-1)[0];
  window.open(url, '_blank', 'noopener,noreferrer');
}

function openPreview(item) {
  previewItem.value = item;
}

function closePreview() {
  previewItem.value = null;
}

// ============ ACTIONS ============
async function load() {
  try {
    const { data } = await api.get('/review/pending');
    items.value = data;
  } catch {
    items.value = [];
  }
}

async function decide(id, action) {
  try {
    await api.post(`/review/${id}`, { action, notes: notes[id] || '' });
    selectedIds.value = selectedIds.value.filter((x) => x !== id);
    await load();
  } catch (e) {
    alert(e.response?.data?.error || 'Action failed');
  }
}

async function bulkApprove() {
  if (!selectedIds.value.length) return;
  if (!confirm(`Approve ${selectedIds.value.length} item${selectedIds.value.length > 1 ? 's' : ''}?`)) return;
  const ids = [...selectedIds.value];
  for (const id of ids) {
    try { await api.post(`/review/${id}`, { action: 'approve', notes: notes[id] || '' }); } catch {}
  }
  selectedIds.value = [];
  await load();
}

async function bulkReject() {
  if (!selectedIds.value.length) return;
  if (!confirm(`Reject ${selectedIds.value.length} item${selectedIds.value.length > 1 ? 's' : ''}?`)) return;
  const ids = [...selectedIds.value];
  for (const id of ids) {
    try { await api.post(`/review/${id}`, { action: 'reject', notes: notes[id] || '' }); } catch {}
  }
  selectedIds.value = [];
  await load();
}

onMounted(load);
</script>

<style scoped>
.rv-page { width: 100%; }

.rv-header {
  margin-bottom: 20px;
}
.rv-header h1 { margin: 0 0 4px; font-size: 22px; letter-spacing: -0.02em; }
.rv-header p { margin: 0; color: #64748b; font-size: 13px; }

/* ============================================================
   STATS
   ============================================================ */
.rv-stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
  margin-bottom: 20px;
}
.rv-stat {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  min-width: 0;
}
.rv-stat-icon {
  width: 44px;
  height: 44px;
  border-radius: 11px;
  display: grid;
  place-items: center;
  flex-shrink: 0;
}
.rv-stat-icon svg { width: 20px; height: 20px; }
.rv-stat-icon-pending { background: #fef3c7; color: #d97706; }
.rv-stat-icon-oldest { background: #fee2e2; color: #dc2626; }
.rv-stat-icon-today { background: #d1fae5; color: #059669; }
.rv-stat-icon-school { background: #e0e7ff; color: #4f46e5; }

.rv-stat-value { font-size: 20px; font-weight: 700; letter-spacing: -0.02em; }
.rv-stat-label {
  font-size: 11px; color: #64748b; text-transform: uppercase;
  letter-spacing: 0.06em; font-weight: 600;
}

/* ============================================================
   FILTERS
   ============================================================ */
.rv-filters {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr auto;
  gap: 8px;
  align-items: center;
  margin-bottom: 16px;
}
.rv-search {
  position: relative;
  display: flex;
  align-items: center;
  color: #64748b;
  min-width: 0;
}
.rv-search svg { position: absolute; left: 12px; pointer-events: none; }
.rv-search input {
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
.rv-search input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59,130,246,0.12);
}
.rv-filter-select {
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

/* ============================================================
   BULK
   ============================================================ */
.rv-bulk {
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
.rv-bulk-info {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  color: #1e40af;
}
.rv-bulk-actions { display: flex; gap: 8px; flex-wrap: wrap; }

.rv-select-all-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 4px 14px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 16px;
}
.rv-select-all-hint { font-size: 12px; color: #64748b; font-weight: 500; }

/* ============================================================
   GRID + CARD
   ============================================================ */
.rv-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 16px;
  width: 100%;
}

.rv-card {
  position: relative;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 18px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-width: 0;
  max-width: 100%;
  overflow: hidden;
  transition: border-color 0.15s, box-shadow 0.15s, transform 0.15s;
}
.rv-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 8px 24px rgba(15,23,42,0.06);
  transform: translateY(-2px);
}
.rv-card-selected {
  border-color: #3b82f6;
  background: #eff6ff;
}

.rv-card-checkbox {
  position: absolute;
  top: 12px;
  left: 12px;
  opacity: 0;
  transition: opacity 0.15s;
  z-index: 2;
}
.rv-card:hover .rv-card-checkbox,
.rv-card-selected .rv-card-checkbox {
  opacity: 1;
}

.rv-card-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.rv-card-age {
  font-size: 11px;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 999px;
}
.rv-card-age-fresh { background: #d1fae5; color: #065f46; }
.rv-card-age-warn { background: #fef3c7; color: #92400e; }
.rv-card-age-old { background: #fee2e2; color: #991b1b; }

.rv-card-title {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
  line-height: 1.35;
  letter-spacing: -0.01em;
  word-break: break-word;
  overflow-wrap: anywhere;
}

.rv-card-meta {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #64748b;
  flex-wrap: wrap;
}

.rv-card-school {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  background: #f1f5f9;
  color: #334155;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 700;
  align-self: flex-start;
}
.rv-card-school svg { color: #64748b; }

.rv-card-file-badge {
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

.rv-card-body {
  font-size: 13px;
  color: #475569;
  line-height: 1.55;
  word-break: break-word;
  overflow-wrap: anywhere;
}

.rv-card-notes-input label {
  display: block;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: #64748b;
  margin-bottom: 6px;
}
.rv-card-notes-input input {
  width: 100%;
  padding: 9px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  font-size: 13px;
  font-family: inherit;
  background: #fff;
  color: #0f172a;
  box-sizing: border-box;
}
.rv-card-notes-input input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59,130,246,0.12);
}

.rv-card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
  padding-top: 12px;
  margin-top: auto;
  border-top: 1px solid #f1f5f9;
  flex-wrap: wrap;
}

.rv-card-actions-left {
  display: flex;
  gap: 6px;
}
.rv-icon-btn {
  width: 34px;
  height: 34px;
  border-radius: 8px;
  background: #fff;
  border: 1px solid #e2e8f0;
  color: #64748b;
  cursor: pointer;
  display: grid;
  place-items: center;
  transition: background 0.15s, color 0.15s, border-color 0.15s;
}
.rv-icon-btn:hover {
  background: #eff6ff;
  color: #3b82f6;
  border-color: #bfdbfe;
}

.rv-card-actions-right {
  display: flex;
  gap: 8px;
}

.rv-btn-reject {
  background: #fef2f2 !important;
  color: #dc2626 !important;
  border: 1px solid #fecaca !important;
}
.rv-btn-reject:hover:not(:disabled) {
  background: #fee2e2 !important;
  border-color: #fca5a5 !important;
}

.rv-btn-approve {
  background: #10b981 !important;
  color: #fff !important;
  border: none !important;
  box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3) !important;
}
.rv-btn-approve:hover:not(:disabled) {
  background: #059669 !important;
  box-shadow: 0 8px 20px rgba(16, 185, 129, 0.4) !important;
}

/* ============================================================
   PREVIEW MODAL
   ============================================================ */
.preview-header-icon-pending {
  background: linear-gradient(135deg, #f59e0b, #d97706);
}
.preview-file-notice {
  display: flex;
  gap: 10px;
  align-items: flex-start;
  padding: 14px 16px;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 10px;
  margin-top: 16px;
  font-size: 13px;
  color: #1e40af;
  line-height: 1.5;
}
.preview-file-notice svg { flex-shrink: 0; margin-top: 2px; color: #2563eb; }

/* ============================================================
   RESPONSIVE
   ============================================================ */
@media (max-width: 1100px) {
  .rv-stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .rv-filters { grid-template-columns: 1fr 1fr 1fr; }
}
@media (max-width: 900px) {
  .rv-grid { grid-template-columns: 1fr; }
  .rv-filters { grid-template-columns: 1fr; }
  .rv-card-checkbox { opacity: 1; }
}
@media (max-width: 600px) {
  .rv-stats { grid-template-columns: repeat(2, 1fr); gap: 10px; }
  .rv-card-footer { flex-direction: column; align-items: stretch; }
  .rv-card-actions-left { justify-content: flex-start; }
  .rv-card-actions-right { display: flex; }
  .rv-card-actions-right .force-btn { flex: 1; justify-content: center; }
}
@media (max-width: 400px) {
  .rv-stats { grid-template-columns: 1fr; }
}
</style>
