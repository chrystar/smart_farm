-- ============================================
-- Droppings Reports Responses and Notifications System
-- ============================================
-- This migration creates tables for vet responses and user notifications

-- ============================================
-- 1. Create droppings_reports_responses table
-- ============================================
CREATE TABLE IF NOT EXISTS droppings_reports_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID NOT NULL REFERENCES droppings_reports(id) ON DELETE CASCADE,
  vet_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  cause TEXT NOT NULL,
  medications TEXT NOT NULL,
  medication_image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_responses_report_id ON droppings_reports_responses(report_id);
CREATE INDEX IF NOT EXISTS idx_responses_vet_id ON droppings_reports_responses(vet_id);

-- ============================================
-- 2. Create notifications table
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL, -- 'report_response', 'system', 'alert', etc.
  reference_id UUID, -- Can reference report_id, response_id, etc.
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- ============================================
-- 3. Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS on both tables
ALTER TABLE droppings_reports_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Responses Policies
-- Vets can insert their own responses
CREATE POLICY "Vets can create responses"
ON droppings_reports_responses FOR INSERT
WITH CHECK (auth.uid() = vet_id);

-- Users can view responses to their reports
CREATE POLICY "Users can view responses to their reports"
ON droppings_reports_responses FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM droppings_reports
    WHERE droppings_reports.id = droppings_reports_responses.report_id
    AND droppings_reports.user_id = auth.uid()
  )
);

-- Vets can view all responses (for their dashboard)
CREATE POLICY "Vets can view all responses"
ON droppings_reports_responses FOR SELECT
USING (auth.uid() = vet_id);

-- Vets can update their own responses
CREATE POLICY "Vets can update their own responses"
ON droppings_reports_responses FOR UPDATE
USING (auth.uid() = vet_id)
WITH CHECK (auth.uid() = vet_id);

-- Notifications Policies
-- Users can view their own notifications
CREATE POLICY "Users can view their own notifications"
ON notifications FOR SELECT
USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update their own notifications"
ON notifications FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- System can insert notifications (this will be done via service role)
CREATE POLICY "System can insert notifications"
ON notifications FOR INSERT
WITH CHECK (true);

-- ============================================
-- 4. Create function to automatically create notification on response
-- ============================================
CREATE OR REPLACE FUNCTION create_notification_on_response()
RETURNS TRIGGER AS $$
DECLARE
  report_user_id UUID;
  batch_name TEXT;
BEGIN
  -- Get the user_id from the report
  SELECT user_id INTO report_user_id
  FROM droppings_reports
  WHERE id = NEW.report_id;
  
  -- Get batch name for better notification message
  SELECT batches.name INTO batch_name
  FROM droppings_reports
  JOIN batches ON droppings_reports.batch_id = batches.id
  WHERE droppings_reports.id = NEW.report_id;
  
  -- Insert notification
  INSERT INTO notifications (user_id, title, message, type, reference_id)
  VALUES (
    report_user_id,
    'Vet Response Received',
    'Your droppings report for ' || COALESCE(batch_name, 'your batch') || ' has been reviewed. Title: ' || NEW.title,
    'report_response',
    NEW.id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_create_notification_on_response ON droppings_reports_responses;
CREATE TRIGGER trigger_create_notification_on_response
AFTER INSERT ON droppings_reports_responses
FOR EACH ROW
EXECUTE FUNCTION create_notification_on_response();

-- ============================================
-- 5. Create storage bucket for medication images
-- ============================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'medication-images',
  'medication-images',
  true,
  5242880, -- 5MB file size limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png']
)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for medication images
CREATE POLICY "Public can view medication images"
ON storage.objects FOR SELECT
USING (bucket_id = 'medication-images');

CREATE POLICY "Vets can upload medication images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'medication-images' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Vets can update medication images"
ON storage.objects FOR UPDATE
USING (bucket_id = 'medication-images')
WITH CHECK (bucket_id = 'medication-images');

CREATE POLICY "Vets can delete medication images"
ON storage.objects FOR DELETE
USING (bucket_id = 'medication-images');

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Check if tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('droppings_reports_responses', 'notifications');

-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('droppings_reports_responses', 'notifications');

-- Check if medication-images bucket was created
SELECT id, name, public 
FROM storage.buckets 
WHERE id = 'medication-images';

-- ============================================
-- ROLLBACK (if needed)
-- ============================================
-- DROP TRIGGER IF EXISTS trigger_create_notification_on_response ON droppings_reports_responses;
-- DROP FUNCTION IF EXISTS create_notification_on_response();
-- DROP TABLE IF EXISTS notifications CASCADE;
-- DROP TABLE IF EXISTS droppings_reports_responses CASCADE;
-- DELETE FROM storage.buckets WHERE id = 'medication-images';
