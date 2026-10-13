<template>
  <transition name="fade">
    <div class="preview-modal" @click.self="$emit('close')">
      <div class="preview-panel" style="max-width: 520px;">
        <div class="preview-header">
          <div class="preview-header-text">
            <div class="preview-title">Send reminder</div>
            <div class="preview-meta">
              To <strong>{{ target.full_name }}</strong>
              <span class="preview-meta-dot">·</span>
              {{ target.email }}
            </div>
          </div>
          <button class="preview-close" @click="$emit('close')">
            <svg viewBox="0 0 24 24" fill="none">
              <path d="M6 6L18 18M6 18L18 6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
          </button>
        </div>

        <div style="padding: 20px;">
          <div style="margin-bottom: 16px;">
            <label style="display:block; font-size:12px; font-weight:700; text-transform:uppercase; letter-spacing:0.06em; color:#64748b; margin-bottom:8px;">
              Template
            </label>
            <div class="reminder-templates">
              <button
                v-for="t in templates"
                :key="t.id"
                class="reminder-template"
                :class="{ 'reminder-template-active': selectedTemplate === t.id }"
                @click="pickTemplate(t)"
              >
                {{ t.label }}
              </button>
            </div>
          </div>

          <div style="margin-bottom: 12px;">
            <label style="display:block; font-size:13px; font-weight:600; margin-bottom:6px;">Subject</label>
            <input v-model="subject" placeholder="e.g. Reminder from e-Muongozo" style="width:100%; padding:10px 12px; border:1px solid #e2e8f0; border-radius:10px; font-size:14px; font-family:inherit;" />
          </div>

          <div>
            <label style="display:block; font-size:13px; font-weight:600; margin-bottom:6px;">Message</label>
            <textarea v-model="message" rows="6" placeholder="Write your message…" style="width:100%; padding:10px 12px; border:1px solid #e2e8f0; border-radius:10px; font-size:14px; font-family:inherit;"></textarea>
          </div>

          <div v-if="error" class="auth-error" style="margin-top: 12px;">{{ error }}</div>

          <div v-if="sent" class="pull-success" style="margin-top: 12px;">
            <svg viewBox="0 0 24 24" fill="none" width="18" height="18">
              <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/>
              <path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
            Reminder queued — check backend logs
          </div>
        </div>

        <div class="preview-footer">
          <div class="preview-footer-info">
            <svg viewBox="0 0 24 24" fill="none" width="16" height="16">
              <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.6"/>
              <path d="M12 8V12M12 16H12.01" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/>
            </svg>
            Email is logged in dev mode.
          </div>
          <div class="preview-footer-actions">
            <button class="force-btn force-btn-ghost force-btn-sm" @click="$emit('close')">Cancel</button>
            <button class="force-btn force-btn-primary force-btn-sm" @click="send" :disabled="sending || sent">
              {{ sending ? 'Sending…' : 'Send reminder' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref } from 'vue';
import api from '../api.js';

const props = defineProps({
  target: { type: Object, required: true },
  endpoint: { type: String, required: true },
});
const emit = defineEmits(['close', 'sent']);

const templates = [
  { id: 'profile', label: 'Complete profile',
    subject: 'Please complete your e-Muongozo profile',
    message: 'Hi, please take a moment to complete your profile on e-Muongozo. Having accurate information helps us serve you better.' },
  { id: 'pending', label: 'Pending review',
    subject: 'You have items awaiting your review',
    message: 'You have content awaiting your review on e-Muongozo. Please log in and complete the review.' },
  { id: 'approval', label: 'Awaiting approval',
    subject: 'Your account is awaiting approval',
    message: 'Your e-Muongozo account is currently awaiting review. We will notify you once a decision is made.' },
  { id: 'custom', label: 'Custom',
    subject: '',
    message: '' },
];

const selectedTemplate = ref('');
const subject = ref('');
const message = ref('');
const sending = ref(false);
const sent = ref(false);
const error = ref('');

function pickTemplate(t) {
  selectedTemplate.value = t.id;
  subject.value = t.subject;
  message.value = t.message;
}

async function send() {
  if (!subject.value.trim() || !message.value.trim()) {
    error.value = 'Subject and message are required';
    return;
  }
  sending.value = true;
  error.value = '';
  try {
    await api.post(props.endpoint, { subject: subject.value, message: message.value });
    sent.value = true;
    emit('sent');
  } catch (e) {
    error.value = e.response?.data?.error || 'Send failed';
  } finally {
    sending.value = false;
  }
}
</script>

<style scoped>
.reminder-templates {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}
.reminder-template {
  padding: 8px 14px;
  border: 1.5px solid #e2e8f0;
  background: #fff;
  color: #334155;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  transition: all 0.15s;
}
.reminder-template:hover {
  border-color: #3b82f6;
  color: #2563eb;
}
.reminder-template-active {
  background: #eff6ff;
  border-color: #3b82f6;
  color: #1e40af;
}
</style>
