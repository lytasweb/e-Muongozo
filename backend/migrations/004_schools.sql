-- Add approval workflow columns to users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) DEFAULT 'pending'
    CHECK (approval_status IN ('pending', 'approved', 'rejected'));

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS approved_by INTEGER;

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Existing users: mark them approved so demo accounts still work
UPDATE users
   SET approval_status = 'approved'
 WHERE approval_status IS NULL;
