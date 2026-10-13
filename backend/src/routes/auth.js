import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db.js';
import { auth } from '../middleware/auth.js';

const router = express.Router();

// ============================================================
// POST /api/auth/register
// ============================================================
router.post('/register', async (req, res) => {
  const { email, password, full_name, role, school_name } = req.body;

  if (!email || !password || !full_name || !role) {
    return res.status(400).json({ error: 'Missing fields' });
  }
  if (!['TIE', 'TIESTAFF', 'NECTA', 'SCHOOL', 'REVIEWER'].includes(role)) {
    return res.status(400).json({ error: 'Invalid role' });
  }

  const hash = await bcrypt.hash(password, 10);
  const approvalStatus = role === 'SCHOOL' ? 'pending' : 'approved';

  try {
    const result = await pool.query(
      `INSERT INTO users (email, password_hash, full_name, role, school_name, approval_status)
       VALUES ($1,$2,$3,$4,$5,$6)
       RETURNING id, email, full_name, role, school_name, approval_status, is_admin`,
      [email, hash, full_name, role, school_name || null, approvalStatus]
    );
    res.json(result.rows[0]);
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'Email already exists' });
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// POST /api/auth/login
// ============================================================
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  const result = await pool.query('SELECT * FROM users WHERE email=$1', [email]);
  if (!result.rows.length) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  const user = result.rows[0];
  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  if (user.approval_status === 'suspended') {
    return res.status(403).json({
      error: user.suspended_reason
        ? `Your account is suspended. Reason: ${user.suspended_reason}`
        : 'Your account is suspended. Contact your organization admin.',
      status: 'suspended',
    });
  }

  if (user.role === 'SCHOOL' && user.approval_status === 'pending') {
    return res.status(403).json({
      error: 'Your account is awaiting NECTA approval.',
      status: 'pending',
    });
  }

  if (user.role === 'SCHOOL' && user.approval_status === 'rejected') {
    return res.status(403).json({
      error: user.rejection_reason
        ? `Your registration was not approved. Reason: ${user.rejection_reason}`
        : 'Your registration was not approved.',
      status: 'rejected',
    });
  }

  // Record last login (wrapped in try/catch so an old schema never breaks login)
  try {
    await pool.query('UPDATE users SET last_login_at=NOW() WHERE id=$1', [user.id]);
  } catch (err) {
    console.error('[auth] last_login_at update failed:', err.message);
  }

  const token = jwt.sign(
    {
      id: user.id,
      email: user.email,
      role: user.role,
      full_name: user.full_name,
      is_admin: user.is_admin === true,
    },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

  res.json({
    token,
    user: {
      id: user.id,
      email: user.email,
      role: user.role,
      full_name: user.full_name,
      school_name: user.school_name,
      is_admin: user.is_admin === true,
      approval_status: user.approval_status,
    },
  });
});

// ============================================================
// PUT /api/auth/profile
// ============================================================
router.put('/profile', auth(), async (req, res) => {
  const { full_name, school_name } = req.body;
  if (!full_name) return res.status(400).json({ error: 'Full name required' });

  try {
    if (['SCHOOL', 'REVIEWER', 'TIESTAFF'].includes(req.user.role)) {
      const result = await pool.query(
        `UPDATE users SET full_name=$1, school_name=COALESCE($2, school_name)
         WHERE id=$3
         RETURNING id, email, full_name, role, school_name, is_admin`,
        [full_name, school_name || null, req.user.id]
      );
      if (!result.rows.length) return res.status(404).json({ error: 'User not found' });
      return res.json(result.rows[0]);
    }

    const result = await pool.query(
      `UPDATE authorized_entities SET entity_name=$1
       WHERE id=$2
       RETURNING id, email, entity_name AS full_name, entity_type AS role`,
      [full_name, req.user.id]
    );
    if (!result.rows.length) return res.status(404).json({ error: 'Entity not found' });
    res.json(result.rows[0]);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// PUT /api/auth/password
// ============================================================
router.put('/password', auth(), async (req, res) => {
  const { current_password, new_password } = req.body;
  if (!current_password || !new_password) {
    return res.status(400).json({ error: 'Missing fields' });
  }
  if (new_password.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  try {
    if (['SCHOOL', 'REVIEWER', 'TIESTAFF'].includes(req.user.role)) {
      const userResult = await pool.query('SELECT password_hash FROM users WHERE id=$1', [req.user.id]);
      if (!userResult.rows.length) return res.status(404).json({ error: 'User not found' });
      const ok = await bcrypt.compare(current_password, userResult.rows[0].password_hash);
      if (!ok) return res.status(401).json({ error: 'Current password is incorrect' });

      const hash = await bcrypt.hash(new_password, 10);
      await pool.query('UPDATE users SET password_hash=$1 WHERE id=$2', [hash, req.user.id]);
      return res.json({ ok: true });
    }

    const entityResult = await pool.query('SELECT password_hash FROM authorized_entities WHERE id=$1', [req.user.id]);
    if (!entityResult.rows.length) return res.status(404).json({ error: 'Entity not found' });
    const ok = await bcrypt.compare(current_password, entityResult.rows[0].password_hash);
    if (!ok) return res.status(401).json({ error: 'Current password is incorrect' });

    const hash = await bcrypt.hash(new_password, 10);
    await pool.query('UPDATE authorized_entities SET password_hash=$1 WHERE id=$2', [hash, req.user.id]);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

export default router;
