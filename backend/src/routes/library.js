import express from 'express';
import { pool } from '../db.js';
import { auth } from '../middleware/auth.js';

const router = express.Router();

// ============================================================
// LIBRARY SOURCES
// Returns the catalog for a given source.
//
// Currently ALL sources return empty until real APIs exist.
// When TIE/NECTA integrate, replace the empty arrays with real
// HTTP calls (see examples at bottom of file).
// ============================================================

async function fetchTieLibrary() {
  // TODO: call real TIE API
  // const res = await fetch('https://api.tie.go.tz/v1/library', {
  //   headers: { Authorization: `Bearer ${process.env.TIE_API_KEY}` },
  // });
  // return res.json();
  return [];
}

async function fetchNectaLibrary() {
  // TODO: call real NECTA API
  // const res = await fetch('https://api.necta.go.tz/v1/archive', {
  //   headers: { Authorization: `Bearer ${process.env.NECTA_API_KEY}` },
  // });
  // return res.json();
  return [];
}

async function fetchApprovedLibrary() {
  try {
    const result = await pool.query(
      `SELECT id, title, subject, level, topic, badge, status, created_at
       FROM content
       WHERE status='approved'
       ORDER BY created_at DESC
       LIMIT 50`
    );
    return result.rows.map((r) => ({
      id: `content-${r.id}`,
      title: r.title,
      subject: r.subject,
      level: r.level,
      type: r.topic || 'Guide',
      size: '—',
      contentId: r.id,
    }));
  } catch {
    return [];
  }
}

// ============================================================
// GET /api/library/:source
//   source: 'tie' | 'necta' | 'approved'
// ============================================================
router.get('/:source', auth(), async (req, res) => {
  const source = String(req.params.source || '').toLowerCase();

  if (source === 'tie') {
    if (!['TIE', 'SCHOOL', 'REVIEWER'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Not authorized for TIE library' });
    }
    const items = await fetchTieLibrary();
    return res.json({ source: 'tie', items });
  }

  if (source === 'necta') {
    if (!['NECTA', 'SCHOOL', 'REVIEWER'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Not authorized for NECTA archive' });
    }
    const items = await fetchNectaLibrary();
    return res.json({ source: 'necta', items });
  }

  if (source === 'approved') {
    const items = await fetchApprovedLibrary();
    return res.json({ source: 'approved', items });
  }

  res.status(404).json({ error: 'Unknown source' });
});

export default router;
