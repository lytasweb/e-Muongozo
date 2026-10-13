import express from 'express';
import { pool } from '../db.js';
import { auth } from '../middleware/auth.js';
import { createNotification } from './notifications.js';

const router = express.Router();

function isAdmin(req) {
  return req.user.is_admin === true;
}

// ============================================================
// GET /api/members
//   TIE / TIESTAFF → TIE + TIESTAFF + REVIEWER
//   NECTA          → NECTA only
// ============================================================
router.get('/', auth(), async (req, res) => {
  try {
    if (['TIE', 'TIESTAFF'].includes(req.user.role)) {
      const result = await pool.query(
        `SELECT id, email, full_name, role, is_admin, approval_status, created_at, last_login_at
         FROM users
         WHERE role IN ('TIE', 'TIESTAFF', 'REVIEWER')
         ORDER BY is_admin DESC, role, created_at DESC`
      );
      return res.json(result.rows);
    }

    if (req.user.role === 'NECTA') {
      const result = await pool.query(
        `SELECT id, email, full_name, role, is_admin, approval_status, created_at, last_login_at
         FROM users
         WHERE role = 'NECTA'
         ORDER BY is_admin DESC, created_at DESC`
      );
      return res.json(result.rows);
    }

    return res.status(403).json({ error: 'Not authorized' });
  } catch (e) {
    console.error('[members] error:', e.message);
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// POST /api/members/:id/suspend
// ============================================================
router.post('/:id/suspend', auth(), async (req, res) => {
  if (!isAdmin(req)) return res.status(403).json({ error: 'Admin access required' });

  const { reason } = req.body;
  const targetId = req.params.id;
  const scope = req.user.role === 'TIE' ? ['TIE', 'TIESTAFF', 'REVIEWER'] : ['NECTA'];

  if (String(targetId) === String(req.user.id)) {
    return res.status(400).json({ error: 'You cannot suspend yourself' });
  }

  const check = await pool.query('SELECT * FROM users WHERE id=$1', [targetId]);
  if (!check.rows.length) return res.status(404).json({ error: 'User not found' });
  if (!scope.includes(check.rows[0].role)) return res.status(403).json({ error: 'Cannot suspend this user' });

  await pool.query(
    `UPDATE users SET approval_status='suspended', suspended_at=NOW(), suspended_by=$1, suspended_reason=$2 WHERE id=$3`,
    [req.user.id, reason || null, targetId]
  );

  try {
    await createNotification({
      user_id: targetId,
      user_role: check.rows[0].role,
      type: 'review',
      title: 'Account suspended',
      text: reason ? `Your account has been suspended. Reason: ${reason}` : 'Your account has been suspended.',
      link: '/login',
    });
  } catch {}

  res.json({ ok: true });
});

// ============================================================
// POST /api/members/:id/activate
// ============================================================
router.post('/:id/activate', auth(), async (req, res) => {
  if (!isAdmin(req)) return res.status(403).json({ error: 'Admin access required' });

  const targetId = req.params.id;
  const scope = req.user.role === 'TIE' ? ['TIE', 'TIESTAFF', 'REVIEWER'] : ['NECTA'];

  const check = await pool.query('SELECT * FROM users WHERE id=$1', [targetId]);
  if (!check.rows.length) return res.status(404).json({ error: 'User not found' });
  if (!scope.includes(check.rows[0].role)) return res.status(403).json({ error: 'Cannot activate this user' });

  await pool.query(
    `UPDATE users SET approval_status='approved', suspended_at=NULL, suspended_by=NULL, suspended_reason=NULL WHERE id=$1`,
    [targetId]
  );

  try {
    await createNotification({
      user_id: targetId,
      user_role: check.rows[0].role,
      type: 'approval',
      title: 'Account reactivated',
      text: 'Your account has been reactivated.',
      link: '/login',
    });
  } catch {}

  res.json({ ok: true });
});

// ============================================================
// POST /api/members/:id/promote
//   TIE admin only → TIESTAFF becomes REVIEWER
// ============================================================
router.post('/:id/promote', auth(), async (req, res) => {
  if (req.user.role !== 'TIE' || !isAdmin(req)) return res.status(403).json({ error: 'TIE admin access required' });

  const targetId = req.params.id;
  const check = await pool.query('SELECT * FROM users WHERE id=$1', [targetId]);
  if (!check.rows.length) return res.status(404).json({ error: 'User not found' });
  if (check.rows[0].role !== 'TIESTAFF') return res.status(400).json({ error: 'Only TIESTAFF can be promoted to Reviewer' });

  await pool.query(`UPDATE users SET role='REVIEWER' WHERE id=$1`, [targetId]);

  try {
    await createNotification({
      user_id: targetId,
      user_role: 'REVIEWER',
      type: 'approval',
      title: 'Promoted to Reviewer',
      text: 'You have been promoted to Reviewer.',
      link: '/review',
    });
  } catch {}

  res.json({ ok: true });
});

// ============================================================
// POST /api/members/:id/demote
//   TIE admin only → REVIEWER becomes TIESTAFF
// ============================================================
router.post('/:id/demote', auth(), async (req, res) => {
  if (req.user.role !== 'TIE' || !isAdmin(req)) return res.status(403).json({ error: 'TIE admin access required' });

  const targetId = req.params.id;
  const check = await pool.query('SELECT * FROM users WHERE id=$1', [targetId]);
  if (!check.rows.length) return res.status(404).json({ error: 'User not found' });
  if (check.rows[0].role !== 'REVIEWER') return res.status(400).json({ error: 'Only REVIEWER can be demoted to TIESTAFF' });

  await pool.query(`UPDATE users SET role='TIESTAFF' WHERE id=$1`, [targetId]);

  try {
    await createNotification({
      user_id: targetId,
      user_role: 'TIESTAFF',
      type: 'system',
      title: 'Role changed',
      text: 'You are now a TIE staff contributor.',
      link: '/tie',
    });
  } catch {}

  res.json({ ok: true });
});

// ============================================================
// POST /api/members/:id/make-admin
//   TIE admin   → TIE / TIESTAFF become admin
//   NECTA admin → NECTA becomes admin
// ============================================================
router.post('/:id/make-admin', auth(), async (req, res) => {
  if (!isAdmin(req)) return res.status(403).json({ error: 'Admin access required' });

  const targetId = req.params.id;
  const scope = req.user.role === 'TIE' ? ['TIE', 'TIESTAFF'] : ['NECTA'];

  // Can't make yourself admin (already are)
  if (String(targetId) === String(req.user.id)) {
    return res.status(400).json({ error: 'You are already an admin' });
  }

  const check = await pool.query('SELECT * FROM users WHERE id=$1', [targetId]);
  if (!check.rows.length) return res.status(404).json({ error: 'User not found' });
  if (!scope.includes(check.rows[0].role)) {
    return res.status(403).json({ error: 'Cannot promote this user' });
  }
  if (check.rows[0].is_admin === true) {
    return res.status(400).json({ error: 'User is already an admin' });
  }

  await pool.query('UPDATE users SET is_admin=TRUE WHERE id=$1', [targetId]);

  try {
    await createNotification({
      user_id: targetId,
      user_role: check.rows[0].role,
      type: 'approval',
      title: 'You are now an admin',
      text: 'You have been granted admin privileges.',
      link: '/profile',
    });
  } catch {}

  res.json({ ok: true });
});

// ============================================================
// POST /api/members/:id/revoke-admin
//   TIE admin   → revoke TIE / TIESTAFF admin
//   NECTA admin → revoke NECTA admin
// ============================================================
router.post('/:id/revoke-admin', auth(), async (req, res) => {
  if (!isAdmin(req)) return res.status(403).json({ error: 'Admin access required' });

  const targetId = req.params.id;
  const scope = req.user.role === 'TIE' ? ['TIE', 'TIESTAFF'] : ['NECTA'];

  // Can't revoke your own admin
  if (String(targetId) === String(req.user.id)) {
    return res.status(400).json({ error: 'You cannot revoke your own admin access' });
  }

  const check = await pool.query('SELECT * FROM users WHERE id=$1', [targetId]);
  if (!check.rows.length) return res.status(404).json({ error: 'User not found' });
  if (!scope.includes(check.rows[0].role)) {
    return res.status(403).json({ error: 'Cannot revoke admin for this user' });
  }
  if (check.rows[0].is_admin !== true) {
    return res.status(400).json({ error: 'User is not an admin' });
  }

  await pool.query('UPDATE users SET is_admin=FALSE WHERE id=$1', [targetId]);

  try {
    await createNotification({
      user_id: targetId,
      user_role: check.rows[0].role,
      type: 'system',
      title: 'Admin privileges revoked',
      text: 'Your admin privileges have been revoked by your organization admin.',
      link: '/profile',
    });
  } catch {}

  res.json({ ok: true });
});

// ============================================================
// POST /api/members/:id/remind
// ============================================================
router.post('/:id/remind', auth(), async (req, res) => {
  if (!isAdmin(req)) return res.status(403).json({ error: 'Admin access required' });

  const { subject, message } = req.body;
  if (!subject || !message) return res.status(400).json({ error: 'Missing subject or message' });

  const targetId = req.params.id;
  const scope = req.user.role === 'TIE' ? ['TIE', 'TIESTAFF', 'REVIEWER'] : ['NECTA'];

  const check = await pool.query('SELECT id, email, full_name, role FROM users WHERE id=$1', [targetId]);
  if (!check.rows.length) return res.status(404).json({ error: 'User not found' });
  if (!scope.includes(check.rows[0].role)) return res.status(403).json({ error: 'Cannot remind this user' });

  const target = check.rows[0];

  console.log('');
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║            e-Muongozo — REMINDER EMAIL           ║');
  console.log('╠══════════════════════════════════════════════════╣');
  console.log(`║  To:      ${target.email.padEnd(38)}║`);
  console.log(`║  Name:    ${target.full_name.slice(0, 38).padEnd(38)}║`);
  console.log(`║  From:    ${(req.user.role + ' admin').padEnd(38)}║`);
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
      user_id: targetId,
      user_role: target.role,
      type: 'system',
      title: `Reminder: ${subject}`,
      text: message,
      link: '/notifications',
    });
  } catch {}

  res.json({ ok: true, sent_to: target.email });
});

export default router;
