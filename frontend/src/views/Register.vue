<template>
  <div class="auth-root">
    <!-- LEFT: Brand panel -->
    <div class="auth-left">
      <div class="auth-left-inner">
        <div class="auth-brand-text">
          <span class="auth-brand-name">e-Muongozo</span>
        </div>

        <h1 class="auth-headline">
          Share your school's<br/>
          <span class="auth-headline-accent">teaching excellence.</span>
        </h1>

        <p class="auth-sub">
          Register your institution to submit structured teaching methods,
          step-by-step notes, and book lists. Every submission is reviewed by
          a NECTA curriculum specialist before it reaches students.
        </p>

        <div class="auth-features">
          <div class="auth-feature">
            <div class="auth-feature-icon">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M12 2L3 7V12C3 17.55 6.84 22.74 12 24C17.16 22.74 21 17.55 21 12V7L12 2Z" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/>
                <path d="M9 12L11 14L15 10" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </div>
            <div>
              <div class="auth-feature-title">TIE-verified badge</div>
              <div class="auth-feature-text">Get official recognition for your school's methods</div>
            </div>
          </div>
          <div class="auth-feature">
            <div class="auth-feature-icon">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M17 21V19C17 16.7909 15.2091 15 13 15H5C2.79086 15 1 16.7909 1 19V21" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                <circle cx="9" cy="7" r="4" stroke="currentColor" stroke-width="1.5"/>
                <path d="M23 21V19C22.9986 17.1771 21.765 15.5857 20 15.13" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                <path d="M16 3.13C17.7699 3.58317 19.0078 5.17799 19.0078 7.005C19.0078 8.83201 17.7699 10.4268 16 10.88" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
              </svg>
            </div>
            <div>
              <div class="auth-feature-title">National reach</div>
              <div class="auth-feature-text">Your methods reach thousands of rural students</div>
            </div>
          </div>
          <div class="auth-feature">
            <div class="auth-feature-icon">
              <svg viewBox="0 0 24 24" fill="none">
                <path d="M4 20H20M4 20V8L12 4L20 8V20M4 20H9M20 20H15" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                <rect x="9" y="12" width="6" height="8" stroke="currentColor" stroke-width="1.5"/>
              </svg>
            </div>
            <div>
              <div class="auth-feature-title">Contribute officially</div>
              <div class="auth-feature-text">Recognized under Tanzania's education policy</div>
            </div>
          </div>
        </div>
      </div>

      <div class="auth-glow auth-glow-1"></div>
      <div class="auth-glow auth-glow-2"></div>
    </div>

    <!-- RIGHT: Register form -->
    <div class="auth-right">
      <div class="auth-form-wrap">
        <div class="auth-form-header">
          <div class="auth-logo-hero">
            <img :src="logoEmuongozo" alt="e-Muongozo" class="auth-logo-hero-img" />
          </div>

          <h2 v-if="!success">Register your school</h2>
          <h2 v-else>Registration submitted</h2>
          <p v-if="!success">Submit your institution for NECTA review</p>
          <p v-else>Awaiting NECTA approval</p>
        </div>

        <!-- SUCCESS PANEL -->
        <div v-if="success" class="auth-success auth-success-large">
          <svg viewBox="0 0 24 24" fill="none" width="32" height="32">
            <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.5"/>
            <path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <div>
            <strong>Your school is now pending NECTA review</strong>
            <p>Our team will verify your submission within 3–5 working days.</p>
            <p style="margin-top: 12px; font-size: 12px; opacity: 0.8;">
              You will be able to log in with
              <strong>{{ form.email }}</strong>
              once your account is approved.
            </p>
          </div>
        </div>

        <form v-else @submit.prevent="submit" class="auth-form">
          <div class="field">
            <label for="full_name">School representative</label>
            <div class="field-input">
              <svg class="field-icon" viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.5"/>
                <path d="M4 21V19C4 16.7909 5.79086 15 8 15H16C18.2091 15 20 16.7909 20 19V21" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
              </svg>
              <input
                id="full_name"
                v-model="form.full_name"
                required
                placeholder="e.g. John Mwakasege"
              />
            </div>
          </div>

          <div class="field">
            <label for="school_name">School name</label>
            <div class="field-input">
              <svg class="field-icon" viewBox="0 0 24 24" fill="none">
                <path d="M4 20H20M4 20V8L12 4L20 8V20M4 20H9M20 20H15" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                <rect x="9" y="12" width="6" height="8" stroke="currentColor" stroke-width="1.5"/>
              </svg>
              <input
                id="school_name"
                v-model="form.school_name"
                required
                placeholder="e.g. Ilboru High School"
              />
            </div>
          </div>

          <div class="field">
            <label for="email">Email</label>
            <div class="field-input">
              <svg class="field-icon" viewBox="0 0 24 24" fill="none">
                <rect x="3" y="5" width="18" height="14" rx="2" stroke="currentColor" stroke-width="1.5"/>
                <path d="M3 7L12 13L21 7" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
              <input
                id="email"
                v-model="form.email"
                type="email"
                required
                placeholder="you@school.ac.tz"
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
                v-model="form.password"
                type="password"
                required
                minlength="6"
                placeholder="Minimum 6 characters"
              />
            </div>
          </div>

          <button type="submit" class="auth-submit" :disabled="loading">
            <span v-if="!loading">Submit for NECTA review</span>
            <span v-else class="auth-submit-loading">
              <span class="spinner"></span>
              Submitting…
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

        <div v-if="!success" class="auth-register-cta">
          <div class="auth-register-text">Already registered?</div>
          <router-link to="/login" class="auth-register-link">
            Sign in instead
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
import { ref } from 'vue';
import api from '../api.js';
import logoEmuongozo from '../assets/logos/emuongozo.png';

const form = ref({
  full_name: '',
  school_name: '',
  email: '',
  password: '',
});
const loading = ref(false);
const error = ref('');
const success = ref(false);

async function submit() {
  loading.value = true;
  error.value = '';
  try {
    await api.post('/auth/register', {
      email: form.value.email,
      password: form.value.password,
      full_name: form.value.full_name,
      school_name: form.value.school_name,
      role: 'SCHOOL',
    });
    success.value = true;
  } catch (e) {
    error.value = e.response?.data?.error || 'Registration failed. Please try again.';
  } finally {
    loading.value = false;
  }
}
</script>
