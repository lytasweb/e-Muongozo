CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,           -- can reference users OR authorized_entities
  user_role VARCHAR(20) NOT NULL,     -- 'SCHOOL' | 'REVIEWER' | 'TIE' | 'NECTA'
  type VARCHAR(30) NOT NULL,          -- 'approval' | 'review' | 'system' | 'rejection'
  title VARCHAR(255) NOT NULL,
  text TEXT NOT NULL,
  link VARCHAR(255),                  -- optional frontend route
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notif_user ON notifications(user_id, user_role, read);
