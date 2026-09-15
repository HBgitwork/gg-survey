/*
# Create survey_photos table

1. New Tables
- `survey_photos` — one row per uploaded photograph, linking back to the survey it belongs to.
  - `survey_id` (text, NOT NULL) — FK to surveys.id, ON DELETE CASCADE. Part of the composite primary key.
  - `engineer_id` (uuid, NOT NULL, DEFAULT auth.uid()) — the anonymous user who owns the photo. FK to auth.users. Part of RLS ownership checks.
  - `field_id` (text, NOT NULL) — the form field id the photo was attached to (e.g. "damagePhotos").
  - `photo_id` (text, NOT NULL) — the stable unique id generated on the device for each photo. Part of the composite primary key.
  - `storage_path` (text, NOT NULL) — the path in the survey-photos storage bucket, formatted as `<user id>/<survey id>/<photo id>.jpg`.
  - `caption` (text) — the caption typed on the device, if any.
  - `created_at` (timestamptz, DEFAULT now()) — when the row was first inserted.
  - Primary key: (survey_id, photo_id) — makes upserts idempotent so re-syncing a photo overwrites the existing row instead of creating duplicates.

2. Security
- Enable RLS on `survey_photos`.
- Owner-scoped CRUD: each authenticated user can only access rows where engineer_id matches their auth.uid().
- 4 separate policies (select/insert/update/delete), all scoped TO authenticated.

3. Important notes
- IndexedDB on the device remains the source of truth. Photos stay as data URLs locally for offline PDF generation.
- The survey_photos table is a read-only copy for the office.
- Photos are uploaded one at a time after the survey row is synced. A failed photo does not block the survey row.
- The composite primary key (survey_id, photo_id) makes upserts idempotent, so re-syncing is safe.
*/

CREATE TABLE IF NOT EXISTS survey_photos (
  survey_id text NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
  engineer_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  field_id text NOT NULL,
  photo_id text NOT NULL,
  storage_path text NOT NULL,
  caption text,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (survey_id, photo_id)
);

ALTER TABLE survey_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_survey_photos" ON survey_photos;
CREATE POLICY "select_own_survey_photos" ON survey_photos FOR SELECT
  TO authenticated USING (auth.uid() = engineer_id);

DROP POLICY IF EXISTS "insert_own_survey_photos" ON survey_photos;
CREATE POLICY "insert_own_survey_photos" ON survey_photos FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = engineer_id);

DROP POLICY IF EXISTS "update_own_survey_photos" ON survey_photos;
CREATE POLICY "update_own_survey_photos" ON survey_photos FOR UPDATE
  TO authenticated USING (auth.uid() = engineer_id) WITH CHECK (auth.uid() = engineer_id);

DROP POLICY IF EXISTS "delete_own_survey_photos" ON survey_photos;
CREATE POLICY "delete_own_survey_photos" ON survey_photos FOR DELETE
  TO authenticated USING (auth.uid() = engineer_id);
