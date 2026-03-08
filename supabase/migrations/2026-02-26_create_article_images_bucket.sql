-- Create article-images storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('article-images', 'article-images', true)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies for article-images bucket
-- Allow authenticated users to upload images
CREATE POLICY article_images_upload_policy ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'article-images' AND
    auth.role() = 'authenticated'
  );

-- Allow public read access to article images
CREATE POLICY article_images_read_policy ON storage.objects
  FOR SELECT USING (
    bucket_id = 'article-images'
  );

-- Allow users to delete their own article images
CREATE POLICY article_images_delete_policy ON storage.objects
  FOR DELETE USING (
    bucket_id = 'article-images' AND
    auth.uid()::text = (storage.foldername(name))[2]
  );
