<template>
  <AppShell :variant="variant" :page-title="content ? content.title : 'Reading'">
    <div class="reader-page">
      <!-- LOADING -->
      <div v-if="loading" class="reader-loading">
        <div class="reader-spinner"></div>
        <p>Loading guide…</p>
      </div>

      <!-- NOT FOUND -->
      <div v-else-if="!content" class="reader-empty">
        <div class="reader-empty-icon">
          <svg viewBox="0 0 24 24" fill="none" width="56" height="56">
            <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.5"/>
            <path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
          </svg>
        </div>
        <h2>Guide not found</h2>
        <p>The guide you're looking for doesn't exist or has been deleted.</p>
        <router-link to="/my-content" class="reader-btn reader-btn-primary">Back to My Content</router-link>
      </div>

      <!-- READER -->
      <div v-else class="reader-layout">
        <!-- LEFT SIDEBAR -->
        <aside class="reader-sidebar">
          <div class="reader-sidebar-section">
            <div class="reader-sidebar-title">Guide details</div>
            <div class="reader-detail">
              <div class="reader-detail-label">Subject</div>
              <div class="reader-detail-value">{{ content.subject }}</div>
            </div>
            <div class="reader-detail">
              <div class="reader-detail-label">Level</div>
              <div class="reader-detail-value">{{ content.level }}</div>
            </div>
            <div class="reader-detail">
              <div class="reader-detail-label">Topic</div>
              <div class="reader-detail-value">{{ content.topic }}</div>
            </div>
            <div v-if="fileKind" class="reader-detail">
              <div class="reader-detail-label">File type</div>
              <div class="reader-detail-value">{{ fileKind }}</div>
            </div>
            <div v-if="fileSize" class="reader-detail">
              <div class="reader-detail-label">File size</div>
              <div class="reader-detail-value">{{ fileSize }}</div>
            </div>
            <div class="reader-detail">
              <div class="reader-detail-label">Submitted</div>
              <div class="reader-detail-value">{{ formatDate(content.created_at) }}</div>
            </div>
          </div>

          <div v-if="!fileData && toc.length" class="reader-sidebar-section">
            <div class="reader-sidebar-title">Contents</div>
            <div class="reader-toc">
              <a
                v-for="(sec, i) in toc"
                :key="i"
                :href="`#section-${i}`"
                class="reader-toc-item"
                :class="{ 'reader-toc-item-active': activeSection === i }"
                @click.prevent="scrollToSection(i)"
              >
                <span class="reader-toc-num">{{ i + 1 }}</span>
                <span class="reader-toc-name">{{ sec.title }}</span>
              </a>
            </div>
          </div>

          <div v-if="content.review_notes" class="reader-sidebar-section">
            <div class="reader-sidebar-title">Reviewer notes</div>
            <div class="reader-note">
              <svg viewBox="0 0 24 24" fill="none" width="14" height="14">
                <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/>
                <path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
              </svg>
              <span>{{ content.review_notes }}</span>
            </div>
          </div>

          <div class="reader-sidebar-section">
            <div class="reader-sidebar-title">Actions</div>
            <div class="reader-sidebar-actions">
              <button v-if="fileData" class="reader-btn reader-btn-primary reader-btn-block" @click="downloadFile">
                <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                  <path d="M12 4V16M7 13L12 18L17 13M4 20H20" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                Download file
              </button>

              <button v-if="pdfUrl" class="reader-btn reader-btn-ghost reader-btn-block" @click="openInNewTab">
                <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                  <path d="M14 5H19V10M19 5L11 13M14 4H7C5.89543 4 5 4.89543 5 6V18C5 19.1046 5.89543 20 7 20H17C18.1046 20 19 19.1046 19 18V11" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                Open PDF in new tab
              </button>

              <router-link to="/my-content" class="reader-btn reader-btn-ghost reader-btn-block">
                <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                  <path d="M15 6L9 12L15 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                Back to My Content
              </router-link>
            </div>
          </div>
        </aside>

        <!-- RIGHT MAIN -->
        <main class="reader-main" :class="{ 'reader-main-wide': !!fileData }">
          <article class="reader-article">
            <div class="reader-hero">
              <div class="reader-hero-badge-row">
                <span :class="badgeClass(content.badge)">{{ content.badge }}</span>
                <span class="reader-status" :class="`reader-status-${content.status}`">{{ content.status }}</span>
              </div>
              <h1 class="reader-title">{{ content.title }}</h1>
              <div class="reader-subtitle">
                {{ content.subject }} · {{ content.level }} · {{ content.topic }}
              </div>
            </div>

            <!-- ============ PDF VIEWER ============ -->
            <div v-if="pdfUrl" class="reader-file-frame">
              <object :data="pdfUrl" type="application/pdf" class="reader-pdf-object">
                <div class="reader-file-download">
                  <div class="reader-file-download-icon">
                    <svg viewBox="0 0 24 24" fill="none" width="48" height="48">
                      <path d="M6 2H14L20 8V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
                      <path d="M14 2V8H20" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
                    </svg>
                  </div>
                  <div class="reader-file-download-title">Your browser can't display the PDF inline</div>
                  <div class="reader-file-download-text">
                    Use the buttons below to view or download.
                  </div>
                  <div style="display:flex; gap:10px; flex-wrap: wrap; justify-content: center;">
                    <button class="reader-btn reader-btn-primary" @click="openInNewTab">
                      Open in new tab
                    </button>
                    <button class="reader-btn reader-btn-ghost" @click="downloadFile">
                      Download
                    </button>
                  </div>
                </div>
              </object>
            </div>

            <!-- ============ IMAGE VIEWER ============ -->
            <div v-else-if="imageUrl" class="reader-file-frame">
              <img :src="imageUrl" :alt="content.title" class="reader-image" />
            </div>

            <!-- ============ TEXT FILE ============ -->
            <div v-else-if="textContent" class="reader-file-text">
              <pre>{{ textContent }}</pre>
            </div>

            <!-- ============ FILE DETECTED BUT UNSUPPORTED ============ -->
            <div v-else-if="fileData" class="reader-file-download">
              <div class="reader-file-download-icon">
                <svg viewBox="0 0 24 24" fill="none" width="48" height="48">
                  <path d="M6 2H14L20 8V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
                  <path d="M14 2V8H20" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
                </svg>
              </div>
              <div class="reader-file-download-title">{{ content.title }}</div>
              <div class="reader-file-download-text">
                This file type ({{ fileMime || 'unknown' }}) can't be previewed inline. Download it to open with a compatible app.
              </div>
              <button class="reader-btn reader-btn-primary" @click="downloadFile">
                Download file
              </button>
            </div>

            <!-- ============ FILE MARKER FOUND BUT MALFORMED ============ -->
            <div v-else-if="hasFileMarker" class="reader-file-download">
              <div class="reader-file-download-icon">
                <svg viewBox="0 0 24 24" fill="none" width="48" height="48">
                  <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.5"/>
                  <path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                </svg>
              </div>
              <div class="reader-file-download-title">File data could not be read</div>
              <div class="reader-file-download-text">
                This guide was uploaded with a file but the reader couldn't parse it. Please re-upload or contact the school.
              </div>
            </div>

            <!-- ============ PLAIN TEXT CONTENT ============ -->
            <template v-else>
              <section
                v-for="(sec, i) in sections"
                :key="i"
                :id="`section-${i}`"
                class="reader-section"
                :ref="(el) => (sectionRefs[i] = el)"
              >
                <h2 class="reader-section-title">{{ sec.title }}</h2>
                <p v-for="(p, j) in sec.paragraphs" :key="j" class="reader-paragraph">{{ p }}</p>
              </section>

              <div v-if="!sections.length" class="reader-empty-body">
                No content available.
              </div>
            </template>
          </article>

          <footer class="reader-footer">
            <div class="reader-footer-info">
              e-Muongozo · {{ formatDate(content.created_at) }}
            </div>
            <div class="reader-footer-actions">
              <router-link to="/my-content" class="reader-btn reader-btn-primary">
                Back to My Content
              </router-link>
            </div>
          </footer>
        </main>
      </div>
    </div>
  </AppShell>
</template>

<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api from '../api.js';
import AppShell from '../components/AppShell.vue';

const route = useRoute();
const router = useRouter();
const content = ref(null);
const loading = ref(true);
const activeSection = ref(0);
const sectionRefs = ref([]);

const user = JSON.parse(localStorage.getItem('user') || '{}');
const variant = computed(() => user.role || 'SCHOOL');

// ============ FILE DETECTION (robust) ============
// Format: [file:MIME]data:MIME;base64,XXXX
// Also handles: leading text, trailing whitespace, newlines inside
const fileInfo = computed(() => {
  if (!content.value?.body) return null;
  const raw = String(content.value.body);

  // Find the [file:...] marker anywhere in the body
  const markerIdx = raw.indexOf('[file:');
  if (markerIdx === -1) return null;

  // Extract the MIME type between [file: and ]
  const closeBracket = raw.indexOf(']', markerIdx);
  if (closeBracket === -1) return { mime: '', dataUrl: null, malformed: true };

  const mime = raw.slice(markerIdx + 6, closeBracket);

  // Extract the data URL (everything after the ])
  const dataUrl = raw.slice(closeBracket + 1).trim();

  // Validate it looks like a data URL
  if (!dataUrl.startsWith('data:')) {
    return { mime, dataUrl: null, malformed: true };
  }

  // Confirm there's actually base64 content after the comma
  const commaIdx = dataUrl.indexOf(',');
  if (commaIdx === -1 || commaIdx === dataUrl.length - 1) {
    return { mime, dataUrl: null, malformed: true };
  }

  return { mime, dataUrl, malformed: false };
});

const hasFileMarker = computed(() => !!fileInfo.value);
const fileData = computed(() => fileInfo.value?.dataUrl || null);
const fileMime = computed(() => fileInfo.value?.mime || '');

const fileKind = computed(() => {
  const m = fileMime.value.toLowerCase();
  if (!m) return null;
  if (m === 'application/pdf') return 'PDF';
  if (m.startsWith('image/')) return 'Image';
  if (m.startsWith('text/')) return 'Text';
  if (m.includes('word')) return 'Word document';
  if (m.includes('excel') || m.includes('spreadsheet')) return 'Spreadsheet';
  return 'File';
});

const fileSize = computed(() => {
  if (!fileData.value) return null;
  const commaIdx = fileData.value.indexOf(',');
  if (commaIdx === -1) return null;
  const b64 = fileData.value.slice(commaIdx + 1);
  // Approximate: base64 is 4/3 of the original size
  const bytes = Math.floor((b64.length * 3) / 4);
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
});

const pdfUrl = computed(() => {
  if (!fileData.value) return null;
  if (!fileMime.value.toLowerCase().includes('pdf')) return null;
  return fileData.value;
});

const imageUrl = computed(() => {
  if (!fileData.value) return null;
  if (!fileMime.value.toLowerCase().startsWith('image/')) return null;
  return fileData.value;
});

const textContent = computed(() => {
  if (!fileData.value) return null;
  const m = fileMime.value.toLowerCase();
  if (!m.startsWith('text/') && !m.includes('plain')) return null;
  try {
    const base64 = fileData.value.split(',')[1];
    return decodeURIComponent(escape(atob(base64)));
  } catch {
    return null;
  }
});

// ============ TEXT SECTIONS ============
const sections = computed(() => {
  if (!content.value?.body) return [];
  if (fileData.value || hasFileMarker.value) return [];
  const raw = String(content.value.body);
  const parts = raw.split(/\n{2,}/).map((s) => s.trim()).filter(Boolean);
  if (parts.length === 0) return [];

  const isHeading = (t) =>
    t.length < 60 && !/[.!?]$/.test(t) && !/^\d+\./.test(t);

  const built = [];
  let current = { title: 'Introduction', paragraphs: [] };

  for (const part of parts) {
    if (isHeading(part)) {
      if (current.paragraphs.length) built.push(current);
      current = { title: part, paragraphs: [] };
    } else {
      current.paragraphs.push(part);
    }
  }
  if (current.paragraphs.length) built.push(current);
  return built.length ? built : [{ title: 'Content', paragraphs: parts }];
});

const toc = computed(() => sections.value.map((s) => ({ title: s.title })));

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

function scrollToSection(i) {
  const el = sectionRefs.value[i];
  if (el) {
    const y = el.getBoundingClientRect().top + window.scrollY - 100;
    window.scrollTo({ top: y, behavior: 'smooth' });
    activeSection.value = i;
  }
}

function onScroll() {
  for (let i = sectionRefs.value.length - 1; i >= 0; i--) {
    const el = sectionRefs.value[i];
    if (!el) continue;
    const rect = el.getBoundingClientRect();
    if (rect.top <= 140) {
      activeSection.value = i;
      return;
    }
  }
  activeSection.value = 0;
}

function openInNewTab() {
  if (!fileData.value) return;
  // Convert data URL to blob, open blob in new tab
  try {
    const [header, b64] = fileData.value.split(',');
    const mime = header.match(/data:([^;]+)/)?.[1] || 'application/octet-stream';
    const binary = atob(b64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    const blob = new Blob([bytes], { type: mime });
    const blobUrl = URL.createObjectURL(blob);
    window.open(blobUrl, '_blank', 'noopener,noreferrer');
    // Revoke after a delay so the new tab can load it
    setTimeout(() => URL.revokeObjectURL(blobUrl), 60000);
  } catch (e) {
    console.error('Failed to open in new tab:', e);
    alert('Could not open file in new tab');
  }
}

function downloadFile() {
  if (!fileData.value) return;
  try {
    const [header, b64] = fileData.value.split(',');
    const mime = header.match(/data:([^;]+)/)?.[1] || 'application/octet-stream';
    const binary = atob(b64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    const blob = new Blob([bytes], { type: mime });

    // Guess a filename from the mime
    let ext = 'bin';
    if (mime.includes('pdf')) ext = 'pdf';
    else if (mime.includes('png')) ext = 'png';
    else if (mime.includes('jpeg') || mime.includes('jpg')) ext = 'jpg';
    else if (mime.includes('word')) ext = 'docx';
    else if (mime.includes('text')) ext = 'txt';

    const name = (content.value?.title || 'guide').replace(/[^a-z0-9]+/gi, '-').toLowerCase() + '.' + ext;

    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = name;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 3000);
  } catch (e) {
    console.error('Download failed:', e);
    alert('Download failed');
  }
}

onMounted(async () => {
  window.addEventListener('scroll', onScroll, { passive: true });
  try {
    const { data } = await api.get(`/content/${route.params.id}`);
    content.value = data;
    document.title = `${data.title} — e-Muongozo`;

    // Debug: log what the reader detected
    if (data.body) {
      const raw = String(data.body);
      const hasMarker = raw.includes('[file:');
      console.log('[Reader] Body length:', raw.length);
      console.log('[Reader] Has [file: marker:', hasMarker);
      if (hasMarker) {
        console.log('[Reader] First 80 chars:', raw.slice(0, 80));
        console.log('[Reader] Detected MIME:', fileMime.value);
        console.log('[Reader] Data URL starts with:', fileData.value?.slice(0, 40));
      }
    }
  } catch (err) {
    console.error('[Reader] Fetch failed:', err);
    content.value = null;
  } finally {
    loading.value = false;
    await nextTick();
    onScroll();
  }
});

onBeforeUnmount(() => {
  window.removeEventListener('scroll', onScroll);
});
</script>

<style scoped>
.reader-page { width: 100%; }

.reader-layout {
  display: grid;
  grid-template-columns: 260px 1fr;
  gap: 32px;
  align-items: flex-start;
  width: 100%;
}

.reader-sidebar {
  position: sticky;
  top: 88px;
  padding: 20px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  max-height: calc(100vh - 120px);
  overflow-y: auto;
}

.reader-sidebar-section { margin-bottom: 24px; }
.reader-sidebar-section:last-child { margin-bottom: 0; }

.reader-sidebar-title {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #94a3b8;
  margin-bottom: 12px;
}

.reader-detail {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  padding: 6px 0;
  font-size: 13px;
}
.reader-detail-label { color: #64748b; }
.reader-detail-value { color: #0f172a; font-weight: 600; text-align: right; }

.reader-toc { display: flex; flex-direction: column; gap: 2px; }
.reader-toc-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
  border-radius: 8px;
  font-size: 13px;
  color: #334155;
  text-decoration: none;
}
.reader-toc-item:hover { background: #f1f5f9; }
.reader-toc-item-active { background: #eff6ff; color: #1e40af; font-weight: 600; }
.reader-toc-num {
  width: 20px; height: 20px; border-radius: 5px;
  background: #e2e8f0; color: #475569;
  display: grid; place-items: center;
  font-size: 10px; font-weight: 700; flex-shrink: 0;
}
.reader-toc-item-active .reader-toc-num { background: #3b82f6; color: #fff; }
.reader-toc-name { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.reader-note {
  display: flex; gap: 8px; padding: 12px;
  background: #fef3c7; border-radius: 8px;
  font-size: 12px; color: #78350f; line-height: 1.5;
  align-items: flex-start;
}
.reader-note svg { flex-shrink: 0; margin-top: 2px; }

.reader-sidebar-actions { display: flex; flex-direction: column; gap: 6px; }
.reader-btn-block { width: 100%; justify-content: flex-start; }

.reader-main { padding: 0 0 40px; min-width: 0; }
.reader-main-wide { max-width: none; }

.reader-hero {
  padding-bottom: 24px;
  border-bottom: 1px solid #e2e8f0;
  margin-bottom: 24px;
}
.reader-hero-badge-row {
  display: flex; gap: 8px; align-items: center;
  margin-bottom: 16px; flex-wrap: wrap;
}
.reader-title {
  font-size: 30px; line-height: 1.2;
  letter-spacing: -0.03em; font-weight: 800;
  margin: 0 0 12px; color: #0f172a;
}
.reader-subtitle { font-size: 14px; color: #64748b; }

.reader-status {
  font-size: 10px; font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  padding: 3px 8px; border-radius: 999px;
}
.reader-status-approved { background: #d1fae5; color: #065f46; }
.reader-status-pending { background: #fef3c7; color: #92400e; }
.reader-status-rejected { background: #fee2e2; color: #991b1b; }
.reader-status-draft { background: #f1f5f9; color: #475569; }

/* PDF / IMAGE / FILE VIEWER */
.reader-file-frame {
  margin-top: 8px;
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid #e2e8f0;
  background: #f8fafc;
}

.reader-pdf-object {
  width: 100%;
  height: 82vh;
  min-height: 700px;
  border: none;
  display: block;
  background: #fff;
}

.reader-image {
  width: 100%;
  height: auto;
  display: block;
}

.reader-file-text {
  padding: 20px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  max-height: 82vh;
  overflow: auto;
}
.reader-file-text pre {
  margin: 0;
  font-family: 'JetBrains Mono', monospace;
  font-size: 13px;
  line-height: 1.6;
  color: #334155;
  white-space: pre-wrap;
  word-break: break-word;
}

.reader-file-download {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
  padding: 60px 20px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  text-align: center;
}
.reader-file-download-icon { color: #cbd5e1; }
.reader-file-download-title {
  font-size: 16px; font-weight: 700; color: #0f172a;
}
.reader-file-download-text {
  font-size: 13px; color: #64748b; max-width: 420px;
}

.reader-section { margin-bottom: 40px; scroll-margin-top: 100px; }
.reader-section-title {
  font-size: 22px; letter-spacing: -0.02em; font-weight: 700;
  color: #0f172a; margin: 0 0 16px;
  padding-bottom: 10px; border-bottom: 2px solid #eff6ff;
}
.reader-paragraph {
  font-size: 16px; line-height: 1.85;
  color: #334155; margin: 0 0 18px;
  white-space: pre-wrap;
}

.reader-empty-body {
  padding: 40px; text-align: center;
  color: #94a3b8; font-size: 14px;
}

.reader-footer {
  margin-top: 40px; padding-top: 24px;
  border-top: 1px solid #e2e8f0;
  display: flex; justify-content: space-between;
  align-items: center; gap: 16px;
  flex-wrap: wrap;
}
.reader-footer-info { font-size: 12px; color: #94a3b8; }
.reader-footer-actions { display: flex; gap: 10px; }

.reader-btn {
  display: inline-flex; align-items: center; justify-content: center;
  gap: 8px; padding: 10px 18px; border-radius: 10px;
  font-size: 13px; font-weight: 700; font-family: inherit;
  cursor: pointer; text-decoration: none;
  transition: background 0.15s, transform 0.1s, box-shadow 0.15s;
  border: none;
}
.reader-btn-primary {
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
  color: #fff; box-shadow: 0 4px 14px rgba(59, 130, 246, 0.3);
}
.reader-btn-primary:hover { transform: translateY(-1px); box-shadow: 0 8px 20px rgba(59, 130, 246, 0.4); }
.reader-btn-ghost {
  background: #fff; color: #334155;
  border: 1.5px solid #e2e8f0;
}
.reader-btn-ghost:hover { background: #f1f5f9; border-color: #cbd5e1; }

.reader-loading, .reader-empty {
  min-height: 60vh; display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  gap: 16px; color: #64748b;
}
.reader-spinner {
  width: 40px; height: 40px;
  border: 3px solid #e2e8f0;
  border-top-color: #3b82f6;
  border-radius: 50%; animation: spin 0.8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
.reader-empty-icon { color: #cbd5e1; }
.reader-empty h2 { margin: 0; font-size: 22px; color: #0f172a; }
.reader-empty p { margin: 0; color: #64748b; font-size: 14px; }

@media (max-width: 1100px) {
  .reader-layout { grid-template-columns: 220px 1fr; gap: 24px; }
}
@media (max-width: 900px) {
  .reader-layout { grid-template-columns: 1fr; gap: 16px; }
  .reader-sidebar { position: static; max-height: none; }
  .reader-title { font-size: 24px; }
  .reader-section-title { font-size: 18px; }
  .reader-paragraph { font-size: 15px; }
  .reader-pdf-object { height: 70vh; min-height: 500px; }
}
@media (max-width: 480px) {
  .reader-title { font-size: 22px; }
  .reader-pdf-object { height: 60vh; min-height: 400px; }
}
@media print {
  .reader-sidebar, .reader-footer { display: none !important; }
  .reader-layout { grid-template-columns: 1fr; max-width: none; }
  .reader-main { padding: 0; max-width: none; }
  .reader-page { background: #fff; }
}
</style>
