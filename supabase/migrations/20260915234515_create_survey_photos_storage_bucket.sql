/*
# Create survey-photos storage bucket and policies

1. New Storage Bucket
- `survey-photos` — private bucket (public = false) for uploaded survey photographs.
- Files are stored at path `<user id>/<survey id>/<photo id>.jpg`.

2. Security
- Storage policies on storage.objects for the survey-photos bucket:
  - INSERT: authenticated users can upload files only into a path starting with their own user id.
  - SELECT: authenticated users can read only their own files.
  - DELETE: authenticated users can delete only their own files.
- The first path segment (storage.foldername(name))[1] is the user id, which enforces per-user isolation.

3. Important notes
- The bucket is private; files are only accessible by the owning user through authenticated RLS.
- Upload paths follow the pattern `<uid>/<survey_id>/<photo_id>.jpg`.
*/

INSERT INTO storage.buckets (id, name, public)
VALUES ('survey-photos', 'survey-photos', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "survey_photos_upload_own" ON storage.objects;
CREATE POLICY "survey_photos_upload_own" ON storage.objects FOR INSERT
  TO authenticated WITH CHECK (
    bucket_id = 'survey-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "survey_photos_read_own" ON storage.objects;
CREATE POLICY "survey_photos_read_own" ON storage.objects FOR SELECT
  TO authenticated USING (
    bucket_id = 'survey-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "survey_photos_delete_own" ON storage.objects;
CREATE POLICY "survey_photos_delete_own" ON storage.objects FOR DELETE
  TO authenticated USING (
    bucket_id = 'survey-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
