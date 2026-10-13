import express from 'express';
import { pool } from '../db.js';
import { auth } from '../middleware/auth.js';

const router = express.Router();

// Get pending content for reviewer
router.get('/pending', auth(['REVIEWER']), async (req, res) => {
  const result = await pool.query(
    `SELECT c.*, u.full_name AS author_name, u.school_name
     FROM content c JOIN users u ON u.id = c.author_id
     WHERE c.status='pending'
     ORDER BY c.created_at ASC`
  );
  res.json(result.rows);
});

// Approve or reject
router.post('/:id', auth(['REVIEWER']), async (req, res) => {
  const { action, notes } = req.body; // action: 'approve' | 'reject'
  if (!['approve', 'reject'].includes(action)) {
    return res.status(400).json({ error: 'Invalid action' });
  }
  const status = action === 'approve' ? 'approved' : 'rejected';
  const badge = action === 'approve' ? 'TIE-Reviewed' : 'Pending';

  const result = await pool.query(
    `UPDATE content SET status=$1, badge=$2, reviewer_id=$3, review_notes=$4, updated_at=NOW()
     WHERE id=$5 RETURNING *`,
    [status, badge, req.user.id, notes || null, req.params.id]
  );
  if (!result.rows.length) return res.status(404).json({ error: 'Not found' });
  res.json(result.rows[0]);
});

export default router;