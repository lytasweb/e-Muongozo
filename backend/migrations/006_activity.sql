-- Track last login for users and entities
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP;
ALTER TABLE authorized_entities ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP;
