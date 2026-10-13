-- ============================================================
-- Migration 005 — Members, admin flags, TIESTAFF role, suspensions
-- ============================================================

-- 1. Admin flags
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

ALTER TABLE authorized_entities
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- 2. Allow TIESTAFF role + suspended status
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
  CHECK (role IN ('TIE', 'TIESTAFF', 'NECTA', 'REVIEWER', 'SCHOOL'));

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_approval_status_check;
ALTER TABLE users ADD CONSTRAINT users_approval_status_check
  CHECK (approval_status IN ('pending', 'approved', 'rejected', 'suspended'));

-- 3. Suspension audit columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspended_by INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspended_reason TEXT;

-- 4. Mark current TIE + NECTA entities as admins
UPDATE authorized_entities SET is_admin = TRUE WHERE entity_type IN ('TIE', 'NECTA');

-- 5. Mark the reviewer as a TIE reviewer (still has REVIEWER role)
UPDATE users SET is_admin = TRUE WHERE email = 'reviewer@emuongozo.tz';

-- 6. Backfill approval_status for existing schools
UPDATE users SET approval_status = 'approved'
 WHERE role = 'SCHOOL' AND (approval_status IS NULL OR approval_status = '');
