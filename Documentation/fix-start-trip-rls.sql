-- Fix RLS for Start Trip + Storage Uploads

-- =========================
-- Trips table policy
-- =========================
-- Ensure drivers can update their assigned trips
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Drivers can update their assigned trips" ON trips;
CREATE POLICY "Drivers can update their assigned trips"
ON trips
FOR UPDATE
TO authenticated
USING (
    driver_id = auth.uid()
)
WITH CHECK (
    driver_id = auth.uid()
);

-- =========================
-- Storage bucket policies
-- =========================
-- Allow authenticated users to upload and read trip photos in bucket "hello"
-- If policies already exist, drop them first.

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Trip photos - insert" ON storage.objects;
CREATE POLICY "Trip photos - insert"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'hello'
    AND (
        (storage.foldername(name))[1] = 'trips'
        OR (storage.foldername(name))[1] = 'refills'
    )
);

DROP POLICY IF EXISTS "Trip photos - select" ON storage.objects;
CREATE POLICY "Trip photos - select"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'hello'
);

-- Optional: allow updating/deleting uploaded trip photos
DROP POLICY IF EXISTS "Trip photos - update" ON storage.objects;
CREATE POLICY "Trip photos - update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'hello')
WITH CHECK (bucket_id = 'hello');

DROP POLICY IF EXISTS "Trip photos - delete" ON storage.objects;
CREATE POLICY "Trip photos - delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'hello');
