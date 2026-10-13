
<template>
  <AppShell :variant="variant" page-title="My Profile">
    <div class="profile-page">
      <!-- HERO -->
      <div class="profile-hero">
        <div class="profile-hero-avatar">{{ initials }}</div>
        <div class="profile-hero-info">
          <h1>{{ user.full_name }}</h1>
          <p>{{ user.email }}</p>
          <div class="profile-hero-badges">
            <span class="profile-hero-badge">{{ roleLabel }}</span>
            <span v-if="twoFactorEnabled" class="profile-hero-badge profile-hero-badge-success">
              <svg viewBox="0 0 24 24" fill="none" width="12" height="12">
                <path d="M12 2L3 7V12C3 17.55 6.84 22.74 12 24C17.16 22.74 21 17.55 21 12V7L12 2Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
                <path d="M9 12L11 14L15 10" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
              2FA Enabled
            </span>
            <span v-else class="profile-hero-badge profile-hero-badge-warn">
              <svg viewBox="0 0 24 24" fill="none" width="12" height="12">
                <path d="M12 4L3 19H21L12 4Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
                <path d="M12 10V14M12 17H12.01" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
              </svg>
              2FA Off
            </span>
          </div>
        </div>
        <div class="profile-hero-stats">
          <div class="profile-hero-stat">
            <div class="profile-hero-stat-value">{{ totalContent }}</div>
            <div class="profile-hero-stat-label">Guides</div>
          </div>
          <div class="profile-hero-stat">
            <div class="profile-hero-stat-value">{{ joinedDays }}</div>
            <div class="profile-hero-stat-label">Days active</div>
          </div>
        </div>
      </div>

      <!-- TABS -->
      <div class="profile-tabs">
        <button
          v-for="t in tabs"
          :key="t.id"
          class="profile-tab"
          :class="{ 'profile-tab-active': activeTab === t.id }"
          @click="activeTab = t.id"
        >
          <span class="profile-tab-icon" v-html="t.icon"></span>
          {{ t.label }}
        </button>
      </div>

      <!-- ===================== TAB: Personal Info ===================== -->
      <div v-if="activeTab === 'info'" class="profile-grid">
        <div class="profile-card">
          <h2>Personal Information</h2>

          <div class="profile-form">
            <div class="form-group">
              <label>Full name</label>
              <input v-model="form.full_name" placeholder="Your full name" />
            </div>

            <div class="form-group">
              <label>Email</label>
              <input v-model="form.email" type="email" disabled />
              <span class="form-hint">Email cannot be changed.</span>
            </div>

            <div v-if="user.role === 'SCHOOL'" class="form-group">
              <label>School name</label>
              <input v-model="form.school_name" placeholder="Your school" />
            </div>

            <div class="form-group">
              <label>Phone</label>
              <input v-model="form.phone" type="tel" placeholder="+255 7xx xxx xxx" />
            </div>

            <div class="form-group">
              <label>Role</label>
              <input :value="roleLabel" disabled />
            </div>

            <div class="profile-actions">
              <button class="force-btn force-btn-primary" :disabled="saving" @click="saveInfo">
                {{ saving ? 'Saving…' : 'Save changes' }}
              </button>
              <span v-if="infoMsg" class="form-msg" :class="infoMsgType">{{ infoMsg }}</span>
            </div>
          </div>
        </div>

        <!-- Side: account meta -->
        <div class="profile-side">
          <div class="profile-card">
            <h2>Account</h2>
            <div class="profile-meta-row">
              <div class="profile-meta-label">User ID</div>
              <div class="profile-meta-value">#{{ user.id || '—' }}</div>
            </div>
            <div class="profile-meta-row">
              <div class="profile-meta-label">Role</div>
              <div class="profile-meta-value">{{ roleLabel }}</div>
            </div>
            <div class="profile-meta-row">
              <div class="profile-meta-label">Status</div>
              <div class="profile-meta-value">
                <span class="profile-pill profile-pill-success">Active</span>
              </div>
            </div>
          </div>

          <div class="profile-card">
            <h2>Danger zone</h2>
            <p class="profile-side-text">
              Deleting your account removes all uploaded content permanently.
            </p>
            <button
              class="force-btn"
              style="background:#fef2f2 !important; color:#dc2626 !important; border:1px solid #fecaca !important;"
              @click="confirmDelete"
            >
              <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                <path d="M4 7H20M10 11V17M14 11V17M5 7L6 20C6 20.5523 6.44772 21 7 21H17C17.5523 21 18 20.5523 18 20L19 7M9 7V4C9 3.44772 9.44772 3 10 3H14C14.5523 3 15 3.44772 15 4V7" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
              Request account deletion
            </button>
          </div>
        </div>
      </div>

      <!-- ===================== TAB: Security ===================== -->
      <div v-else-if="activeTab === 'security'" class="profile-grid">
        <div class="profile-card">
          <h2>Change password</h2>

          <div class="profile-form">
            <div class="form-group">
              <label>Current password</label>
              <input v-model="pwd.current" type="password" placeholder="Enter current password" />
            </div>

            <div class="form-group">
              <label>New password</label>
              <input v-model="pwd.next" type="password" placeholder="At least 6 characters" />
            </div>

            <div class="form-group">
              <label>Confirm new password</label>
              <input v-model="pwd.confirm" type="password" placeholder="Repeat new password" />
            </div>

            <div class="profile-actions">
              <button class="force-btn force-btn-primary" :disabled="savingPwd" @click="savePassword">
                {{ savingPwd ? 'Updating…' : 'Update password' }}
              </button>
              <span v-if="pwdMsg" class="form-msg" :class="pwdMsgType">{{ pwdMsg }}</span>
            </div>
          </div>
        </div>

        <div class="profile-side">
          <div class="profile-card">
            <h2>Two-factor authentication</h2>

            <div class="profile-2fa" :class="{ 'profile-2fa-on': twoFactorEnabled }">
              <div class="profile-2fa-icon">
                <svg v-if="twoFactorEnabled" viewBox="0 0 24 24" fill="none" width="28" height="28">
                  <path d="M12 2L3 7V12C3 17.55 6.84 22.74 12 24C17.16 22.74 21 17.55 21 12V7L12 2Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
                  <path d="M9 12L11 14L15 10" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                <svg v-else viewBox="0 0 24 24" fill="none" width="28" height="28">
                  <path d="M12 2L3 7V12C3 17.55 6.84 22.74 12 24C17.16 22.74 21 17.55 21 12V7L12 2Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>
                </svg>
              </div>
              <div>
                <div class="profile-2fa-title">
                  {{ twoFactorEnabled ? 'Enabled' : 'Disabled' }}
                </div>
                <div class="profile-2fa-text">
                  {{ twoFactorEnabled
                    ? 'A 6-character code is required every time you sign in.'
                    : 'Add an extra layer of security to your account.' }}
                </div>
              </div>
            </div>

            <div class="profile-2fa-method">
              <div class="profile-2fa-method-label">Method</div>
              <div class="profile-2fa-method-value">
                <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                  <rect x="3" y="5" width="18" height="14" rx="2" stroke="currentColor" stroke-width="1.6"/>
                  <path d="M3 7L12 13L21 7" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                Email OTP to <strong>{{ maskedEmail }}</strong>
              </div>
            </div>

            <div class="profile-actions">
              <button
                v-if="!twoFactorEnabled"
                class="force-btn force-btn-primary"
                :disabled="toggling2fa"
                @click="enable2fa"
              >
                {{ toggling2fa ? 'Enabling…' : 'Enable 2FA' }}
              </button>
              <button
                v-else
                class="force-btn"
                style="background:#fef2f2 !important; color:#dc2626 !important; border:1px solid #fecaca !important;"
                :disabled="toggling2fa"
                @click="disable2fa"
              >
                {{ toggling2fa ? 'Disabling…' : 'Disable 2FA' }}
              </button>
            </div>

            <div v-if="twoFactorMsg" class="profile-2fa-msg" :class="twoFactorMsgType">
              {{ twoFactorMsg }}
            </div>
          </div>

          <div class="profile-card">
            <h2>Active sessions</h2>
            <div class="profile-session">
              <div class="profile-session-icon">
                <svg viewBox="0 0 24 24" fill="none" width="20" height="20">
                  <rect x="3" y="4" width="18" height="14" rx="2" stroke="currentColor" stroke-width="1.6"/>
                  <path d="M8 20H16" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
                </svg>
              </div>
              <div class="profile-session-info">
                <div class="profile-session-name">This browser</div>
                <div class="profile-session-meta">Current session · Active now</div>
              </div>
              <span class="profile-pill profile-pill-success">Current</span>
            </div>
          </div>
        </div>
      </div>

      <!-- ===================== TAB: Preferences ===================== -->
      <div v-else-if="activeTab === 'preferences'" class="profile-grid">
        <div class="profile-card">
          <h2>Notification preferences</h2>

          <div class="profile-toggle">
            <div>
              <div class="profile-toggle-title">Email me when content is approved</div>
              <div class="profile-toggle-text">Get notified the moment TIE reviews your guide.</div>
            </div>
            <label class="switch">
              <input type="checkbox" v-model="prefs.emailOnApproval" />
              <span class="switch-slider"></span>
            </label>
          </div>

          <div class="profile-toggle">
            <div>
              <div class="profile-toggle-title">Email me when content is rejected</div>
              <div class="profile-toggle-text">Includes the reviewer's notes.</div>
            </div>
            <label class="switch">
              <input type="checkbox" v-model="prefs.emailOnRejection" />
              <span class="switch-slider"></span>
            </label>
          </div>

          <div class="profile-toggle">
            <div>
              <div class="profile-toggle-title">Weekly digest</div>
              <div class="profile-toggle-text">A summary of new guides and reports.</div>
            </div>
            <label class="switch">
              <input type="checkbox" v-model="prefs.weeklyDigest" />
              <span class="switch-slider"></span>
            </label>
          </div>

          <div class="profile-toggle">
            <div>
              <div class="profile-toggle-title">System announcements</div>
              <div class="profile-toggle-text">Occasional product updates and news.</div>
            </div>
            <label class="switch">
              <input type="checkbox" v-model="prefs.systemAnnouncements" />
              <span class="switch-slider"></span>
            </label>
          </div>

          <div class="profile-actions">
            <button class="force-btn force-btn-primary" :disabled="savingPrefs" @click="savePreferences">
              {{ savingPrefs ? 'Saving…' : 'Save preferences' }}
            </button>
            <span v-if="prefsMsg" class="form-msg" :class="prefsMsgType">{{ prefsMsg }}</span>
          </div>
        </div>

        <div class="profile-side">
          <div class="profile-card">
            <h2>Language</h2>
            <div class="profile-form">
              <div class="form-group">
                <label>Preferred language</label>
                <select v-model="prefs.language">
                  <option value="sw">Kiswahili</option>
                  <option value="en">English</option>
                </select>
              </div>
            </div>
          </div>

          <div class="profile-card">
            <h2>Appearance</h2>
            <div class="profile-form">
              <div class="form-group">
                <label>Theme</label>
                <select v-model="prefs.theme">
                  <option value="auto">System default</option>
                  <option value="light">Light</option>
                  <option value="dark">Dark</option>
                </select>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- ===================== TAB: Activity ===================== -->
      <div v-else-if="activeTab === 'activity'" class="profile-card">
        <h2>Recent Activity</h2>

        <div v-if="activities.length === 0" class="profile-empty">
          No recent activity yet.
        </div>

        <div v-else class="profile-activity-list">
          <div v-for="a in activities" :key="a.id" class="profile-activity">
            <div class="profile-activity-icon" v-html="activityIcon(a.type)"></div>
            <div class="profile-activity-body">
              <div class="profile-activity-text">{{ a.text }}</div>
              <div class="profile-activity-time">{{ formatDate(a.created_at) }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </AppShell>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import api from '../api.js';
import AppShell from '../components/AppShell.vue';

const stored = JSON.parse(localStorage.getItem('user') || '{}');
const user = ref({ ...stored });
const variant = computed(() => user.value.role || 'SCHOOL');

const roleLabel = computed(() => ({
  TIE: 'TIE Contributor',
  NECTA: 'NECTA Contributor',
  SCHOOL: 'School Contributor',
  REVIEWER: 'TIE Reviewer',
}[user.value.role] || ''));

const initials = computed(() => {
  const full = (user.value.full_name || '').trim();
  if (!full) return '?';
  const parts = full.split(/\s+/);
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
});

const maskedEmail = computed(() => {
  const email = user.value.email || '';
  const [name, domain] = email.split('@');
  if (!name || !domain) return email;
  const masked = name.length > 2
    ? name[0] + '*'.repeat(Math.min(4, name.length - 2)) + name[name.length - 1]
    : '*'.repeat(name.length);
  return `${masked}@${domain}`;
});

const tabs = [
  { id: 'info', label: 'Personal Info', icon: `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.6"/><path d="M4 21V19C4 16.7909 5.79086 15 8 15H16C18.2091 15 20 16.7909 20 19V21" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>` },
  { id: 'security', label: 'Security', icon: `<svg viewBox="0 0 24 24" fill="none"><path d="M12 2L3 7V12C3 17.55 6.84 22.74 12 24C17.16 22.74 21 17.55 21 12V7L12 2Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>` },
  { id: 'preferences', label: 'Preferences', icon: `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="1.6"/><path d="M19 12C19 12.9 19.1 13.8 19.4 14.6L21 16L19.6 17.4L18.2 16.4C17.5 17 16.8 17.5 16 17.8L16.3 19.7L14.4 20L14 18.1C13.3 18.2 12.7 18.2 12 18.1L11.6 20L9.7 19.7L10 17.8C9.2 17.5 8.5 17 7.8 16.4L6.4 17.4L5 16L6.6 14.6C6.9 13.8 7 12.9 7 12C7 11.1 6.9 10.2 6.6 9.4L5 8L6.4 6.6L7.8 7.6C8.5 7 9.2 6.5 10 6.2L9.7 4.3L11.6 4L12 5.9C12.7 5.8 13.3 5.8 14 5.9L14.4 4L16.3 4.3L16 6.2C16.8 6.5 17.5 7 18.2 7.6L19.6 6.6L21 8L19.4 9.4C19.1 10.2 19 11.1 19 12Z" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>` },
  { id: 'activity', label: 'Activity', icon: `<svg viewBox="0 0 24 24" fill="none"><path d="M4 20V10M10 20V4M16 20V14M22 20H2" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>` },
];
const activeTab = ref('info');

// ===== Info form (city + bio removed) =====
const form = ref({
  full_name: user.value.full_name || '',
  email: user.value.email || '',
  school_name: user.value.school_name || '',
  phone: '',
});

const saving = ref(false);
const infoMsg = ref('');
const infoMsgType = ref('success');

// ===== Password form =====
const pwd = ref({ current: '', next: '', confirm: '' });
const savingPwd = ref(false);
const pwdMsg = ref('');
const pwdMsgType = ref('success');

// ===== 2FA =====
const twoFactorEnabled = ref(false);
const toggling2fa = ref(false);
const twoFactorMsg = ref('');
const twoFactorMsgType = ref('success');

// ===== Preferences =====
const prefs = ref({
  emailOnApproval: true,
  emailOnRejection: true,
  weeklyDigest: false,
  systemAnnouncements: true,
  language: 'en',
  theme: 'auto',
});
const savingPrefs = ref(false);
const prefsMsg = ref('');
const prefsMsgType = ref('success');

// ===== Activity =====
const activities = ref([]);
const totalContent = ref(0);

const joinedDays = computed(() => {
  if (!activities.value.length) return 0;
  const earliest = activities.value.reduce((min, a) => {
    const d = new Date(a.created_at).getTime();
    return d < min ? d : min;
  }, Date.now());
  return Math.max(1, Math.floor((Date.now() - earliest) / (1000 * 60 * 60 * 24)));
});

async function saveInfo() {
  saving.value = true;
  infoMsg.value = '';
  try {
    const { data } = await api.put('/auth/profile', {
      full_name: form.value.full_name,
      school_name: form.value.school_name,
    });
    user.value = { ...user.value, ...data };
    localStorage.setItem('user', JSON.stringify(user.value));
    infoMsg.value = 'Profile updated';
    infoMsgType.value = 'success';
  } catch (e) {
    infoMsg.value = e.response?.data?.error || 'Update failed';
    infoMsgType.value = 'error';
  } finally {
    saving.value = false;
    setTimeout(() => (infoMsg.value = ''), 2500);
  }
}

async function savePassword() {
  if (!pwd.value.current || !pwd.value.next) {
    pwdMsg.value = 'Fill all fields';
    pwdMsgType.value = 'error';
    return;
  }
  if (pwd.value.next !== pwd.value.confirm) {
    pwdMsg.value = 'Passwords do not match';
    pwdMsgType.value = 'error';
    return;
  }
  if (pwd.value.next.length < 6) {
    pwdMsg.value = 'Password must be at least 6 characters';
    pwdMsgType.value = 'error';
    return;
  }

  savingPwd.value = true;
  pwdMsg.value = '';
  try {
    await api.put('/auth/password', {
      current_password: pwd.value.current,
      new_password: pwd.value.next,
    });
    pwd.value = { current: '', next: '', confirm: '' };
    pwdMsg.value = 'Password updated';
    pwdMsgType.value = 'success';
  } catch (e) {
    pwdMsg.value = e.response?.data?.error || 'Update failed';
    pwdMsgType.value = 'error';
  } finally {
    savingPwd.value = false;
    setTimeout(() => (pwdMsg.value = ''), 2500);
  }
}

async function enable2fa() {
  toggling2fa.value = true;
  twoFactorMsg.value = '';
  setTimeout(() => {
    twoFactorEnabled.value = true;
    localStorage.setItem('twoFactorEnabled', 'true');
    twoFactorMsg.value = 'Two-factor authentication enabled';
    twoFactorMsgType.value = 'success';
    toggling2fa.value = false;
    setTimeout(() => (twoFactorMsg.value = ''), 2500);
  }, 700);
}

async function disable2fa() {
  if (!confirm('Disable two-factor authentication? This makes your account less secure.')) return;
  toggling2fa.value = true;
  twoFactorMsg.value = '';
  setTimeout(() => {
    twoFactorEnabled.value = false;
    localStorage.setItem('twoFactorEnabled', 'false');
    twoFactorMsg.value = 'Two-factor authentication disabled';
    twoFactorMsgType.value = 'success';
    toggling2fa.value = false;
    setTimeout(() => (twoFactorMsg.value = ''), 2500);
  }, 700);
}

async function savePreferences() {
  savingPrefs.value = true;
  prefsMsg.value = '';
  setTimeout(() => {
    localStorage.setItem('preferences', JSON.stringify(prefs.value));
    prefsMsg.value = 'Preferences saved';
    prefsMsgType.value = 'success';
    savingPrefs.value = false;
    setTimeout(() => (prefsMsg.value = ''), 2500);
  }, 500);
}

function confirmDelete() {
  if (confirm('This will request deletion of your account and all your content. Continue?')) {
    alert('Deletion request submitted. Our team will contact you shortly.');
  }
}

function activityIcon(type) {
  if (type === 'approval') return `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/><path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
  if (type === 'upload') return `<svg viewBox="0 0 24 24" fill="none"><path d="M12 4V16" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M7 9L12 4L17 9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
  return `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/><path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>`;
}

function formatDate(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleDateString() + ' ' + d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

onMounted(async () => {
  try {
    const saved = JSON.parse(localStorage.getItem('preferences') || 'null');
    if (saved) prefs.value = { ...prefs.value, ...saved };
  } catch {}
  twoFactorEnabled.value = localStorage.getItem('twoFactorEnabled') === 'true';

  try {
    const { data } = await api.get('/content');
    totalContent.value = data.length;
    activities.value = data.slice(0, 8).map((c) => ({
      id: c.id,
      type: c.status === 'approved' ? 'approval' : 'upload',
      text: `Uploaded "${c.title}" (${c.subject})`,
      created_at: c.created_at,
    }));
  } catch {}
});
</script>