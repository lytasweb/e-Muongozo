import express from 'express';
import { pool } from '../db.js';
import { auth } from '../middleware/auth.js';

const router = express.Router();

// GET all notifications for the current user
router.get('/', auth(), async (req, res) => {
  const result = await pool.query(
    `SELECT id, type, title, text, link, read, created_at
     FROM notifications
     WHERE user_id=$1 AND user_role=$2
     ORDER BY created_at DESC
     LIMIT 50`,
    [req.user.id, req.user.role]
  );
  res.json(result.rows);
});

// GET unread count
router.get('/unread-count', auth(), async (req, res) => {
  const result = await pool.query(
    `SELECT COUNT(*)::int AS count
     FROM notifications
     WHERE user_id=$1 AND user_role=$2 AND read=FALSE`,
    [req.user.id, req.user.role]
  );
  res.json({ count: result.rows[0]?.count || 0 });
});

// POST mark one as read
router.post('/:id/read', auth(), async (req, res) => {
  await pool.query(
    `UPDATE notifications SET read=TRUE
     WHERE id=$1 AND user_id=$2 AND user_role=$3`,
    [req.params.id, req.user.id, req.user.role]
  );
  res.json({ ok: true });
});

// POST mark all as read
router.post('/mark-all-read', auth(), async (req, res) => {
  await pool.query(
    `UPDATE notifications SET read=TRUE
     WHERE user_id=$1 AND user_role=$2 AND read=FALSE`,
    [req.user.id, req.user.role]
  );
  res.json({ ok: true });
});

// DELETE one
router.delete('/:id', auth(), async (req, res) => {
  await pool.query(
    `DELETE FROM notifications WHERE id=$1 AND user_id=$2 AND user_role=$3`,
    [req.params.id, req.user.id, req.user.role]
  );
  res.json({ ok: true });
});

// Helper to create a notification (importable by other routes)
export async function createNotification({ user_id, user_role, type, title, text, link }) {
  await pool.query(
    `INSERT INTO notifications (user_id, user_role, type, title, text, link)
     VALUES ($1,$2,$3,$4,$5,$6)`,
    [user_id, user_role, type, title, text, link || null]
  );
}

export default router;
