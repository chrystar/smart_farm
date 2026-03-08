-- This migration ensures the profiles table has all the fields we need
-- and makes phone_number optional if it exists

-- If the profiles table doesn't exist, create it
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  email TEXT,
  phone_number TEXT,  -- Optional phone number
  role TEXT NOT NULL DEFAULT 'farmer' CHECK (role IN ('farmer', 'vet', 'admin')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Make phone_number optional (remove NOT NULL constraint if it exists)
DO $$ 
BEGIN
  -- Only drop NOT NULL if the column exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' 
    AND column_name = 'phone_number'
  ) THEN
    ALTER TABLE profiles ALTER COLUMN phone_number DROP NOT NULL;
  END IF;
END $$;

-- Ensure email has unique constraint (skip if already exists)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'profiles_email_unique'
  ) THEN
    ALTER TABLE profiles ADD CONSTRAINT profiles_email_unique UNIQUE (email);
  END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id);

-- Enable RLS if not already enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop and recreate policies
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;

-- Users can view their own profile
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can insert their own profile during signup
CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- CREATE POLICY "Admins can view all profiles"
--   ON profiles FOR SELECT
--   USING (
--     EXISTS (
--       SELECT 1 FROM profiles admin_profile
--       WHERE admin_profile.id = auth.uid()
--       AND admin_profile.role = 'admin'
--     )
--   );

-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION update_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and recreate the trigger
DROP TRIGGER IF EXISTS profiles_updated_at_trigger ON profiles;
CREATE TRIGGER profiles_updated_at_trigger
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_profiles_updated_at();
