<template>
  <div class="auth-root">
    <!-- LEFT panel -->
    <div class="auth-left">
      <div class="auth-left-inner">
        <h1 class="auth-headline">
          {{ type }} sign in<br/>
          <span class="auth-headline-accent">with confidence.</span>
        </h1>

        <p class="auth-sub">
          Verified access for {{ entityLabel }}. Use your email or organization username.
        </p>

        <div class="auth-features">
          <div class="auth-feature">
            <div class="auth-feature-icon">
              <svg viewBox="0 0 24 24" fill="none">
                <rect x="4" y="10" width="16" height="10" rx="2" stroke="currentColor" stroke-width="1.5"/>
                <path d="M8 10V7C8 4.79086 9.79086 3 12 3C14.2091 3 16 4.79086 16 7V10" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
              </svg>
            </div>
            <div>
              <div class="auth-feature-title">Restricted access</div>
              <div class="auth-feature-text">Only verified {{ type }} accounts</div>
            </div>
          </div>
          <div class="auth-feature">
            <div class="auth-feature-icon">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M4 4H20V16H13L8 20V16H4V4Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
              </svg>
            </div>
            <div>
              <div class="auth-feature-title">Email verification</div>
              <div class="auth-feature-text">A one-time code confirms organization sign-in</div>
            </div>
          </div>
          <div class="auth-feature">
            <div class="auth-feature-icon">
              <svg viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.5"/>
                <path d="M12 7V12L15 15" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
              </svg>
            </div>
            <div>
              <div class="auth-feature-title">Audit logged</div>
              <div class="auth-feature-text">Every session is recorded</div>
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
        <div class="auth-form-header">
          <div class="auth-entity-hero">
            <img :src="entityLogo" :alt="type" class="auth-entity-hero-img" />
          </div>
          <h2>{{ step === 1 ? `${type} sign in` : 'Enter verification code' }}</h2>
          <p v-if="step === 1">Use your email or organization username</p>
          <p v-else>We sent a 6-character code to your registered email</p>
        </div>

        <!-- STEP 1: Email OR Username + Password -->
        <form v-if="step === 1" @submit.prevent="submitCredentials" class="auth-form">
          <div class="field">
            <label for="identifier">Email or username</label>
            <div class="field-input">
              <svg class="field-icon" viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.5"/>
                <path d="M4 21V19C4 16.7909 5.79086 15 8 15H16C18.2091 15 20 16.7909 20 19V21" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
              </svg>
              <input
                id="identifier"
                v-model="identifier"
                required
                placeholder="you@example.com or tie_official"
                autocomplete="username"
              />
            </div>
          </div>

          <div class="field">
            <label for="password">Password</label>
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
            <span v-if="!loading">Continue</span>
            <span v-else class="auth-submit-loading"><span class="spinner"></span> Verifying…</span>
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

        <!-- STEP 2: OTP (only for organization accounts) -->
        <form v-else @submit.prevent="submitOtp" class="auth-form">
          <div class="auth-info-banner">
            <svg viewBox="0 0 24 24" fill="none" width="18" height="18">
              <rect x="3" y="5" width="18" height="14" rx="2" stroke="currentColor" stroke-width="1.5"/>
              <path d="M3 7L12 13L21 7" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
            <span>Code sent to <strong>{{ emailHint }}</strong></span>
          </div>

          <div v-if="devCode" class="dev-code-banner">
            <div class="dev-code-label">DEV MODE — Your code:</div>
            <div class="dev-code-value">{{ devCode }}</div>
            <div class="dev-code-hint">(also printed in backend logs)</div>
          </div>

          <div class="field">
            <label for="otp">Verification code</label>
            <div class="field-input">
              <svg class="field-icon" viewBox="0 0 24 24" fill="none">
                <rect x="4" y="4" width="16" height="16" rx="3" stroke="currentColor" stroke-width="1.5"/>
                <path d="M9 9H15M9 12H15M9 15H13" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
              </svg>
              <input
                id="otp"
                v-model="code"
                type="text"
                inputmode="text"
                maxlength="6"
                required
                placeholder="ABC123"
                autocomplete="one-time-code"
                class="otp-input"
                @input="code = code.toUpperCase()"
              />
            </div>
          </div>

          <button type="submit" class="auth-submit" :disabled="loading || code.length !== 6">
            <span v-if="!loading">Verify & continue</span>
            <span v-else class="auth-submit-loading"><span class="spinner"></span> Verifying…</span>
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

          <div class="otp-resend">
            Wrong account?
            <button type="button" class="otp-resend-btn" @click="backToCredentials">Start over</button>
          </div>
        </form>

        <div class="auth-register-cta" v-if="step === 1">
          <div class="auth-register-text">Not {{ type }}?</div>
          <router-link to="/login" class="auth-register-link">
            Back to sign in
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
import { computed, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api from '../api.js';
import logoTie from '../assets/logos/tie.png';
import logoNecta from '../assets/logos/necta.png';

const route = useRoute();
const router = useRouter();

const type = computed(() => (route.params.type || 'TIE').toUpperCase());
const entityLabel = computed(() =>
  type.value === 'TIE'
    ? 'Tanzania Institute of Education'
    : 'National Examinations Council of Tanzania'
);
const entityLogo = computed(() => type.value === 'TIE' ? logoTie : logoNecta);

const step = ref(1);
const identifier = ref('');
const password = ref('');
const showPassword = ref(false);
const loading = ref(false);
const error = ref('');

// OTP state
const code = ref('');
const emailHint = ref('');
const devCode = ref('');
const sessionToken = ref('');

// ============================================================
// STEP 1: Detect email vs username, route accordingly
// ============================================================
async function submitCredentials() {
  loading.value = true;
  error.value = '';

  const value = identifier.value.trim();
  const looksLikeEmail = value.includes('@');

  try {
    if (looksLikeEmail) {
      // ---- STAFF / regular user login ----
      const { data } = await api.post('/auth/login', {
        email: value,
        password: password.value,
      });

      const role = String(data.user.role || '').toUpperCase();
      const expected = type.value === 'TIE' ? ['TIE', 'TIESTAFF'] : ['NECTA'];

      if (!expected.includes(role)) {
        error.value = `This account is not a ${type.value} account.`;
        loading.value = false;
        return;
      }

      localStorage.setItem('token', data.token);
      localStorage.setItem('user', JSON.stringify(data.user));

      await router.push(type.value === 'TIE' ? '/tie' : '/necta');
      window.location.reload();
    } else {
      // ---- ORGANIZATION account login → OTP flow ----
      const { data } = await api.post(`/entities/${type.value}/login`, {
        username: value,
        password: password.value,
      });
      sessionToken.value = data.session_token;
      emailHint.value = data.entity.email_hint;
      devCode.value = data.dev_code || '';
      step.value = 2;
      code.value = '';
    }
  } catch (e) {
    error.value = e.response?.data?.error || 'Authentication failed.';
  } finally {
    loading.value = false;
  }
}

// ============================================================
// STEP 2: Verify OTP → land on dashboard
// ============================================================
async function submitOtp() {
  loading.value = true;
  error.value = '';
  try {
    const { data } = await api.post(`/entities/${type.value}/verify`, {
      session_token: sessionToken.value,
      code: code.value,
    });

    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));

    const role = String(data.user.role || '').toUpperCase();
    const target =
      role === 'TIE' ? '/tie' :
      role === 'NECTA' ? '/necta' :
      '/dashboard';

    await router.push(target);
    window.location.reload();
  } catch (e) {
    error.value = e.response?.data?.error || 'Verification failed.';
  } finally {
    loading.value = false;
  }
}

function backToCredentials() {
  step.value = 1;
  code.value = '';
  error.value = '';
  devCode.value = '';
  sessionToken.value = '';
}
</script>
