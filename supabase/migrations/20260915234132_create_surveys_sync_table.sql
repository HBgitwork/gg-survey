/*
# Create surveys table for background sync

1. New Tables
- `surveys` — stores synced copies of local survey records from the field app.
  - `id` (text, primary key) — the local IndexedDB record id, used as the upsert key.
  - `engineer_id` (uuid, NOT NULL, DEFAULT auth.uid()) — the anonymous user who created the survey. FK to auth.users.
  - `job_ref` (text) — job / reference number.
  - `site_name` (text) — site name.
  - `surveyed_by` (text) — who surveyed it.
  - `survey_date` (text) — date of the survey.
  - `status` (text) — DRAFT or SUBMITTED.
  - `sample` (boolean, default false) — whether the record contains sample/demo data.
  - `answers` (jsonb) — the full answers object from the survey form.
  - `device_updated_at` (timestamptz) — the local updatedAt timestamp from the device.
  - `created_at` (timestamptz, default now()) — when the row was first synced.
2. Security
- Enable RLS on `surveys`.
- Owner-scoped CRUD: each authenticated user can only access rows where engineer_id matches their auth.uid().
- The app uses anonymous auth (signInAnonymously), so users have a session and auth.uid() returns their id.
- 4 separate policies (select/insert/update/delete), all scoped TO authenticated with engineer_id = auth.uid().
3. Important notes
- IndexedDB on the device remains the source of truth. This table is a read-only copy for the office.
- The app upserts rows here; it never reads from or depends on this table for form functionality.
- If the network is unavailable, sync is skipped silently and the app continues normally.
*/

CREATE TABLE IF NOT EXISTS surveys (
  id text PRIMARY KEY,
  engineer_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  job_ref text,
  site_name text,
  surveyed_by text,
  survey_date text,
  status text,
  sample boolean NOT NULL DEFAULT false,
  answers jsonb,
  device_updated_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE surveys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_surveys" ON surveys;
CREATE POLICY "select_own_surveys" ON surveys FOR SELECT
  TO authenticated USING (auth.uid() = engineer_id);

DROP POLICY IF EXISTS "insert_own_surveys" ON surveys;
CREATE POLICY "insert_own_surveys" ON surveys FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = engineer_id);

DROP POLICY IF EXISTS "update_own_surveys" ON surveys;
CREATE POLICY "update_own_surveys" ON surveys FOR UPDATE
  TO authenticated USING (auth.uid() = engineer_id) WITH CHECK (auth.uid() = engineer_id);

DROP POLICY IF EXISTS "delete_own_surveys" ON surveys;
CREATE POLICY "delete_own_surveys" ON surveys FOR DELETE
  TO authenticated USING (auth.uid() = engineer_id);
