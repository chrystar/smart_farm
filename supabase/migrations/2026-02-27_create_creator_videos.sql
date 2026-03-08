-- Create creator_videos table
CREATE TABLE IF NOT EXISTS creator_videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  video_url TEXT NOT NULL,
  thumbnail_url TEXT,
  duration_seconds INTEGER,
  file_size_bytes BIGINT,
  category TEXT NOT NULL DEFAULT 'General',
  featured BOOLEAN DEFAULT false,
  views INTEGER DEFAULT 0,
  likes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE creator_videos ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Creators can manage their own videos
CREATE POLICY creator_videos_creator_policy ON creator_videos
  FOR ALL USING (
    auth.uid() = user_id
  ) WITH CHECK (
    auth.uid() = user_id
  );

-- Public read access for published videos
CREATE POLICY creator_videos_read_policy ON creator_videos
  FOR SELECT USING (true);

-- Create updated_at trigger
CREATE TRIGGER creator_videos_updated_at
  BEFORE UPDATE ON creator_videos
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for faster queries
CREATE INDEX creator_videos_user_id_idx ON creator_videos(user_id);
CREATE INDEX creator_videos_created_at_idx ON creator_videos(created_at DESC);
CREATE INDEX creator_videos_featured_idx ON creator_videos(featured) WHERE featured = true;
