CREATE TABLE IF NOT EXISTS customers (
  username TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS prostheses (
  prosthesis_id TEXT PRIMARY KEY,
  username TEXT NOT NULL REFERENCES customers(username),
  model TEXT NOT NULL,
  activated_at DATE NOT NULL
);

INSERT INTO customers (username, email, full_name) VALUES
  ('prothetic1', 'prothetic1@example.com', 'Prothetic One'),
  ('prothetic2', 'prothetic2@example.com', 'Prothetic Two'),
  ('prothetic3', 'prothetic3@example.com', 'Prothetic Three')
ON CONFLICT (username) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name;

INSERT INTO prostheses (prosthesis_id, username, model, activated_at) VALUES
  ('bp-arm-1001', 'prothetic1', 'Bionic Arm Pro', '2026-05-12'),
  ('bp-hand-1002', 'prothetic1', 'Bionic Hand Lite', '2026-06-01'),
  ('bp-leg-2001', 'prothetic2', 'Bionic Leg Pro', '2026-04-22'),
  ('bp-arm-3001', 'prothetic3', 'Bionic Arm Pro', '2026-06-08')
ON CONFLICT (prosthesis_id) DO UPDATE SET
  username = EXCLUDED.username,
  model = EXCLUDED.model,
  activated_at = EXCLUDED.activated_at;
