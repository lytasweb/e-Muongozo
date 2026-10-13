<template>
  <AppShell :variant="variant" :page-title="roleConfig.pageTitle">
    <div class="upload-page">
      <!-- HEADER -->
      <div class="upload-header">
        <div>
          <h1>{{ roleConfig.pageTitle }}</h1>
          <p>{{ roleConfig.roleHint }}</p>
        </div>
      </div>

      <!-- SOURCE SELECTOR (role-aware) -->
      <div
        class="source-tabs"
        :style="{ gridTemplateColumns: `repeat(${availableSources.length}, minmax(0, 1fr))` }"
      >
        <button
          v-for="s in availableSources"
          :key="s.id"
          class="source-tab"
          :class="{ 'source-tab-active': source === s.id }"
          @click="switchSource(s.id)"
        >
          <span class="source-tab-icon" v-html="s.icon"></span>
          <span class="source-tab-label">{{ s.label }}</span>
          <span class="source-tab-desc">{{ s.desc }}</span>
        </button>
      </div>

      <!-- ===================== MANUAL ENTRY ===================== -->
      <div v-if="source === 'manual'" class="upload-card">
        <form @submit.prevent="submitManual">
          <div class="upload-grid">
            <div class="upload-col">
              <h3 class="upload-section-title">Metadata</h3>

              <div class="form-group">
                <label>Title</label>
                <input v-model="form.title" required placeholder="e.g. Fluid Dynamics — Bernoulli's Principle" />
              </div>

              <div class="form-group">
                <label>Subject</label>
                <select v-model="form.subject" required>
                  <option value="" disabled>Choose a subject…</option>
                  <optgroup label="Sciences">
                    <option>Physics</option>
                    <option>Chemistry</option>
                    <option>Biology</option>
                    <option>General Science</option>
                  </optgroup>
                  <optgroup label="Mathematics">
                    <option>Mathematics</option>
                    <option>Basic Mathematics</option>
                    <option>Additional Mathematics</option>
                  </optgroup>
                  <optgroup label="Languages">
                    <option>Kiswahili</option>
                    <option>English</option>
                    <option>French</option>
                    <option>Arabic</option>
                  </optgroup>
                  <optgroup label="Humanities">
                    <option>Geography</option>
                    <option>History</option>
                    <option>Civics</option>
                    <option>Book Keeping</option>
                    <option>Commerce</option>
                  </optgroup>
                  <optgroup label="Technical">
                    <option>Computer Science</option>
                    <option>Agriculture</option>
                    <option>Technical Drawing</option>
                  </optgroup>
                </select>
              </div>

              <div class="grid grid-2">
                <div class="form-group">
                  <label>Level</label>
                  <select v-model="form.level" required>
                    <option value="" disabled>Choose…</option>
                    <option value="Primary">Primary</option>
                    <option value="O-Level">O-Level</option>
                    <option value="A-Level">A-Level</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>Topic</label>
                  <select v-model="form.topic" required>
                    <option value="" disabled>Choose a topic…</option>
                    <option v-for="t in topicsForSelectedSubject" :key="t">{{ t }}</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
              </div>

              <div class="form-group">
                <label>Badge preview</label>
                <div class="badge-preview">
                  <span :class="previewBadgeClass">{{ roleConfig.badge }}</span>
                  <span class="badge-preview-hint">{{ badgeHint }}</span>
                </div>
              </div>
            </div>

            <div class="upload-col">
              <h3 class="upload-section-title">
                Content
                <span class="upload-char-count">{{ form.body.length }} chars</span>
              </h3>
              <div class="form-group">
                <textarea v-model="form.body" required rows="18" placeholder="Write or paste the study guide content here…"></textarea>
              </div>
            </div>
          </div>

          <div class="upload-actions upload-actions-manual">
            <button type="submit" class="force-btn force-btn-primary" :disabled="loading">
              {{ loading ? 'Submitting…' : roleConfig.submitLabel }}
            </button>
            <button type="button" class="force-btn force-btn-ghost" @click="resetForm">Clear</button>
            <span v-if="message" class="form-msg" :class="messageType">{{ message }}</span>
          </div>
        </form>
      </div>

      <!-- ===================== FILE UPLOAD ===================== -->
      <div v-else-if="source === 'file'" class="upload-card">
        <h3 class="upload-section-title">Upload files</h3>

        <div
          class="dropzone"
          :class="{ 'dropzone-active': dragging }"
          @dragover.prevent="dragging = true"
          @dragleave.prevent="dragging = false"
          @drop.prevent="onDrop"
          @click="pickFiles"
        >
          <input ref="fileInput" type="file" multiple accept=".pdf,.doc,.docx,.txt,.md,.png,.jpg,.jpeg" @change="onFilesSelected" hidden />
          <div class="dropzone-icon">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M12 16V4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
              <path d="M7 9L12 4L17 9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
              <path d="M4 20H20" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
            </svg>
          </div>
          <div class="dropzone-title">{{ dragging ? 'Drop files here' : 'Click or drag files here' }}</div>
          <div class="dropzone-sub">PDF, DOCX, TXT, MD, PNG, JPG — up to 5 files, 10MB each</div>
        </div>

        <div v-if="queuedFiles.length" class="file-list">
          <div v-for="(f, i) in queuedFiles" :key="i" class="file-row">
            <div class="file-icon" v-html="fileIcon(f.name)"></div>
            <div class="file-meta">
              <div class="file-name">{{ f.name }}</div>
              <div class="file-size">{{ formatSize(f.size) }} · {{ f.type || 'unknown' }}</div>
            </div>
            <div class="file-progress" v-if="uploadProgress[f.name] !== undefined">
              <div class="file-progress-bar" :style="{ width: uploadProgress[f.name] + '%' }"></div>
            </div>
            <button class="file-remove" @click="removeFile(i)" title="Remove">
              <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                <path d="M6 6L18 18M6 18L18 6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
              </svg>
            </button>
          </div>
        </div>

        <div v-if="queuedFiles.length" class="upload-grid" style="margin-top:24px">
          <div class="upload-col">
            <h3 class="upload-section-title">Shared metadata</h3>

            <div class="form-group">
              <label>Subject</label>
              <select v-model="fileForm.subject" required>
                <option value="" disabled>Choose a subject…</option>
                <optgroup label="Sciences">
                  <option>Physics</option>
                  <option>Chemistry</option>
                  <option>Biology</option>
                  <option>General Science</option>
                </optgroup>
                <optgroup label="Mathematics">
                  <option>Mathematics</option>
                  <option>Basic Mathematics</option>
                  <option>Additional Mathematics</option>
                </optgroup>
                <optgroup label="Languages">
                  <option>Kiswahili</option>
                  <option>English</option>
                  <option>French</option>
                  <option>Arabic</option>
                </optgroup>
                <optgroup label="Humanities">
                  <option>Geography</option>
                  <option>History</option>
                  <option>Civics</option>
                  <option>Book Keeping</option>
                  <option>Commerce</option>
                </optgroup>
                <optgroup label="Technical">
                  <option>Computer Science</option>
                  <option>Agriculture</option>
                  <option>Technical Drawing</option>
                </optgroup>
              </select>
            </div>

            <div class="grid grid-2">
              <div class="form-group">
                <label>Level</label>
                <select v-model="fileForm.level">
                  <option value="Primary">Primary</option>
                  <option value="O-Level">O-Level</option>
                  <option value="A-Level">A-Level</option>
                </select>
              </div>
              <div class="form-group">
                <label>Topic</label>
                <select v-model="fileForm.topic">
                  <option value="">Choose a topic…</option>
                  <option v-for="t in topicsForFileSubject" :key="t">{{ t }}</option>
                  <option value="Other">Other</option>
                </select>
              </div>
            </div>

            <div class="form-group">
              <label>Notes (optional)</label>
              <textarea v-model="fileForm.notes" rows="3" placeholder="Any additional context for reviewers…"></textarea>
            </div>
          </div>

          <div class="upload-col upload-col-info">
            <div class="info-panel">
              <div class="info-panel-icon">
                <svg viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/>
                  <path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
                </svg>
              </div>
              <div>
                <div class="info-panel-title">How files become guides</div>
                <ol class="info-panel-list">
                  <li>File content is encoded and stored with the guide</li>
                  <li>PDFs and images render inline in the reader</li>
                  <li>Text files are shown as plain text</li>
                  <li>Metadata is applied and the guide enters review</li>
                </ol>
              </div>
            </div>
          </div>
        </div>

        <div v-if="queuedFiles.length" class="file-action-bar">
          <div class="file-action-info">
            <svg viewBox="0 0 24 24" fill="none" width="20" height="20">
              <path d="M6 2H14L20 8V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
              <path d="M14 2V8H20" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
            </svg>
            <span>{{ queuedFiles.length }} file{{ queuedFiles.length > 1 ? 's' : '' }} ready to upload</span>
          </div>

          <div class="file-action-buttons">
            <button type="button" class="force-btn force-btn-ghost" @click="clearFiles">Clear</button>
            <button type="button" class="force-btn force-btn-primary" :disabled="loading" @click="uploadFiles">
              <span v-if="loading" class="force-spinner"></span>
              {{ loading ? 'Uploading…' : `Upload ${queuedFiles.length} file${queuedFiles.length > 1 ? 's' : ''}` }}
            </button>
          </div>

          <div v-if="message" class="file-action-msg" :class="messageType">{{ message }}</div>
        </div>
      </div>

      <!-- ===================== CATALOG PULL ===================== -->
      <div v-else-if="source === 'catalog'" class="upload-card">
        <div class="library-head">
          <div>
            <h3 class="upload-section-title" style="margin-bottom:4px">{{ roleConfig.catalog.title }}</h3>
            <p class="library-subtitle">{{ roleConfig.catalog.subtitle }}</p>
          </div>
          <div class="library-bulk-actions">
            <button class="force-btn force-btn-ghost force-btn-sm" :disabled="selectedIds.length === 0 || loading" @click="pullSelected">
              Pull selected ({{ selectedIds.length }})
            </button>
            <button class="force-btn force-btn-primary force-btn-sm" :disabled="filteredLibraryAll.length === 0 || loading" @click="pullAll">
              Pull all ({{ filteredLibraryAll.length }})
            </button>
          </div>
        </div>

        <!-- Demo notice -->
        <div class="demo-notice">
          <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
            <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/>
            <path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
          </svg>
          <span>
            <strong>Demo catalog.</strong>
            These are sample entries. Once the {{ roleConfig.catalog.realSource }} integration is live,
            this list will fetch live records from
            <code>/api/library/{{ roleConfig.catalog.source }}</code>.
          </span>
        </div>

        <!-- Filters -->
        <div class="library-filters">
          <div class="library-search">
            <svg viewBox="0 0 24 24" fill="none" width="18" height="18">
              <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="1.8"/>
              <path d="M20 20L17 17" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
            </svg>
            <input v-model="libraryQuery" placeholder="Search by title, subject, level…" />
          </div>

          <select v-model="libraryFilterSubject" class="library-filter-select">
            <option value="">All subjects</option>
            <option v-for="s in librarySubjects" :key="s">{{ s }}</option>
          </select>

          <select v-model="libraryFilterLevel" class="library-filter-select">
            <option value="">All levels</option>
            <option>Primary</option>
            <option>O-Level</option>
            <option>A-Level</option>
          </select>

          <select v-model="libraryFilterType" class="library-filter-select">
            <option value="">All types</option>
            <option v-for="t in roleConfig.catalog.types" :key="t">{{ t }}</option>
          </select>

          <button class="library-clear" @click="clearLibraryFilters" v-if="hasLibraryFilters">Clear</button>
        </div>

        <!-- Loading -->
        <div v-if="loadingLibrary" class="library-empty">
          <div class="library-empty-title">Loading catalog…</div>
        </div>

        <template v-else>
          <div v-if="filteredLibrary.length" class="library-select-all">
            <label class="library-checkbox">
              <input type="checkbox" :checked="allSelected" @change="toggleSelectAll" />
              <span></span>
            </label>
            <span class="library-select-all-label">Select all on this page ({{ filteredLibrary.length }})</span>
          </div>

          <div v-if="filteredLibrary.length" class="library-list">
            <div
              v-for="item in filteredLibrary"
              :key="item.id"
              class="library-row"
              :class="{ 'library-row-selected': selectedIds.includes(item.id) }"
            >
              <label class="library-checkbox" @click.stop>
                <input type="checkbox" :value="item.id" v-model="selectedIds" />
                <span></span>
              </label>

              <div class="library-icon" v-html="libraryIcon(item.type)"></div>

              <div class="library-meta">
                <div class="library-title">{{ item.title }}</div>
                <div class="library-sub">{{ item.subject }} · {{ item.level }} · {{ item.type }}</div>
              </div>

              <div class="library-size">{{ item.size }}</div>

              <button type="button" class="force-btn force-btn-outline force-btn-sm" @click="openPreview(item)">
                <svg viewBox="0 0 24 24" fill="none">
                  <path d="M2 12C2 12 5 5 12 5C19 5 22 12 22 12C22 12 19 19 12 19C5 19 2 12 2 12Z" stroke="currentColor" stroke-width="1.6"/>
                  <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="1.6"/>
                </svg>
                View
              </button>

              <button
                type="button"
                class="force-btn force-btn-primary force-btn-sm"
                :disabled="pulled[item.id]"
                @click="pullItem(item)"
                style="min-width:90px;"
              >
                {{ pulled[item.id] ? '✓ Pulled' : 'Pull' }}
              </button>
            </div>
          </div>

          <div v-else class="library-empty">
            <div class="library-empty-icon">
              <svg viewBox="0 0 24 24" fill="none" width="40" height="40">
                <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="1.5"/>
                <path d="M20 20L17 17" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
              </svg>
            </div>
            <div class="library-empty-title">No matches</div>
            <div class="library-empty-text">Try adjusting your filters</div>
          </div>
        </template>

        <!-- Pagination -->
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
            Page {{ currentPage }} of {{ totalPages }} · {{ filteredLibraryAll.length }} items
          </span>
        </div>

        <transition name="fade">
          <div v-if="message" class="pull-success">
            <svg viewBox="0 0 24 24" fill="none" width="18" height="18">
              <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/>
              <path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
            {{ message }}
          </div>
        </transition>
      </div>

      <!-- ===================== SYNC ===================== -->
      <div v-else-if="source === 'sync'" class="upload-card">
        <h3 class="upload-section-title">
          {{ roleConfig.catalog.syncTitle }}
          <span class="upload-char-count">{{ roleConfig.catalog.syncSubtitle }}</span>
        </h3>

        <div class="info-panel" style="margin-bottom:24px">
          <div class="info-panel-icon info-panel-icon-warn">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M12 4L3 19H21L12 4Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
              <path d="M12 10V14M12 17H12.01" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
            </svg>
          </div>
          <div>
            <div class="info-panel-title">Demo sync</div>
            <div class="info-panel-text">
              This is a UI demonstration. In production, this tab calls the {{ roleConfig.catalog.realSource }} API directly
              and imports records with idempotent sync.
            </div>
          </div>
        </div>

        <div class="grid grid-2" style="margin-bottom:20px">
          <div class="form-group">
            <label>{{ roleConfig.catalog.syncEndpointLabel }}</label>
            <select v-model="syncForm.endpoint">
              <option v-for="e in roleConfig.catalog.syncEndpoints" :key="e.value" :value="e.value">{{ e.label }}</option>
            </select>
          </div>
          <div class="form-group">
            <label>Scope</label>
            <select v-model="syncForm.scope">
              <option value="all">All subjects</option>
              <option value="stem">STEM only</option>
              <option value="langs">Languages only</option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label>Subject filter (optional)</label>
          <select v-model="syncForm.filter">
            <option value="">All subjects</option>
            <option>Physics</option>
            <option>Chemistry</option>
            <option>Biology</option>
            <option>Mathematics</option>
            <option>Kiswahili</option>
            <option>English</option>
          </select>
        </div>

        <div class="upload-actions upload-actions-manual">
          <button type="button" class="force-btn force-btn-primary" :disabled="loading" @click="runSync">
            {{ loading ? 'Syncing…' : 'Start sync' }}
          </button>
          <button type="button" class="force-btn force-btn-ghost" @click="resetSyncForm">Reset</button>
          <span v-if="message" class="form-msg" :class="messageType">{{ message }}</span>
        </div>

        <div v-if="systemLog.length" class="system-log">
          <div class="system-log-head">Sync log (demo)</div>
          <div v-for="(line, i) in systemLog" :key="i" class="system-log-line">
            <span class="system-log-time">{{ line.time }}</span>
            <span class="system-log-text">{{ line.text }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- ===================== PREVIEW MODAL ===================== -->
    <transition name="fade">
      <div v-if="previewItem" class="preview-modal" @click.self="closePreview">
        <div class="preview-panel">
          <div class="preview-header">
            <div class="preview-header-icon preview-header-icon-syllabus">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M4 5C4 3.89543 4.89543 3 6 3H18C19.1046 3 20 3.89543 20 5V19C20 20.1046 19.1046 21 18 21H6C4.89543 21 4 20.1046 4 19V5Z" stroke="currentColor" stroke-width="1.6"/>
                <path d="M8 8H16M8 12H16M8 16H12" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
              </svg>
            </div>
            <div class="preview-header-text">
              <div class="preview-title">{{ previewItem.title }}</div>
              <div class="preview-meta">
                <span>{{ previewItem.subject }}</span>
                <span class="preview-meta-dot">·</span>
                <span>{{ previewItem.level }}</span>
                <span class="preview-meta-dot">·</span>
                <span>{{ previewItem.type }}</span>
                <span class="preview-meta-dot">·</span>
                <span>{{ previewItem.size }}</span>
              </div>
            </div>
            <button class="preview-close" @click="closePreview" aria-label="Close">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M6 6L18 18M6 18L18 6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
              </svg>
            </button>
          </div>

          <div class="preview-body">
            <aside class="preview-toc">
              <div class="preview-toc-title">Table of contents</div>
              <div class="preview-toc-list">
                <div
                  v-for="(ch, i) in previewItem.toc"
                  :key="i"
                  class="preview-toc-item"
                  :class="{ 'preview-toc-item-active': previewChapter === i }"
                  @click="previewChapter = i"
                >
                  <span class="preview-toc-num">{{ i + 1 }}</span>
                  <span class="preview-toc-name">{{ ch.title }}</span>
                  <span class="preview-toc-pages">{{ ch.pages }}p</span>
                </div>
              </div>
            </aside>

            <section class="preview-content">
              <div class="preview-chapter-header">
                <div class="preview-chapter-num">Chapter {{ previewChapter + 1 }}</div>
                <h2 class="preview-chapter-title">{{ currentChapter.title }}</h2>
                <div class="preview-chapter-pages">{{ currentChapter.pages }} pages</div>
              </div>

              <div class="preview-body-content">
                <p v-for="(p, i) in currentChapter.content" :key="i" class="preview-paragraph">
                  {{ p }}
                </p>
              </div>

              <div class="preview-chapter-nav">
                <button class="force-btn force-btn-ghost force-btn-sm" :disabled="previewChapter === 0" @click="previewChapter--">
                  ← Previous
                </button>
                <span class="preview-chapter-indicator">
                  {{ previewChapter + 1 }} / {{ previewItem.toc.length }}
                </span>
                <button class="force-btn force-btn-ghost force-btn-sm" :disabled="previewChapter === previewItem.toc.length - 1" @click="previewChapter++">
                  Next →
                </button>
              </div>
            </section>
          </div>

          <div class="preview-footer">
            <div class="preview-footer-info">
              <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/>
                <path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
              </svg>
              Preview shows sample content. Full guide is available on Pull.
            </div>
            <div class="preview-footer-actions">
              <button class="force-btn force-btn-ghost force-btn-sm" @click="closePreview">Close</button>
              <button
                class="force-btn force-btn-primary force-btn-sm"
                :disabled="pulled[previewItem.id]"
                @click="pullFromPreview"
              >
                {{ pulled[previewItem.id] ? '✓ Already pulled' : 'Pull this guide' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </AppShell>
</template>

<script setup>
import { computed, ref, watch, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import api from '../api.js';
import AppShell from '../components/AppShell.vue';
import { getRoleConfig } from '../config/roles.js';

const user = JSON.parse(localStorage.getItem('user') || '{}');
const router = useRouter();
const variant = computed(() => user.role || 'SCHOOL');
const roleConfig = computed(() => getRoleConfig(user.role));

// ============ TOPIC MAP ============
const topicsBySubject = {
  Physics: ['Mechanics', 'Thermodynamics', 'Waves', 'Electricity', 'Magnetism', 'Optics', 'Modern Physics', 'Fluid Dynamics'],
  Chemistry: ['Atomic Structure', 'Periodic Table', 'Bonding', 'Organic Chemistry', 'Acids & Bases', 'Electrochemistry', 'Kinetics'],
  Biology: ['Cell Biology', 'Genetics', 'Evolution', 'Ecology', 'Human Physiology', 'Plant Biology', 'Microbiology'],
  Mathematics: ['Algebra', 'Geometry', 'Trigonometry', 'Calculus', 'Statistics', 'Probability', 'Vectors', 'Matrices'],
  'Basic Mathematics': ['Numbers', 'Algebra', 'Geometry', 'Statistics', 'Trigonometry'],
  'Additional Mathematics': ['Calculus', 'Vectors', 'Complex Numbers', 'Matrices'],
  Kiswahili: ['Sarufi', 'Fasihi', 'Insha', 'Ufahamu', 'Utungaji'],
  English: ['Grammar', 'Comprehension', 'Composition', 'Literature'],
  French: ['Grammar', 'Vocabulary', 'Reading', 'Writing'],
  Arabic: ['Grammar', 'Vocabulary', 'Reading', 'Writing'],
  Geography: ['Physical Geography', 'Human Geography', 'Map Reading', 'Regional Geography'],
  History: ['Pre-Colonial', 'Colonial', 'Post-Independence', 'World History'],
  Civics: ['Citizenship', 'Governance', 'Human Rights', 'Civic Duties'],
  'Book Keeping': ['Ledgers', 'Trial Balance', 'Final Accounts', 'Depreciation'],
  Commerce: ['Trade', 'Business Units', 'Money & Banking', 'Marketing'],
  'Computer Science': ['Programming', 'Data Structures', 'Networks', 'Databases', 'Algorithms'],
  Agriculture: ['Crop Production', 'Animal Husbandry', 'Soil Science', 'Farm Management'],
  'Technical Drawing': ['Orthographic Projection', 'Isometric Drawing', 'Sections', 'Dimensioning'],
  'General Science': ['Matter', 'Energy', 'Life Processes', 'Earth Science'],
};

// ============ STATE ============
const form = ref({ title: '', subject: '', level: 'O-Level', topic: '', body: '' });
const fileForm = ref({ subject: '', level: 'O-Level', topic: '', notes: '' });

const loading = ref(false);
const loadingLibrary = ref(false);
const message = ref('');
const messageType = ref('success');

const topicsForSelectedSubject = computed(() => topicsBySubject[form.value.subject] || []);
const topicsForFileSubject = computed(() => topicsBySubject[fileForm.value.subject] || []);

const previewBadgeClass = computed(() => ({
  'TIE-Official': 'badge badge-tie',
  'NECTA-Official': 'badge badge-necta',
  'Pending': 'badge badge-pending',
}[roleConfig.value.badge] || 'badge'));

const badgeHint = computed(() => ({
  'TIE-Official': 'Publishes immediately',
  'NECTA-Official': 'Publishes immediately',
  'Pending': 'Goes to TIE review queue first',
}[roleConfig.value.badge] || ''));

// ============ SOURCE TABS (role-aware) ============
const availableSources = computed(() => {
  const base = [
    { id: 'manual', label: 'Manual Entry', desc: 'Type or paste directly', icon: '<svg viewBox="0 0 24 24" fill="none"><path d="M4 5C4 3.89543 4.89543 3 6 3H18C19.1046 3 20 3.89543 20 5V19C20 20.1046 19.1046 21 18 21H6C4.89543 21 4 20.1046 4 19V5Z" stroke="currentColor" stroke-width="1.6"/><path d="M8 8H16M8 12H16M8 16H12" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>' },
    { id: 'file', label: 'Upload Files', desc: 'PDF, DOCX, TXT, images', icon: '<svg viewBox="0 0 24 24" fill="none"><path d="M12 16V4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M7 9L12 4L17 9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><path d="M4 20H20" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>' },
  ];

  if (roleConfig.value.catalog.showCatalogTab) {
    base.push({
      id: 'catalog',
      label: roleConfig.value.catalog.title,
      desc: 'Pull from ' + roleConfig.value.catalog.realSource,
      icon: '<svg viewBox="0 0 24 24" fill="none"><path d="M3 21H21M5 21V7L12 3L19 7V21M9 21V15H15V21" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>',
    });
  }
  if (roleConfig.value.catalog.showSyncTab) {
    base.push({
      id: 'sync',
      label: roleConfig.value.catalog.syncTitle,
      desc: 'Sync via API',
      icon: '<svg viewBox="0 0 24 24" fill="none"><ellipse cx="12" cy="6" rx="8" ry="3" stroke="currentColor" stroke-width="1.6"/><path d="M4 6V12C4 13.6569 7.58172 15 12 15C16.4183 15 20 13.6569 20 12V6" stroke="currentColor" stroke-width="1.6"/><path d="M4 12V18C4 19.6569 7.58172 21 12 21C16.4183 21 20 19.6569 20 18V12" stroke="currentColor" stroke-width="1.6"/></svg>',
    });
  }
  return base;
});

const source = ref('manual');

function switchSource(id) {
  source.value = id;
  message.value = '';
  if (id === 'catalog') loadCatalog();
}

// ============ MANUAL SUBMIT ============
async function submitManual() {
  loading.value = true;
  message.value = '';
  try {
    await api.post('/content', form.value);
    message.value = user.role === 'SCHOOL' ? 'Submitted! Awaiting TIE review.' : 'Published successfully.';
    messageType.value = 'success';
    setTimeout(() => router.push('/my-content'), 1200);
  } catch (e) {
    message.value = e.response?.data?.error || 'Failed';
    messageType.value = 'error';
  } finally {
    loading.value = false;
  }
}

function resetForm() {
  form.value = { title: '', subject: '', level: 'O-Level', topic: '', body: '' };
  message.value = '';
}

// ============ FILE UPLOAD ============
const fileInput = ref(null);
const dragging = ref(false);
const queuedFiles = ref([]);
const uploadProgress = ref({});

function pickFiles() { fileInput.value?.click(); }

function onFilesSelected(e) {
  addFiles(Array.from(e.target.files || []));
  e.target.value = '';
}

function onDrop(e) {
  dragging.value = false;
  addFiles(Array.from(e.dataTransfer.files || []));
}

function addFiles(list) {
  const valid = list.filter((f) => f.size <= 10 * 1024 * 1024);
  queuedFiles.value = [...queuedFiles.value, ...valid].slice(0, 5);
  message.value = valid.length < list.length ? 'Some files were skipped (over 10MB)' : '';
  messageType.value = valid.length < list.length ? 'error' : 'success';
}

function removeFile(i) { queuedFiles.value.splice(i, 1); }

function clearFiles() {
  queuedFiles.value = [];
  uploadProgress.value = {};
  message.value = '';
}

function fileIcon(name) {
  const ext = name.split('.').pop().toLowerCase();
  const color = {
    pdf: '#dc2626', doc: '#2563eb', docx: '#2563eb',
    txt: '#64748b', md: '#7c3aed', png: '#0891b2',
    jpg: '#0891b2', jpeg: '#0891b2',
  }[ext] || '#64748b';
  return `<svg viewBox="0 0 24 24" fill="none" style="color:${color}"><path d="M6 2H14L20 8V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/><path d="M14 2V8H20" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>`;
}

function formatSize(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}

function readFileAsDataURL(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}

async function uploadFiles() {
  loading.value = true;
  message.value = '';
  let successCount = 0;

  for (const f of queuedFiles.value) {
    uploadProgress.value[f.name] = 5;
    try {
      const dataUrl = await readFileAsDataURL(f);
      uploadProgress.value[f.name] = 60;
      const noteText = (fileForm.value.notes || '').trim();
      const body = (noteText ? noteText + '\n\n' : '') + `[file:${f.type || 'application/octet-stream'}]${dataUrl}`;
      await api.post('/content', {
        title: f.name.replace(/\.[^.]+$/, ''),
        subject: fileForm.value.subject || 'General Science',
        level: fileForm.value.level,
        topic: fileForm.value.topic || 'Other',
        body,
      });
      uploadProgress.value[f.name] = 100;
      successCount++;
    } catch (err) {
      console.error('Upload failed for', f.name, err);
      uploadProgress.value[f.name] = 0;
    }
  }

  message.value = `${successCount} of ${queuedFiles.value.length} file${queuedFiles.value.length > 1 ? 's' : ''} uploaded.`;
  messageType.value = successCount === queuedFiles.value.length ? 'success' : 'error';

  if (successCount > 0) {
    setTimeout(() => {
      clearFiles();
      router.push('/my-content');
    }, 1600);
  }
  loading.value = false;
}

// ============ CATALOG ============
const libraryQuery = ref('');
const libraryFilterSubject = ref('');
const libraryFilterLevel = ref('');
const libraryFilterType = ref('');
const selectedIds = ref([]);
const pulled = ref({});
const catalog = ref([]);

const currentPage = ref(1);
const perPage = 10;

const previewItem = ref(null);
const previewChapter = ref(0);

async function loadCatalog() {
  loadingLibrary.value = true;
  try {
    const { data } = await api.get(`/library/${roleConfig.value.catalog.source}`);
    catalog.value = data.items || [];
  } catch (e) {
    catalog.value = [];
    console.error('Catalog load failed:', e);
  } finally {
    loadingLibrary.value = false;
  }
}

const librarySubjects = computed(() => [...new Set(catalog.value.map((i) => i.subject))].sort());

const filteredLibraryAll = computed(() => {
  const q = libraryQuery.value.trim().toLowerCase();
  return catalog.value.filter((i) => {
    if (q && ![i.title, i.subject, i.level, i.type].some((f) => String(f).toLowerCase().includes(q))) return false;
    if (libraryFilterSubject.value && i.subject !== libraryFilterSubject.value) return false;
    if (libraryFilterLevel.value && i.level !== libraryFilterLevel.value) return false;
    if (libraryFilterType.value && i.type !== libraryFilterType.value) return false;
    return true;
  });
});

const totalPages = computed(() => Math.max(1, Math.ceil(filteredLibraryAll.value.length / perPage)));

watch([libraryQuery, libraryFilterSubject, libraryFilterLevel, libraryFilterType], () => {
  currentPage.value = 1;
});

const filteredLibrary = computed(() => {
  const start = (currentPage.value - 1) * perPage;
  return filteredLibraryAll.value.slice(start, start + perPage);
});

const hasLibraryFilters = computed(() =>
  !!(libraryQuery.value || libraryFilterSubject.value || libraryFilterLevel.value || libraryFilterType.value)
);

const allSelected = computed(() =>
  filteredLibrary.value.length > 0 && filteredLibrary.value.every((i) => selectedIds.value.includes(i.id))
);

function toggleSelectAll() {
  if (allSelected.value) {
    selectedIds.value = selectedIds.value.filter((id) => !filteredLibrary.value.some((i) => i.id === id));
  } else {
    const ids = filteredLibrary.value.map((i) => i.id);
    selectedIds.value = Array.from(new Set([...selectedIds.value, ...ids]));
  }
}

function clearLibraryFilters() {
  libraryQuery.value = '';
  libraryFilterSubject.value = '';
  libraryFilterLevel.value = '';
  libraryFilterType.value = '';
}

function libraryIcon(type) {
  if (String(type).toLowerCase().includes('syllabus')) {
    return `<svg viewBox="0 0 24 24" fill="none"><path d="M4 5C4 3.89543 4.89543 3 6 3H18C19.1046 3 20 3.89543 20 5V19C20 20.1046 19.1046 21 18 21H6C4.89543 21 4 20.1046 4 19V5Z" stroke="currentColor" stroke-width="1.6"/><path d="M8 8H16M8 12H16M8 16H12" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>`;
  }
  if (String(type).toLowerCase().includes('past paper')) {
    return `<svg viewBox="0 0 24 24" fill="none"><path d="M6 2H14L20 8V20C20 21.1046 19.1046 22 18 22H6C4.89543 22 4 21.1046 4 20V4C4 2.89543 4.89543 2 6 2Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/><path d="M14 2V8H20" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>`;
  }
  return `<svg viewBox="0 0 24 24" fill="none"><path d="M4 19.5C4 18.1193 5.11929 17 6.5 17H20V2H6.5C5.11929 2 4 3.11929 4 4.5V19.5Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/><path d="M4 19.5C4 20.8807 5.11929 22 6.5 22H20" stroke="currentColor" stroke-width="1.6"/></svg>`;
}

async function pullOne(item) {
  try {
    await api.post('/content', {
      title: item.title,
      subject: item.subject,
      level: item.level,
      topic: item.type,
      body: `Pulled from ${roleConfig.value.catalog.title}: ${item.title}\n\nSource: ${item.type}\nSubject: ${item.subject}\nLevel: ${item.level}`,
    });
    pulled.value[item.id] = true;
    return true;
  } catch {
    return false;
  }
}

async function pullItem(item) {
  loading.value = true;
  const ok = await pullOne(item);
  message.value = ok ? `Pulled "${item.title}"` : 'Pull failed';
  messageType.value = ok ? 'success' : 'error';
  loading.value = false;
  setTimeout(() => (message.value = ''), 2000);
}

async function pullSelected() {
  if (!selectedIds.value.length) return;
  loading.value = true;
  const items = filteredLibraryAll.value.filter((i) => selectedIds.value.includes(i.id));
  let ok = 0;
  for (const it of items) if (await pullOne(it)) ok++;
  message.value = `Pulled ${ok} of ${items.length} items`;
  messageType.value = 'success';
  selectedIds.value = [];
  loading.value = false;
  setTimeout(() => (message.value = ''), 2500);
}

async function pullAll() {
  if (!filteredLibraryAll.value.length) return;
  loading.value = true;
  const items = [...filteredLibraryAll.value];
  let ok = 0;
  for (const it of items) if (await pullOne(it)) ok++;
  message.value = `Pulled ${ok} of ${items.length} items`;
  messageType.value = 'success';
  selectedIds.value = [];
  loading.value = false;
  setTimeout(() => (message.value = ''), 2500);
}

// ============ PREVIEW ============
const currentChapter = computed(() => {
  if (!previewItem.value) return { title: '', pages: 0, content: [] };
  return previewItem.value.toc[previewChapter.value] || { title: '', pages: 0, content: [] };
});

function openPreview(item) {
  const chapters = ['Introduction', 'Core Concepts', 'Applications', 'Summary & Review'];
  previewItem.value = {
    ...item,
    toc: chapters.map((t, i) => ({
      title: t,
      pages: 12 + i * 4,
      content: [
        `This chapter introduces learners to ${t.toLowerCase()} for ${item.level} ${item.subject}.`,
        `Key principles are illustrated with worked examples, common pitfalls, and step-by-step solutions aligned with ${roleConfig.value.catalog.realSource} standards.`,
      ],
    })),
  };
  previewChapter.value = 0;
}

function closePreview() {
  previewItem.value = null;
  previewChapter.value = 0;
}

async function pullFromPreview() {
  if (!previewItem.value) return;
  const item = previewItem.value;
  loading.value = true;
  const ok = await pullOne(item);
  message.value = ok ? `Pulled "${item.title}"` : 'Pull failed';
  messageType.value = ok ? 'success' : 'error';
  loading.value = false;
  if (ok) setTimeout(() => (message.value = ''), 2000);
}

// ============ SYNC ============
const syncForm = ref({
  endpoint: roleConfig.value.catalog.syncEndpoints[0]?.value || '',
  scope: 'all',
  filter: '',
});
const systemLog = ref([]);

function resetSyncForm() {
  syncForm.value = {
    endpoint: roleConfig.value.catalog.syncEndpoints[0]?.value || '',
    scope: 'all',
    filter: '',
  };
  systemLog.value = [];
  message.value = '';
}

async function runSync() {
  loading.value = true;
  message.value = '';
  systemLog.value = [];
  const time = () => new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });

  systemLog.value.push({ time: time(), text: `Connecting to ${roleConfig.value.catalog.realSource} ${syncForm.value.endpoint} endpoint…` });
  await new Promise((r) => setTimeout(r, 500));
  systemLog.value.push({ time: time(), text: `Authenticated. Scope: ${syncForm.value.scope}` });
  await new Promise((r) => setTimeout(r, 500));
  systemLog.value.push({ time: time(), text: 'Fetching records…' });
  await new Promise((r) => setTimeout(r, 600));
  systemLog.value.push({ time: time(), text: `Filter: ${syncForm.value.filter || 'none'}` });
  await new Promise((r) => setTimeout(r, 500));
  systemLog.value.push({ time: time(), text: 'Parsing into structured JSON…' });
  await new Promise((r) => setTimeout(r, 700));
  systemLog.value.push({ time: time(), text: 'Sync complete (demo).' });

  message.value = `${roleConfig.value.catalog.realSource} sync completed (demo).`;
  messageType.value = 'success';
  loading.value = false;
}

watch(() => form.value.subject, () => { form.value.topic = ''; });
watch(() => fileForm.value.subject, () => { fileForm.value.topic = ''; });

onMounted(() => {
  // If a role has no manual/file tabs (unlikely) default remains manual
  if (!availableSources.value.find((s) => s.id === 'manual')) {
    source.value = availableSources.value[0]?.id || 'manual';
  }
});
</script>
