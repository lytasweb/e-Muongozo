import express from 'express';
import { pool } from '../db.js';
import { auth } from '../middleware/auth.js';
import { createNotification } from './notifications.js';

const router = express.Router();

function isTieOrNectaAdmin(req) {
  return (
    req.user.is_admin === true &&
    ['TIE', 'NECTA'].includes(req.user.role)
  );
}

// ============================================================
// GET /api/schools/pending  — NECTA admin only
// ============================================================
router.get('/pending', auth(), async (req, res) => {
  if (!isTieOrNectaAdmin(req) || req.user.role !== 'NECTA') {
    return res.status(403).json({ error: 'NECTA admin access required' });
  }

  const result = await pool.query(
    `SELECT id, email, full_name, school_name, role, approval_status, created_at
     FROM users
     WHERE role='SCHOOL' AND approval_status='pending'
     ORDER BY created_at ASC`
  );
  res.json(result.rows);
});

// ============================================================
// GET /api/schools/registered  — TIE + NECTA admins
// ============================================================
router.get('/registered', auth(), async (req, res) => {
  if (!isTieOrNectaAdmin(req)) {
    return res.status(403).json({ error: 'Admin access required' });
  }

  const result = await pool.query(
    `SELECT u.id, u.email, u.full_name, u.school_name, u.approval_status,
            u.created_at, u.approved_at,
            (SELECT COUNT(*)::int FROM content c
             WHERE c.author_id = u.id AND c.author_role = 'SCHOOL') AS content_count
     FROM users u
     WHERE u.role='SCHOOL' AND u.approval_status IN ('approved', 'suspended')
     ORDER BY u.approved_at DESC NULLS LAST, u.created_at DESC`
  );
  res.json(result.rows);
});

// ============================================================
// GET /api/schools/:id/teachers
// ============================================================
router.get('/:id/teachers', auth(), async (req, res) => {
  if (!isTieOrNectaAdmin(req)) {
    return res.status(403).json({ error: 'Admin access required' });
  }

  const schoolId = req.params.id;

  const school = await pool.query(
    `SELECT id, school_name, full_name, email, approval_status, created_at
     FROM users WHERE id=$1 AND role='SCHOOL'`,
    [schoolId]
  );
  if (!school.rows.length) return res.status(404).json({ error: 'School not found' });

  const content = await pool.query(
    `SELECT id, title, subject, level, status, badge, created_at, review_notes
     FROM content WHERE author_id=$1 AND author_role='SCHOOL'
     ORDER BY created_at DESC`,
    [schoolId]
  );

  res.json({
    school: school.rows[0],
    teachers: [{
      id: school.rows[0].id,
      full_name: school.rows[0].full_name,
      email: school.rows[0].email,
      role: 'Primary Contact',
      joined_at: school.rows[0].created_at,
    }],
    content: content.rows,
  });
});

// ============================================================
// POST /api/schools/:id/approve  — NECTA admin only
// ============================================================
router.post('/:id/approve', auth(), async (req, res) => {
  if (!isTieOrNectaAdmin(req) || req.user.role !== 'NECTA') {
    return res.status(403).json({ error: 'NECTA admin access required' });
  }

  const result = await pool.query(
    `UPDATE users
     SET approval_status='approved',
         approved_at=NOW(),
         approved_by=$1,
         rejection_reason=NULL
     WHERE id=$2 AND role='SCHOOL'
     RETURNING id, email, full_name, school_name`,
    [req.user.id, req.params.id]
  );
  if (!result.rows.length) return res.status(404).json({ error: 'School not found' });

  const school = result.rows[0];

  try {
    await createNotification({
      user_id: school.id,
      user_role: 'SCHOOL',
      type: 'approval',
      title: 'Account approved',
      text: `Your school "${school.school_name || school.full_name}" has been approved by NECTA. You can now upload content.`,
      link: '/upload',
    });
  } catch {}

  res.json(school);
});

// ============================================================
// POST /api/schools/:id/reject  — NECTA admin only
// ============================================================
router.post('/:id/reject', auth(), async (req, res) => {
  if (!isTieOrNectaAdmin(req) || req.user.role !== 'NECTA') {
    return res.status(403).json({ error: 'NECTA admin access required' });
  }

  const { reason } = req.body;

  const result = await pool.query(
    `UPDATE users
     SET approval_status='rejected', rejection_reason=$1
     WHERE id=$2 AND role='SCHOOL'
     RETURNING id, email, full_name, school_name`,
    [reason || null, req.params.id]
  );
  if (!result.rows.length) return res.status(404).json({ error: 'School not found' });

  const school = result.rows[0];

  try {
    await createNotification({
      user_id: school.id,
      user_role: 'SCHOOL',
      type: 'review',
      title: 'Account not approved',
      text: reason
        ? `Your school registration was not approved. Reason: ${reason}`
        : 'Your school registration was not approved.',
      link: '/login',
    });
  } catch {}

  res.json(school);
});

// ============================================================
// POST /api/schools/:id/suspend  — TIE admin OR NECTA admin
//   Auto-rejects pending content with a clear reason.
// ============================================================
router.post('/:id/suspend', auth(), async (req, res) => {
  if (!isTieOrNectaAdmin(req)) {
    return res.status(403).json({ error: 'Admin access required' });
  }

  const { reason } = req.body;
  const schoolId = req.params.id;

  const check = await pool.query(
    'SELECT * FROM users WHERE id=$1 AND role=$2',
    [schoolId, 'SCHOOL']
  );
  if (!check.rows.length) return res.status(404).json({ error: 'School not found' });

  const school = check.rows[0];

  // 1. Suspend the school
  await pool.query(
    `UPDATE users
     SET approval_status='suspended',
         suspended_at=NOW(),
         suspended_by=$1,
         suspended_reason=$2
     WHERE id=$3`,
    [req.user.id, reason || null, schoolId]
  );

  // 2. Auto-reject pending content
  const rejectReason = `School suspended on ${new Date().toLocaleDateString()} — ${reason || 'contact NECTA for more information'}`;
  await pool.query(
    `UPDATE content
     SET status='rejected',
         badge='Pending',
         review_notes=$1,
         updated_at=NOW()
     WHERE author_id=$2 AND author_role='SCHOOL' AND status='pending'`,
    [rejectReason, schoolId]
  );

  // 3. Notify the school
  try {
    await createNotification({
      user_id: school.id,
      user_role: 'SCHOOL',
      type: 'review',
      title: 'Account suspended',
      text: reason
        ? `Your school account was suspended. Reason: ${reason}`
        : 'Your school account was suspended. Contact NECTA for more information.',
      link: '/login',
    });
  } catch {}

  res.json({ ok: true });
});

// ============================================================
// POST /api/schools/:id/activate  — TIE admin OR NECTA admin
// ============================================================
router.post('/:id/activate', auth(), async (req, res) => {
  if (!isTieOrNectaAdmin(req)) {
    return res.status(403).json({ error: 'Admin access required' });
  }

  const schoolId = req.params.id;

  const check = await pool.query(
    'SELECT * FROM users WHERE id=$1 AND role=$2',
    [schoolId, 'SCHOOL']
  );
  if (!check.rows.length) return res.status(404).json({ error: 'School not found' });

  const school = check.rows[0];

  await pool.query(
    `UPDATE users
     SET approval_status='approved',
         suspended_at=NULL,
         suspended_by=NULL,
         suspended_reason=NULL
     WHERE id=$1`,
    [schoolId]
  );

  try {
    await createNotification({
      user_id: school.id,
      user_role: 'SCHOOL',
      type: 'approval',
      title: 'Account reactivated',
      text: 'Your school account has been reactivated. You can now log in and upload again.',
      link: '/upload',
    });
  } catch {}

  res.json({ ok: true });
});

// ============================================================
// POST /api/schools/:id/remind  — TIE admin OR NECTA admin
// ============================================================
router.post('/:id/remind', auth(), async (req, res) => {
  if (!isTieOrNectaAdmin(req)) {
    return res.status(403).json({ error: 'Admin access required' });
  }

  const { subject, message } = req.body;
  if (!subject || !message) {
    return res.status(400).json({ error: 'Missing subject or message' });
  }

  const schoolId = req.params.id;
  const check = await pool.query(
    'SELECT id, email, full_name, school_name FROM users WHERE id=$1 AND role=$2',
    [schoolId, 'SCHOOL']
  );
  if (!check.rows.length) return res.status(404).json({ error: 'School not found' });

  const school = check.rows[0];

  console.log('');
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║            e-Muongozo — REMINDER EMAIL           ║');
  console.log('╠══════════════════════════════════════════════════╣');
  console.log(`║  To:      ${school.email.padEnd(38)}║`);
  console.log(`║  School:  ${(school.school_name || school.full_name).slice(0, 38).padEnd(38)}║`);
  console.log(`║  From:    ${req.user.role} admin`.padEnd(49) + '║');
  console.log('╠══════════════════════════════════════════════════╣');
  console.log(`║  Subject: ${subject.slice(0, 38).padEnd(38)}║`);
  console.log('╠══════════════════════════════════════════════════╣');
  const wrapped = String(message).match(/.{1,48}/g) || [''];
  for (const line of wrapped) {
    console.log(`║  ${line.padEnd(48)}║`);
  }
  console.log('╚══════════════════════════════════════════════════╝');
  console.log('');

  try {
    await createNotification({
      user_id: school.id,
      user_role: 'SCHOOL',
      type: 'system',
      title: `Reminder: ${subject}`,
      text: message,
      link: '/notifications',
    });
  } catch {}

  res.json({ ok: true, sent_to: school.email });
});

// ============================================================
// GET /api/schools/members
//   Legacy endpoint — kept for the TIE members listing
//   that used to show everyone. Now returns only TIE-scoped users.
// ============================================================
router.get('/members', auth(), async (req, res) => {
  if (req.user.role !== 'TIE' || !req.user.is_admin) {
    return res.status(403).json({ error: 'TIE admin access required' });
  }
  const result = await pool.query(
    `SELECT id, email, full_name, role, school_name, is_admin, approval_status, created_at
     FROM users
     WHERE role IN ('TIE', 'TIESTAFF', 'REVIEWER')
     ORDER BY is_admin DESC, role, created_at DESC`
  );
  res.json(result.rows);
});

export default router;
