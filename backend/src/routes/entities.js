import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db.js';

const router = express.Router();

// STEP 1: Verify TIE/NECTA username + password → issue OTP
router.post('/:type/login', async (req, res) => {
  const { type } = req.params;
  const { username, password } = req.body;

  if (!['TIE', 'NECTA'].includes(type.toUpperCase())) {
    return res.status(400).json({ error: 'Invalid entity type' });
  }
  if (!username || !password) {
    return res.status(400).json({ error: 'Missing credentials' });
  }

  const result = await pool.query(
    'SELECT * FROM authorized_entities WHERE entity_type=$1 AND username=$2',
    [type.toUpperCase(), username]
  );
  if (!result.rows.length) return res.status(401).json({ error: 'Invalid credentials' });

  const entity = result.rows[0];
  const ok = await bcrypt.compare(password, entity.password_hash);
  if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

  const code = generateOtp();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

  await pool.query(
    'UPDATE otp_codes SET used = TRUE WHERE entity_id=$1 AND used=FALSE',
    [entity.id]
  );
  await pool.query(
    'INSERT INTO otp_codes (entity_id, code, expires_at) VALUES ($1,$2,$3)',
    [entity.id, code, expiresAt]
  );

  sendOtp(entity, code);

  const sessionToken = jwt.sign(
    { entity_id: entity.id, entity_type: entity.entity_type, purpose: 'otp-verify' },
    process.env.JWT_SECRET,
    { expiresIn: '15m' }
  );

  res.json({
    session_token: sessionToken,
    entity: {
      id: entity.id,
      type: entity.entity_type,
      name: entity.entity_name,
      email_hint: maskEmail(entity.email),
    },
    dev_code: code,
  });
});

// STEP 2: Verify OTP → issue full session
router.post('/:type/verify', async (req, res) => {
  const { type } = req.params;
  const { session_token, code } = req.body;

  if (!session_token || !code) {
    return res.status(400).json({ error: 'Missing fields' });
  }

  let decoded;
  try {
    decoded = jwt.verify(session_token, process.env.JWT_SECRET);
  } catch {
    return res.status(401).json({ error: 'Session expired. Please sign in again.' });
  }

  if (decoded.purpose !== 'otp-verify' || decoded.entity_type !== type.toUpperCase()) {
    return res.status(401).json({ error: 'Invalid session' });
  }

  const otpResult = await pool.query(
    `SELECT * FROM otp_codes
     WHERE entity_id=$1 AND code=$2 AND used=FALSE
     ORDER BY created_at DESC LIMIT 1`,
    [decoded.entity_id, code.toUpperCase()]
  );

  if (!otpResult.rows.length) return res.status(400).json({ error: 'Invalid code' });

  const otp = otpResult.rows[0];
  if (new Date(otp.expires_at) < new Date()) {
    return res.status(400).json({ error: 'Code expired. Request a new one.' });
  }

  await pool.query('UPDATE otp_codes SET used=TRUE WHERE id=$1', [otp.id]);
  await pool.query(
    'INSERT INTO entity_authorizations (entity_id, authorized, code_used) VALUES ($1,$2,$3)',
    [decoded.entity_id, true, otp.code]
  );

  // Record last login for the entity (wrapped so old schema doesn't break login)
  try {
    await pool.query(
      'UPDATE authorized_entities SET last_login_at=NOW() WHERE id=$1',
      [decoded.entity_id]
    );
  } catch (err) {
    console.error('[entities] last_login_at update failed:', err.message);
  }

  const entityResult = await pool.query(
    'SELECT id, entity_type, entity_name, email, is_admin FROM authorized_entities WHERE id=$1',
    [decoded.entity_id]
  );
  const entity = entityResult.rows[0];

  const token = jwt.sign(
    {
      id: entity.id,
      email: entity.email,
      full_name: entity.entity_name,
      role: entity.entity_type,
      entity_id: entity.id,
      is_admin: entity.is_admin === true,
    },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

  res.json({
    token,
    user: {
      id: entity.id,
      email: entity.email,
      full_name: entity.entity_name,
      role: entity.entity_type,
      entity_id: entity.id,
      is_admin: entity.is_admin === true,
    },
  });
});

function generateOtp() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

function maskEmail(email) {
  const [name, domain] = email.split('@');
  const masked = name.length > 2
    ? name[0] + '*'.repeat(name.length - 2) + name[name.length - 1]
    : '*'.repeat(name.length);
  return `${masked}@${domain}`;
}

function sendOtp(entity, code) {
  console.log('');
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║      e-Muongozo — OTP for ' + entity.entity_type.padEnd(24) + '║');
  console.log('╠══════════════════════════════════════════════════╣');
  console.log('║  To:     ' + entity.email.padEnd(40) + '║');
  console.log('║  Entity: ' + entity.entity_name.slice(0, 39).padEnd(40) + '║');
  console.log('║                                                  ║');
  console.log('║           VERIFICATION CODE: ' + code + '           ║');
  console.log('║                                                  ║');
  console.log('║  Expires in 10 minutes                           ║');
  console.log('╚══════════════════════════════════════════════════╝');
  console.log('');
}

export default router;
