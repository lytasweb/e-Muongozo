CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL CHECK (role IN ('TIE', 'NECTA', 'SCHOOL', 'REVIEWER')),
  school_name VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE content (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  subject VARCHAR(100) NOT NULL,
  level VARCHAR(50) NOT NULL CHECK (level IN ('Primary', 'O-Level', 'A-Level')),
  topic VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  badge VARCHAR(50) NOT NULL CHECK (badge IN ('TIE-Official', 'NECTA-Official', 'TIE-Reviewed', 'Pending')),
  status VARCHAR(50) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'approved', 'rejected')),
  author_id INTEGER NOT NULL,
  author_role VARCHAR(50) NOT NULL CHECK (author_role IN ('TIE', 'NECTA', 'SCHOOL')),
  reviewer_id INTEGER REFERENCES users(id),
  review_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_content_status ON content(status);
CREATE INDEX idx_content_author ON content(author_id, author_role);
