import express from 'express';
import { pool } from '../db.js';
import { auth } from '../middleware/auth.js';

const router = express.Router();

// Global search across content
router.get('/', auth(), async (req, res) => {
  const q = (req.query.q || '').trim();
  if (!q) return res.json({ results: [] });

  const like = `%${q.toLowerCase()}%`;
  const isEntity = ['TIE', 'NECTA'].includes(req.user.role);
  const isReviewer = req.user.role === 'REVIEWER';

  try {
    let query;
    let params;

    if (isEntity || isReviewer) {
      query = `
        SELECT c.id, c.title, c.subject, c.topic, c.level, c.badge, c.status, c.created_at,
               COALESCE(u.full_name, ae.entity_name) AS author_name
        FROM content c
        LEFT JOIN users u ON u.id = c.author_id AND c.author_role = 'SCHOOL'
        LEFT JOIN authorized_entities ae ON ae.id = c.author_id AND c.author_role IN ('TIE','NECTA')
        WHERE LOWER(c.title) LIKE $1
           OR LOWER(c.subject) LIKE $1
           OR LOWER(c.topic) LIKE $1
           OR LOWER(LEFT(c.body, 2000)) LIKE $1
        ORDER BY c.created_at DESC
        LIMIT 30
      `;
      params = [like];
    } else {
      query = `
        SELECT c.id, c.title, c.subject, c.topic, c.level, c.badge, c.status, c.created_at,
               u.full_name AS author_name
        FROM content c
        LEFT JOIN users u ON u.id = c.author_id
        WHERE c.author_id = $2 AND c.author_role = 'SCHOOL'
          AND (LOWER(c.title) LIKE $1
            OR LOWER(c.subject) LIKE $1
            OR LOWER(c.topic) LIKE $1
            OR LOWER(LEFT(c.body, 2000)) LIKE $1)
        ORDER BY c.created_at DESC
        LIMIT 30
      `;
      params = [like, req.user.id];
    }

    const result = await pool.query(query, params);
    res.json({ results: result.rows });
  } catch (e) {
    console.error('[search] error:', e.message);
    res.status(500).json({ error: e.message, results: [] });
  }
});

export default router;
