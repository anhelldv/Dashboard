/*
# Create "leads" table for the Velionix prospection dashboard

1. Purpose
   - Stores commercial prospection leads processed by the Velionix automation workflow.
   - The public dashboard reads this table (READ ONLY) using the Supabase anon key.
   - No INSERT/UPDATE/DELETE from the dashboard; write protection is enforced by RLS.

2. New Tables
   - `leads`
     - id                    integer PRIMARY KEY (auto-increment)
     - nombre               text NOT NULL
     - categoria            text
     - email                text
     - telefono             text
     - website              text
     - direccion            text
     - whatsapp             text
     - instagram            text
     - facebook             text
     - ssl                  boolean
     - wordpress            boolean
     - job_id               text
     - area                 text
     - nivel_dato           text  ('completo' | 'basico')
     - ranking              integer (1-10, necesidad de automatizacion)
     - facilidad_conversion integer (1-10)
     - puntaje_final         numeric (promedio de ranking y facilidad)
     - problemas_detectados text
     - angulo_venta         text
     - motivo_ranking       text
     - reputacion_resumen   text
     - puntos_fuertes       text
     - areas_mejora         text
     - presencia_redes     text
     - recomendacion        text
     - email_asunto         text
     - email_cuerpo         text
     - estado               text
     - intentos_seguimiento integer default 0
     - clasificacion        text
     - fecha_recibido       timestamptz
     - fecha_analizado      timestamptz

3. Security (RLS)
   - Enable RLS on `leads`.
   - SELECT policy for `anon, authenticated` so the public anon-key dashboard can read all rows.
   - NO insert/update/delete policies: the table is intentionally read-only for the anon role.
*/

CREATE TABLE IF NOT EXISTS leads (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre text NOT NULL,
  categoria text,
  email text,
  telefono text,
  website text,
  direccion text,
  whatsapp text,
  instagram text,
  facebook text,
  ssl boolean,
  wordpress boolean,
  job_id text,
  area text,
  nivel_dato text,
  ranking integer,
  facilidad_conversion integer,
  puntaje_final numeric(4,1),
  problemas_detectados text,
  angulo_venta text,
  motivo_ranking text,
  reputacion_resumen text,
  puntos_fuertes text,
  areas_mejora text,
  presencia_redes text,
  recomendacion text,
  email_asunto text,
  email_cuerpo text,
  estado text DEFAULT 'nuevo',
  intentos_seguimiento integer DEFAULT 0,
  clasificacion text,
  fecha_recibido timestamptz DEFAULT now(),
  fecha_analizado timestamptz
);

ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

-- Read-only access for the public anon-key dashboard.
DROP POLICY IF EXISTS "anon_read_leads" ON leads;
CREATE POLICY "anon_read_leads"
ON leads FOR SELECT
TO anon, authenticated
USING (true);

-- NOTE: No INSERT / UPDATE / DELETE policies are defined on purpose.
-- The dashboard performs READ operations only. Write protection relies entirely on RLS.
