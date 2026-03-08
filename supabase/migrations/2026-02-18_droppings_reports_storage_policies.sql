-- ============================================
-- Storage Bucket and Policies for Droppings Reports
-- ============================================
-- This migration creates the storage bucket and policies for droppings reports

-- ============================================
-- 1. Create Storage Bucket
-- ============================================
-- Note: Run this in Supabase SQL Editor or create via Dashboard
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'droppings-reports',
  'droppings-reports',
  true,
  5242880, -- 5MB file size limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 2. Storage Policies
-- ============================================

-- Policy 1: Public can view droppings report images
CREATE POLICY "Public can view droppings reports"
ON storage.objects FOR SELECT
USING (bucket_id = 'droppings-reports');

-- Policy 2: Authenticated users can upload their own droppings reports
CREATE POLICY "Authenticated users can upload droppings reports"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'droppings-reports' 
  AND auth.role() = 'authenticated'
);

-- Policy 3: Users can update their own uploads
CREATE POLICY "Users can update their own droppings reports"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'droppings-reports' 
  AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'droppings-reports' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy 4: Users can delete their own uploads
CREATE POLICY "Users can delete their own droppings reports"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'droppings-reports' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Run these to verify the policies were created successfully

-- Check if bucket was created
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE id = 'droppings-reports';

-- Check storage policies
SELECT policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND policyname LIKE '%droppings%';

-- ============================================
-- ROLLBACK (if needed)
-- ============================================
-- DROP POLICY IF EXISTS "Public can view droppings reports" ON storage.objects;
-- DROP POLICY IF EXISTS "Authenticated users can upload droppings reports" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can update their own droppings reports" ON storage.objects;
-- DROP POLICY IF EXISTS "Users can delete their own droppings reports" ON storage.objects;
-- DELETE FROM storage.buckets WHERE id = 'droppings-reports';
