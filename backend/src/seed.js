import bcrypt from 'bcryptjs';
import { pool } from './db.js';

async function seed() {
  // ─────────────────────────────────────────────────────────
  // Users
  // ─────────────────────────────────────────────────────────
  const users = [
    {
      email: 'school@emuongozo.tz',
      password: 'school123',
      full_name: 'Mussa Peter',
      role: 'SCHOOL',
      school_name: 'Ilboru High School',
      is_admin: false,
      approval_status: 'approved',
    },
    {
      email: 'reviewer@emuongozo.tz',
      password: 'review123',
      full_name: 'Anna Joseph',
      role: 'REVIEWER',
      is_admin: true,
      approval_status: 'approved',
    },
    // TIE staff
    {
      email: 'staff1@emuongozo.tz',
      password: 'staff123',
      full_name: 'Joseph Mwakyusa',
      role: 'TIESTAFF',
      is_admin: false,
      approval_status: 'approved',
    },
    {
      email: 'staff2@emuongozo.tz',
      password: 'staff123',
      full_name: 'Grace Kileo',
      role: 'TIESTAFF',
      is_admin: false,
      approval_status: 'approved',
    },
    // NECTA staff
    {
      email: 'necta1@emuongozo.tz',
      password: 'necta123',
      full_name: 'Samuel Mwakalinga',
      role: 'NECTA',
      is_admin: false,
      approval_status: 'approved',
    },
    {
      email: 'necta2@emuongozo.tz',
      password: 'necta123',
      full_name: 'Fatuma Ramadhani',
      role: 'NECTA',
      is_admin: false,
      approval_status: 'approved',
    },
  ];

  for (const u of users) {
    const hash = await bcrypt.hash(u.password, 10);
    await pool.query(
      `INSERT INTO users (email, password_hash, full_name, role, school_name, is_admin, approval_status)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       ON CONFLICT (email) DO UPDATE
         SET full_name = EXCLUDED.full_name,
             role = EXCLUDED.role,
             is_admin = EXCLUDED.is_admin,
             approval_status = EXCLUDED.approval_status`,
      [
        u.email, hash, u.full_name, u.role,
        u.school_name || null,
        u.is_admin === true,
        u.approval_status || 'approved',
      ]
    );
  }

  // ─────────────────────────────────────────────────────────
  // External entities
  // ─────────────────────────────────────────────────────────
  const entities = [
    {
      entity_type: 'TIE',
      entity_name: 'Tanzania Institute of Education',
      username: 'tie_official',
      password: 'tie_entity_2024',
      email: 'tie@emuongozo.tz',
    },
    {
      entity_type: 'NECTA',
      entity_name: 'National Examinations Council of Tanzania',
      username: 'necta_official',
      password: 'necta_entity_2024',
      email: 'necta@emuongozo.tz',
    },
  ];

  for (const e of entities) {
    const hash = await bcrypt.hash(e.password, 10);
    await pool.query(
      `INSERT INTO authorized_entities (entity_type, entity_name, username, password_hash, email, is_admin)
       VALUES ($1,$2,$3,$4,$5,TRUE)
       ON CONFLICT (username) DO UPDATE SET email = EXCLUDED.email, is_admin = TRUE`,
      [e.entity_type, e.entity_name, e.username, hash, e.email]
    );
  }

  // ─────────────────────────────────────────────────────────
  // Notifications
  // ─────────────────────────────────────────────────────────
  const school = await pool.query('SELECT id FROM users WHERE email=$1', ['school@emuongozo.tz']);
  if (school.rows.length) {
    const userId = school.rows[0].id;
    await pool.query('DELETE FROM notifications WHERE user_id=$1 AND user_role=$2', [userId, 'SCHOOL']);
    await pool.query(
      `INSERT INTO notifications (user_id, user_role, type, title, text, link, read)
       VALUES
         ($1,'SCHOOL','approval','Guide approved','Your "Bernoulli Principle" guide was approved by TIE.','/my-content',FALSE),
         ($1,'SCHOOL','review','New SIRA report','NECTA published a new SIRA report for Physics.','/dashboard',FALSE),
         ($1,'SCHOOL','system','Welcome to e-Muongozo','Start by uploading your first study guide.','/upload',TRUE)`,
      [userId]
    );
  }

  const tie = await pool.query('SELECT id FROM authorized_entities WHERE username=$1', ['tie_official']);
  if (tie.rows.length) {
    const entityId = tie.rows[0].id;
    await pool.query('DELETE FROM notifications WHERE user_id=$1 AND user_role=$2', [entityId, 'TIE']);
    await pool.query(
      `INSERT INTO notifications (user_id, user_role, type, title, text, link, read)
       VALUES
         ($1,'TIE','system','Welcome, TIE','You can now publish official curriculum directly.','/upload',FALSE),
         ($1,'TIE','review','3 pending submissions','Top schools have submitted new content for review.','/dashboard',FALSE)`,
      [entityId]
    );
  }

  const necta = await pool.query('SELECT id FROM authorized_entities WHERE username=$1', ['necta_official']);
  if (necta.rows.length) {
    const entityId = necta.rows[0].id;
    await pool.query('DELETE FROM notifications WHERE user_id=$1 AND user_role=$2', [entityId, 'NECTA']);
    await pool.query(
      `INSERT INTO notifications (user_id, user_role, type, title, text, link, read)
       VALUES
         ($1,'NECTA','system','Welcome, NECTA','You can now publish SIRA diagnostics and answering schemes.','/upload',FALSE),
         ($1,'NECTA','review','New exam cycle','CSEE 2024 examination cycle is now open for submissions.','/upload',FALSE)`,
      [entityId]
    );
  }

  console.log('');
  console.log('✅ Seeded users:');
  console.log('   school@emuongozo.tz  / school123  (SCHOOL)');
  console.log('   reviewer@emuongozo.tz / review123 (REVIEWER, admin)');
  console.log('   staff1@emuongozo.tz   / staff123  (TIESTAFF)');
  console.log('   staff2@emuongozo.tz   / staff123  (TIESTAFF)');
  console.log('   necta1@emuongozo.tz   / necta123  (NECTA)');
  console.log('   necta2@emuongozo.tz   / necta123  (NECTA)');
  console.log('');
  console.log('✅ Seeded entities:');
  console.log('   TIE   → tie_official / tie_entity_2024');
  console.log('   NECTA → necta_official / necta_entity_2024');
  console.log('');
  process.exit(0);
}

seed();
