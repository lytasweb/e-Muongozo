import express from 'express';
import { pool } from '../db.js';

const router = express.Router();

// ============================================================
// Cache of subject name -> id and id -> name.
// Refreshed on every /subjects call so new uploads appear.
// ============================================================
let SUBJECT_MAP = {};      // id (1-based index) -> name
let SUBJECT_LIST = [];     // [{ id, name, level, icon, color }]

async function loadSubjects() {
  // Every distinct (subject, level) pair that has approved content.
  const { rows } = await pool.query(`
    SELECT
      subject AS name,
      level,
      COUNT(*)::int AS topic_count
    FROM content
    WHERE status = 'approved'
    GROUP BY subject, level
    ORDER BY subject, level
  `);

  SUBJECT_LIST = rows.map((r, i) => ({
    id: i + 1,
    name: r.name,
    level: r.level,
    icon: iconFor(r.name),
    color: colorFor(r.name),
    topic_count: r.topic_count,
  }));

  SUBJECT_MAP = {};
  for (const s of SUBJECT_LIST) SUBJECT_MAP[s.id] = s.name;
}

function iconFor(name) {
  const map = {
    Physics: '⚛️', Chemistry: '🧪', Biology: '🧬',
    Mathematics: '📐', Kiswahili: '📖', English: '📘',
    Geography: '🌍', History: '🏛️', French: '🇫🇷',
    Civics: '🏛️', 'Book Keeping': '📊', Commerce: '💼',
    Agriculture: '🌾', 'Computer Science': '💻',
  };
  return map[name] || '📚';
}

function colorFor(name) {
  const map = {
    Physics: '#3B82F6', Chemistry: '#10B981', Biology: '#8B5CF6',
    Mathematics: '#F59E0B', Kiswahili: '#EC4899', English: '#06B6D4',
    Geography: '#14B8A6', History: '#F97316', French: '#E11D48',
    Civics: '#0EA5E9', 'Book Keeping': '#16A34A', Commerce: '#7C3AED',
    Agriculture: '#CA8A04', 'Computer Science': '#334155',
  };
  return map[name] || '#2563EB';
}

// ============================================================
// Helper: detect [file:mime]data:...;base64,... in the body
// ============================================================
function detectFile(body) {
  if (!body) return null;
  const match = String(body).match(/\[file:([^\]]+)\](data:[\s\S]+)/);
  if (!match) return null;
  return { mime: match[1], dataUrl: match[2] };
}

function extractPlainText(body) {
  if (!body) return '';
  const str = String(body);
  const markerIdx = str.indexOf('[file:');
  if (markerIdx === -1) return str.trim();
  return str.slice(0, markerIdx).trim();
}

// ============================================================
// GET /api/mobile/subjects
// ============================================================
router.get('/subjects', async (req, res) => {
  try {
    await loadSubjects();
    res.json({ subjects: SUBJECT_LIST });
  } catch (e) {
    console.error('GET /mobile/subjects', e);
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// GET /api/mobile/subjects/:id/terms
// ============================================================
router.get('/subjects/:id/terms', async (req, res) => {
  try {
    const subjectId = parseInt(req.params.id, 10);
    if (!SUBJECT_LIST.length) await loadSubjects();

    const subject = SUBJECT_LIST.find((s) => s.id === subjectId);
    if (!subject) {
      return res.status(404).json({ error: 'Unknown subject' });
    }

    const stats = await pool.query(`
      SELECT
        COUNT(*)::int AS total,
        COALESCE(SUM(LENGTH(body)), 0)::bigint AS total_bytes
      FROM content
      WHERE status = 'approved' AND subject = $1
    `, [subject.name]);

    const total = stats.rows[0]?.total || 0;
    const totalBytes = Number(stats.rows[0]?.total_bytes || 0);
    const perTerm = total === 0 ? 0 : Math.ceil(total / 3);

    const terms = [1, 2, 3].map((t) => {
      const remaining = Math.max(0, total - (t - 1) * perTerm);
      const count = perTerm === 0 ? 0 : Math.min(perTerm, remaining);
      const sizeBytes =
          total === 0 ? 0 : Math.round((count / total) * totalBytes);
      return {
        subject_id: subjectId,
        term: t,
        topic_count: count,
        size_bytes: sizeBytes,
      };
    });

    res.json({ terms, subject_name: subject.name });
  } catch (e) {
    console.error('GET /mobile/subjects/:id/terms', e);
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// GET /api/mobile/terms/:subjectId/:term
// ============================================================
router.get('/terms/:subjectId/:term', async (req, res) => {
  try {
    const subjectId = parseInt(req.params.subjectId, 10);
    const term = parseInt(req.params.term, 10);
    if (!SUBJECT_LIST.length) await loadSubjects();

    const subject = SUBJECT_LIST.find((s) => s.id === subjectId);
    if (!subject) {
      return res.status(404).json({ error: 'Unknown subject' });
    }

    const result = await pool.query(`
      SELECT id, subject, level, title, body, badge, review_notes,
             teaching_schemes, recommended_books
      FROM content
      WHERE status = 'approved' AND subject = $1
      ORDER BY created_at DESC
      LIMIT 50
    `, [subject.name]);

    if (!result.rows.length) {
      return res.json({
        topics: [],
        subject_name: subject.name,
        message: `No approved content for ${subject.name}`,
      });
    }

    const perTerm = Math.max(1, Math.ceil(result.rows.length / 3));
    const startIdx = (term - 1) * perTerm;
    const endIdx = startIdx + perTerm;
    const termRows = result.rows.slice(startIdx, endIdx);

    const topics = termRows.map((row) => {
      const blocks = [];

      if (row.review_notes) {
        blocks.push({ type: 'warning', content: row.review_notes, order: 0 });
      }

      const plainText = extractPlainText(row.body);
      if (plainText) {
        const paragraphs = plainText
            .split(/\n{2,}/)
            .map((p) => p.trim())
            .filter(Boolean);
        paragraphs.forEach((p, i) => {
          blocks.push({ type: 'text', content: p, order: i + 1 });
        });
      }

      const file = detectFile(row.body);
      if (file) {
        const kind =
            file.mime === 'application/pdf' ? 'pdf'
          : file.mime.startsWith('image/') ? 'image'
          : 'file';
        blocks.push({
          type: kind,
          content: `attached:${file.mime}`,
          order: 999,
        });
      }

      return {
        id: row.id,
        subject_id: subjectId,
        term: term,
        title: row.title,
        badge: row.badge,
        blocks,
        teaching_schemes: row.teaching_schemes || [],
        recommended_books: row.recommended_books || [],
      };
    });

    res.json({ topics, subject_name: subject.name });
  } catch (e) {
    console.error('GET /mobile/terms/:subjectId/:term', e);
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// GET /api/mobile/topics/:id/pdf
// ============================================================
router.get('/topics/:id/pdf', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const result = await pool.query(
      'SELECT id, title, body FROM content WHERE id = $1 AND status = $2',
      [id, 'approved']
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Topic not found' });
    }

    const body = String(result.rows[0].body || '');
    const marker = body.match(
        /\[file:application\/pdf\]data:application\/pdf;base64,([\s\S]+)/);
    if (!marker) {
      return res.status(415).json({ error: 'Not a PDF topic' });
    }

    const base64 = marker[1].replace(/\s+$/, '');
    const buffer = Buffer.from(base64, 'base64');

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Length', buffer.length);
    res.setHeader('Content-Disposition',
        `inline; filename="topic-${id}.pdf"`);
    res.end(buffer);
  } catch (e) {
    console.error('GET /mobile/topics/:id/pdf', e);
    res.status(500).json({ error: e.message });
  }
});

// ============================================================
// GET /api/mobile/health
// ============================================================
router.get('/health', (_, res) => {
  res.json({ ok: true, version: '1.0.0' });
});

export default router;
