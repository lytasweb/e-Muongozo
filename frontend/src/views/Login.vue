<template>
  <div class="auth-root">
    <!-- LEFT panel -->
    <div class="auth-left">
      <div class="auth-left-inner">
        <div class="auth-brand-text">
          <span class="auth-brand-name">e-Muongozo</span>
        </div>

        <h1 class="auth-headline">
          Verified curriculum.<br/>
          <span class="auth-headline-accent">Zero data cost.</span>
        </h1>

        <p class="auth-sub">
          The contributor portal for TIE, NECTA, and top-performing schools.
          Publish study guides that reach every Tanzanian student - offline, under 1MB.
        </p>

        <div class="auth-features">
          <div class="auth-feature">
            <div class="auth-feature-icon">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M5 13L9 17L19 7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </div>
            <div>
              <div class="auth-feature-title">TIE-Reviewed</div>
              <div class="auth-feature-text">Every guide checked against the current syllabus</div>
            </div>
          </div>
          <div class="auth-feature">
            <div class="auth-feature-icon">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M13 2L4 14H12L11 22L20 10H12L13 2Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
              </svg>
            </div>
            <div>
              <div class="auth-feature-title">Under 1MB sync</div>
              <div class="auth-feature-text">Full term's content on 2G networks</div>
            </div>
          </div>
          <div class="auth-feature">
            <div class="auth-feature-icon">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M5 12.55C5 14.55 7.5 16 12 16C16.5 16 19 14.55 19 12.55M12 16V20M9 20H15" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                <path d="M16.24 6.56C17.5 7.5 18.5 9 19 10.5M7.76 6.56C6.5 7.5 5.5 9 5 10.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="1.5"/>
              </svg>
            </div>
            <div>
              <div class="auth-feature-title">Works offline</div>
              <div class="auth-feature-text">Students study without active internet</div>
            </div>
          </div>
        </div>
      </div>
      <div class="auth-glow auth-glow-1"></div>
      <div class="auth-glow auth-glow-2"></div>
    </div>

    <!-- RIGHT panel -->
    <div class="auth-right">
      <div class="auth-form-wrap">
        <button class="theme-toggle" @click="toggleTheme" :aria-label="theme === 'dark' ? 'Switch to light' : 'Switch to dark'">
          <svg v-if="theme === 'dark'" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="4" stroke="currentColor" stroke-width="1.5"/>
            <path d="M12 2V4M12 20V22M4.93 4.93L6.34 6.34M17.66 17.66L19.07 19.07M2 12H4M20 12H22M4.93 19.07L6.34 17.66M17.66 6.34L19.07 4.93" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
          </svg>
          <svg v-else viewBox="0 0 24 24" fill="none">
            <path d="M21 12.79C20.84 14.43 20.19 15.97 19.13 17.22C18.07 18.47 16.65 19.36 15.06 19.78C13.47 20.19 11.79 20.11 10.25 19.54C8.71 18.97 7.38 17.95 6.44 16.62C5.5 15.29 5.01 13.7 5.03 12.08C5.05 10.46 5.58 8.88 6.55 7.57C7.52 6.27 8.88 5.29 10.44 4.78C9.66 5.63 9.16 6.7 9.02 7.85C8.88 9 9.11 10.16 9.68 11.17C10.24 12.19 11.1 13 12.14 13.53C13.18 14.06 14.36 14.28 15.52 14.14C16.68 14 17.77 13.52 18.65 12.76" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>

        <div class="auth-form-header">
          <div class="auth-logo-hero">
            <img :src="logoEmuongozo" alt="e-Muongozo" class="auth-logo-hero-img" />
          </div>
          <h2>Welcome back</h2>
          <p>Sign in to your contributor account</p>
        </div>

        <form @submit.prevent="submit" class="auth-form">
          <div class="field">
            <label for="email">Email</label>
            <div class="field-input">
              <svg class="field-icon" viewBox="0 0 24 24" fill="none">
                <rect x="3" y="5" width="18" height="14" rx="2" stroke="currentColor" stroke-width="1.5"/>
                <path d="M3 7L12 13L21 7" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
              <input id="email" v-model="email" type="email" required placeholder="you@emuongozo.tz" autocomplete="email" />
            </div>
          </div>

          <div class="field">
            <div class="field-row">
              <label for="password">Password</label>
              <a href="#" class="field-link">Forgot?</a>
            </div>
            <div class="field-input">
              <svg class="field-icon" viewBox="0 0 24 24" fill="none">
                <rect x="4" y="10" width="16" height="10" rx="2" stroke="currentColor" stroke-width="1.5"/>
                <path d="M8 10V7C8 4.79086 9.79086 3 12 3C14.2091 3 16 4.79086 16 7V10" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
              </svg>
              <input
                id="password"
                v-model="password"
                :type="showPassword ? 'text' : 'password'"
                required
                placeholder="Enter your password"
                autocomplete="current-password"
              />
              <button type="button" class="field-toggle" @click="showPassword = !showPassword">
                <svg v-if="!showPassword" viewBox="0 0 24 24" fill="none">
                  <path d="M2 12C2 12 5 5 12 5C19 5 22 12 22 12C22 12 19 19 12 19C5 19 2 12 2 12Z" stroke="currentColor" stroke-width="1.5"/>
                  <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="1.5"/>
                </svg>
                <svg v-else viewBox="0 0 24 24" fill="none">
                  <path d="M3 3L21 21" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                  <path d="M10.58 10.58C10.21 10.95 10 11.45 10 12C10 13.1 10.9 14 12 14C12.55 14 13.05 13.79 13.42 13.42" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                </svg>
              </button>
            </div>
          </div>

          <button type="submit" class="auth-submit" :disabled="loading">
            <span v-if="!loading">Sign in</span>
            <span v-else class="auth-submit-loading">
              <span class="spinner"></span>
              Signing in…
            </span>
          </button>

          <transition name="fade">
            <div v-if="error" class="auth-error">
              <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
                <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.5"/>
                <path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
              </svg>
              {{ error }}
            </div>
          </transition>
        </form>

        <div class="auth-divider"><span>or continue with</span></div>

        <div class="entity-buttons">
          <button class="entity-btn entity-btn-primary" @click="goToEntity('TIE')">
            <div class="entity-btn-icon">
              <img :src="logoTie" alt="TIE" />
            </div>
            <div class="entity-btn-text">
              <div class="entity-btn-title">Continue with TIE</div>
              <div class="entity-btn-sub">Tanzania Institute of Education</div>
            </div>
            <svg class="entity-btn-arrow" viewBox="0 0 24 24" fill="none">
              <path d="M5 12H19M13 6L19 12L13 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </button>

          <button class="entity-btn entity-btn-primary" @click="goToEntity('NECTA')">
            <div class="entity-btn-icon">
              <img :src="logoNecta" alt="NECTA" />
            </div>
            <div class="entity-btn-text">
              <div class="entity-btn-title">Continue with NECTA</div>
              <div class="entity-btn-sub">National Examinations Council</div>
            </div>
            <svg class="entity-btn-arrow" viewBox="0 0 24 24" fill="none">
              <path d="M5 12H19M13 6L19 12L13 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </button>
        </div>

        <div class="auth-register-cta">
          <div class="auth-register-text">Top-performing school?</div>
          <router-link to="/register" class="auth-register-link">
            Register your school
            <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
              <path d="M5 12H19M13 6L19 12L13 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import api from '../api.js';
import logoEmuongozo from '../assets/logos/emuongozo.png';
import logoTie from '../assets/logos/tie.png';
import logoNecta from '../assets/logos/necta.png';

const router = useRouter();
const email = ref('');
const password = ref('');
const loading = ref(false);
const error = ref('');
const showPassword = ref(false);
const theme = ref(localStorage.getItem('theme') || 'dark');

onMounted(() => applyTheme());

function toggleTheme() {
  theme.value = theme.value === 'dark' ? 'light' : 'dark';
  localStorage.setItem('theme', theme.value);
  applyTheme();
}

function applyTheme() {
  document.documentElement.setAttribute('data-theme', theme.value);
}

function goToEntity(type) {
  router.push(`/entity/${type.toLowerCase()}`);
}

async function submit() {
  loading.value = true;
  error.value = '';
  try {
    const { data } = await api.post('/auth/login', {
      email: email.value,
      password: password.value,
    });
    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));

    // Redirect based on role
    const role = String(data.user.role || '').toUpperCase();
    let target = '/dashboard';
    if (role === 'TIE' || role === 'TIESTAFF') target = '/tie';
    else if (role === 'NECTA') target = '/necta';
    else if (role === 'REVIEWER') target = '/dashboard';
    else if (role === 'SCHOOL') target = '/dashboard';

    await router.push(target);
    window.location.reload();
  } catch (e) {
    error.value = e.response?.data?.error || 'Unable to sign in. Please try again.';
  } finally {
    loading.value = false;
  }
}
</script>
