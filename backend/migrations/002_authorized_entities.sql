CREATE TABLE IF NOT EXISTS authorized_entities (
  id SERIAL PRIMARY KEY,
  entity_type VARCHAR(20) NOT NULL CHECK (entity_type IN ('TIE', 'NECTA')),
  entity_name VARCHAR(255) NOT NULL,
  username VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS entity_authorizations (
  id SERIAL PRIMARY KEY,
  entity_id INTEGER REFERENCES authorized_entities(id),
  authorized BOOLEAN NOT NULL,
  code_used VARCHAR(6),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS otp_codes (
  id SERIAL PRIMARY KEY,
  entity_id INTEGER NOT NULL REFERENCES authorized_entities(id),
  code VARCHAR(6) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_entity_code ON otp_codes(entity_id, code, used);
