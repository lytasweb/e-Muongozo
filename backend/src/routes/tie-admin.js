import express from 'express';
import { pool } from '../db.js';
import { auth } from '../middleware/auth.js';
import { createNotification } from './notifications.js';

const router = express.Router();

// All routes require TIE role
router.use(auth(['TIE']));

// ============================================================
// GET /api/tie-admin/pending
//   Schools that registered but are not yet approved
// ============================================================
router.get('/pending', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, email, full_name, school_name, role, created_at
       FROM users
       WHERE role='SCHOOL'
         AND (approved IS NULL OR approved = FALSE)
         AND rejected IS NULL
       ORDER BY created_at DESC`
    );
    res.json(result.rows);
  } catch (e) {
    if (e.code === '42703') {
      // approved/rejected columns don't exist yet
      return res.json([]);
    }
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// GET /api/tie-admin/registered
//   Schools that have been approved
// ============================================================
router.get('/registered', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, email, full_name, school_name, role, created_at, approved_at
       FROM users
       WHERE role='SCHOOL' AND approved = TRUE
       ORDER BY approved_at DESC NULLS LAST, created_at DESC`
    );

    // For each school, count teachers
    for (const school of result.rows) {
      const teachers = await pool.query(
        `SELECT id, full_name, email, role, created_at
         FROM users
         WHERE school_id = $1 AND role IN ('SCHOOL', 'TEACHER')
         ORDER BY created_at DESC`,
        [school.id]
      ).catch(() => ({ rows: [] }));
      school.teachers = teachers.rows || [];
      school.teacher_count = (teachers.rows || []).length;
    }

    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// GET /api/tie-admin/members
//   Every user that has "Continue with TIE" — i.e. all users
//   that belong to the TIE ecosystem (role=TIE or role=SCHOOL
//   or role=TEACHER)
// ============================================================
router.get('/members', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT
         'user' AS source,
         id, email, full_name, role, school_name, school_id,
         approved, created_at
       FROM users
       WHERE role IN ('TIE', 'SCHOOL', 'TEACHER', 'REVIEWER')
       UNION ALL
       SELECT
         'entity' AS source,
         id, email, entity_name AS full_name, entity_type AS role,
         NULL AS school_name, NULL AS school_id,
         TRUE AS approved, created_at
       FROM authorized_entities
       WHERE entity_type = 'TIE'
       ORDER BY created_at DESC`
    );
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// POST /api/tie-admin/schools/:id/approve
//   TIE approves a registered school
// ============================================================
router.post('/schools/:id/approve', async (req, res) => {
  try {
    const result = await pool.query(
      `UPDATE users
       SET approved = TRUE, approved_at = NOW(), rejected = FALSE
       WHERE id = $1 AND role = 'SCHOOL'
       RETURNING id, email, full_name, school_name`,
      [req.params.id]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'School not found' });
    }
    const school = result.rows[0];

    // Notify the school
    try {
      await createNotification({
        user_id: school.id,
        user_role: 'SCHOOL',
        type: 'approval',
        title: 'Registration approved',
        text: `Your school "${school.school_name || school.full_name}" has been approved by TIE. You can now upload content.`,
        link: '/dashboard',
      });
    } catch {}

    res.json(school);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// POST /api/tie-admin/schools/:id/reject
// ============================================================
router.post('/schools/:id/reject', async (req, res) => {
  const { reason } = req.body;
  try {
    const result = await pool.query(
      `UPDATE users
       SET approved = FALSE, rejected = TRUE, rejected_reason = $2
       WHERE id = $1 AND role = 'SCHOOL'
       RETURNING id, email, full_name, school_name`,
      [req.params.id, reason || null]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'School not found' });
    }
    const school = result.rows[0];

    // Notify
    try {
      await createNotification({
        user_id: school.id,
        user_role: 'SCHOOL',
        type: 'rejection',
        title: 'Registration not approved',
        text: reason
          ? `Your registration was not approved. Reason: ${reason}`
          : `Your registration was not approved.`,
        link: '/dashboard',
      });
    } catch {}

    res.json(school);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

export default router;
