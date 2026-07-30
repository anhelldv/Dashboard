/*
# Create "negocios" table for the public Velionix dashboard

1. Purpose
   - Stores business records ("negocios") that the public Velionix statistics dashboard reads from.
   - The dashboard is a read-only, no-auth public page that uses ONLY the Supabase anon key.
   - No INSERT/UPDATE/DELETE is performed by the dashboard app; write protection is enforced by RLS.

2. New Tables
   - `negocios`
     - `id`            uuid PRIMARY KEY
     - `nombre`        text NOT NULL          -> business name
     - `categoria`     text                   -> category (nullable)
     - `telefono`      text                   -> phone (nullable)
     - `email`         text                   -> email (nullable)
     - `website`       text                   -> website URL (nullable)
     - `direccion`     text                   -> address (nullable)
     - `created_at`    timestamptz DEFAULT now()

3. Security (RLS)
   - Enable RLS on `negocios`.
   - SELECT policy for `anon, authenticated` so the public anon-key dashboard can read all rows.
   - NO insert/update/delete policies are created: the table is intentionally read-only for the
     anon role. Any future write access must be added explicitly as a separate, deliberate policy.
     This is the RLS-enforced write protection the dashboard code comments reference.
*/

CREATE TABLE IF NOT EXISTS negocios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  categoria text,
  telefono text,
  email text,
  website text,
  direccion text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE negocios ENABLE ROW LEVEL SECURITY;

-- Read-only access for the public anon-key dashboard (and authenticated users if added later).
DROP POLICY IF EXISTS "anon_read_negocios" ON negocios;
CREATE POLICY "anon_read_negocios"
ON negocios FOR SELECT
TO anon, authenticated
USING (true);

-- NOTE: No INSERT / UPDATE / DELETE policies are defined on purpose.
-- The dashboard performs READ operations only. Write protection relies entirely on RLS:
-- without explicit policies for INSERT/UPDATE/DELETE, the anon role cannot mutate this table.
