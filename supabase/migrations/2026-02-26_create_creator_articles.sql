-- Create creator_articles table
CREATE TABLE IF NOT EXISTS creator_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  content TEXT NOT NULL,
  image_url TEXT,
  category TEXT NOT NULL DEFAULT 'General',
  featured BOOLEAN DEFAULT false,
  views INTEGER DEFAULT 0,
  likes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE creator_articles ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Creators can manage their own articles
CREATE POLICY creator_articles_creator_policy ON creator_articles
  FOR ALL USING (
    auth.uid() = user_id
  ) WITH CHECK (
    auth.uid() = user_id
  );

-- Public read access for published articles
CREATE POLICY creator_articles_read_policy ON creator_articles
  FOR SELECT USING (true);

-- Create updated_at trigger
CREATE TRIGGER creator_articles_updated_at
  BEFORE UPDATE ON creator_articles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create index for faster queries
CREATE INDEX creator_articles_user_id_idx ON creator_articles(user_id);
CREATE INDEX creator_articles_created_at_idx ON creator_articles(created_at DESC);
CREATE INDEX creator_articles_featured_idx ON creator_articles(featured) WHERE featured = true;
