import express from 'express';
import { pool } from '../db.js';
import { auth } from '../middleware/auth.js';
import { createNotification } from './notifications.js';

const router = express.Router();

// ============================================================
// POST /  — Contributor uploads content
//   TIE / NECTA → publishes immediately
//   SCHOOL      → goes to review queue
// ============================================================
router.post('/', auth(['TIE', 'NECTA', 'SCHOOL']), async (req, res) => {
  const { title, subject, level, topic, body } = req.body;

  if (!title || !subject || !level || !topic || !body) {
    return res.status(400).json({ error: 'Missing fields' });
  }

  // Auto-badge & status logic
  let badge, status;
  if (req.user.role === 'TIE') { badge = 'TIE-Official'; status = 'approved'; }
  else if (req.user.role === 'NECTA') { badge = 'NECTA-Official'; status = 'approved'; }
  else { badge = 'Pending'; status = 'pending'; }

  // For TIE/NECTA, author_id refers to an entity; for SCHOOL, to a user.
  const result = await pool.query(
    `INSERT INTO content (title, subject, level, topic, body, badge, status, author_id, author_role)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
    [title, subject, level, topic, body, badge, status, req.user.id, req.user.role]
  );

  const content = result.rows[0];

  // ============================================================
  // Notifications
  // ============================================================
  try {
    if (req.user.role === 'TIE' || req.user.role === 'NECTA') {
      // Direct publish → self-notification
      const entityLabel = req.user.role === 'TIE' ? 'curriculum' : 'report';
      await createNotification({
        user_id: req.user.id,
        user_role: req.user.role,
        type: 'approval',
        title: `${entityLabel.charAt(0).toUpperCase() + entityLabel.slice(1)} published`,
        text: `Your ${entityLabel} "${title}" was published successfully.`,
        link: '/my-content',
      });
    } else if (req.user.role === 'SCHOOL') {
      // School submitted → self-notification
      await createNotification({
        user_id: req.user.id,
        user_role: 'SCHOOL',
        type: 'system',
        title: 'Submitted for review',
        text: `"${title}" is awaiting TIE review.`,
        link: '/my-content',
      });

      // Also notify every reviewer
      const reviewers = await pool.query(`SELECT id FROM users WHERE role='REVIEWER'`);
      for (const r of reviewers.rows) {
        await createNotification({
          user_id: r.id,
          user_role: 'REVIEWER',
          type: 'review',
          title: 'New submission',
          text: `A school submitted "${title}" (${subject}, ${level}) for review.`,
          link: '/review',
        });
      }
    }
  } catch (err) {
    console.error('[content] notification create failed:', err.message);
    // Don't fail the upload if notification fails
  }

  res.json(content);
});

// ============================================================
// GET /  — List content, scoped by role
// ============================================================
router.get('/', auth(), async (req, res) => {
  let rows;

  if (req.user.role === 'REVIEWER') {
    // Reviewers see everything
    rows = await pool.query(
      `SELECT c.*,
              COALESCE(u.full_name, ae.entity_name) AS author_name,
              u.school_name
       FROM content c
       LEFT JOIN users u ON u.id = c.author_id AND c.author_role != 'TIE' AND c.author_role != 'NECTA'
       LEFT JOIN authorized_entities ae ON ae.id = c.author_id AND c.author_role IN ('TIE', 'NECTA')
       ORDER BY c.created_at DESC`
    );
  } else if (req.user.role === 'TIE' || req.user.role === 'NECTA') {
    // Entities see their own uploaded content
    rows = await pool.query(
      `SELECT c.*, ae.entity_name AS author_name
       FROM content c
       LEFT JOIN authorized_entities ae ON ae.id = c.author_id
       WHERE c.author_id = $1 AND c.author_role = $2
       ORDER BY c.created_at DESC`,
      [req.user.id, req.user.role]
    );
  } else {
    // Schools see their own
    rows = await pool.query(
      `SELECT c.*, u.full_name AS author_name
       FROM content c
       LEFT JOIN users u ON u.id = c.author_id
       WHERE c.author_id = $1 AND c.author_role = 'SCHOOL'
       ORDER BY c.created_at DESC`,
      [req.user.id]
    );
  }

  res.json(rows.rows);
});

// ============================================================
// GET /:id  — Get one
// ============================================================
router.get('/:id', auth(), async (req, res) => {
  const result = await pool.query(
    `SELECT c.*,
            COALESCE(u.full_name, ae.entity_name) AS author_name,
            u.school_name
     FROM content c
     LEFT JOIN users u ON u.id = c.author_id AND c.author_role = 'SCHOOL'
     LEFT JOIN authorized_entities ae ON ae.id = c.author_id AND c.author_role IN ('TIE','NECTA')
     WHERE c.id = $1`,
    [req.params.id]
  );
  if (!result.rows.length) return res.status(404).json({ error: 'Not found' });
  res.json(result.rows[0]);
});

// ============================================================
// DELETE /:id  — Delete own content
// ============================================================
router.delete('/:id', auth(['TIE', 'NECTA', 'SCHOOL']), async (req, res) => {
  const check = await pool.query('SELECT * FROM content WHERE id=$1', [req.params.id]);
  if (!check.rows.length) return res.status(404).json({ error: 'Not found' });
  if (check.rows[0].author_id !== req.user.id) {
    return res.status(403).json({ error: 'Not your content' });
  }
  await pool.query('DELETE FROM content WHERE id=$1', [req.params.id]);
  res.json({ ok: true });
});

export default router;
