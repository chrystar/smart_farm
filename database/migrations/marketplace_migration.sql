-- ============================================
-- MARKETPLACE FEATURE - DATABASE MIGRATION
-- ============================================
-- This script creates the necessary tables and policies for the marketplace feature
-- Run this script in your Supabase SQL Editor

-- ============================================
-- 1. Create approved_locations table
-- ============================================
CREATE TABLE IF NOT EXISTS approved_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_name TEXT NOT NULL,
    region TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_approved_locations_active ON approved_locations(is_active);

-- ============================================
-- 2. Create sales_requests table
-- ============================================
CREATE TABLE IF NOT EXISTS sales_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Bird details
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price_per_bird DECIMAL(10, 2) NOT NULL CHECK (price_per_bird > 0),
    total_price DECIMAL(10, 2) NOT NULL,
    bird_type TEXT NOT NULL CHECK (bird_type IN ('broiler', 'layer', 'cockerel', 'other')),
    age_months INTEGER NOT NULL CHECK (age_months >= 0),
    bird_photos TEXT[] NOT NULL DEFAULT '{}',
    
    -- Location
    location_id UUID NOT NULL REFERENCES approved_locations(id),
    location_name TEXT NOT NULL,
    
    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'approved', 'finding_buyer', 'buyer_found', 'completed', 'cancelled', 'rejected')),
    
    -- Admin review
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    admin_notes TEXT,
    
    -- Buyer information (populated when buyer is found)
    buyer_name TEXT,
    buyer_phone TEXT,
    pickup_location TEXT,
    pickup_date TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_sales_requests_user_id ON sales_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_requests_status ON sales_requests(status);
CREATE INDEX IF NOT EXISTS idx_sales_requests_location_id ON sales_requests(location_id);
CREATE INDEX IF NOT EXISTS idx_sales_requests_created_at ON sales_requests(created_at DESC);

-- ============================================
-- 3. Create updated_at trigger function
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 4. Add triggers for updated_at
-- ============================================
DROP TRIGGER IF EXISTS update_approved_locations_updated_at ON approved_locations;
CREATE TRIGGER update_approved_locations_updated_at
    BEFORE UPDATE ON approved_locations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sales_requests_updated_at ON sales_requests;
CREATE TRIGGER update_sales_requests_updated_at
    BEFORE UPDATE ON sales_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 5. Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS on both tables
ALTER TABLE approved_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_requests ENABLE ROW LEVEL SECURITY;

-- approved_locations policies
-- Everyone can read active locations
DROP POLICY IF EXISTS "Anyone can view active locations" ON approved_locations;
CREATE POLICY "Anyone can view active locations"
    ON approved_locations
    FOR SELECT
    USING (is_active = true);

-- Only admins can insert/update/delete locations (you can customize this)
-- For now, we'll allow authenticated users to read them
DROP POLICY IF EXISTS "Authenticated users can view all locations" ON approved_locations;
CREATE POLICY "Authenticated users can view all locations"
    ON approved_locations
    FOR SELECT
    TO authenticated
    USING (true);

-- sales_requests policies
-- Users can view their own sales requests
DROP POLICY IF EXISTS "Users can view own sales requests" ON sales_requests;
CREATE POLICY "Users can view own sales requests"
    ON sales_requests
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Users can insert their own sales requests
DROP POLICY IF EXISTS "Users can create sales requests" ON sales_requests;
CREATE POLICY "Users can create sales requests"
    ON sales_requests
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own sales requests (only if status is pending or cancelled)
DROP POLICY IF EXISTS "Users can update own pending requests" ON sales_requests;
CREATE POLICY "Users can update own pending requests"
    ON sales_requests
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id AND status IN ('pending', 'cancelled'))
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own sales requests (only if status is pending)
DROP POLICY IF EXISTS "Users can delete own pending requests" ON sales_requests;
CREATE POLICY "Users can delete own pending requests"
    ON sales_requests
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id AND status = 'pending');

-- ============================================
-- 6. Insert sample approved locations
-- ============================================
-- Feel free to modify these locations based on your needs
INSERT INTO approved_locations (location_name, region, is_active) VALUES
    ('Lagos Central Market', 'Lagos', true),
    ('Ibadan Livestock Market', 'Oyo', true),
    ('Kano Agricultural Hub', 'Kano', true),
    ('Port Harcourt Farm Center', 'Rivers', true),
    ('Abuja Central Farm', 'FCT', true)
ON CONFLICT DO NOTHING;

-- ============================================
-- 7. Create Supabase Storage Bucket
-- ============================================
-- Note: This needs to be done via the Supabase Dashboard or using the Storage API
-- Bucket name: 'bird-photos'
-- Public access: true (for viewing images)
-- Allowed MIME types: image/jpeg, image/png, image/jpg
-- Max file size: 5MB per file

-- To create via SQL (requires proper permissions):
-- INSERT INTO storage.buckets (id, name, public) 
-- VALUES ('bird-photos', 'bird-photos', true)
-- ON CONFLICT DO NOTHING;

-- Storage policies for bird-photos bucket:
-- 1. Anyone can view images (public read)
-- 2. Authenticated users can upload images
-- 3. Users can delete their own images

-- Note: Storage policies are typically managed through Supabase Dashboard
-- Go to Storage > bird-photos > Policies to set these up

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Run these to verify the migration was successful

-- Check if tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('approved_locations', 'sales_requests');

-- Check approved locations
SELECT * FROM approved_locations;

-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('approved_locations', 'sales_requests');

-- ============================================
-- ROLLBACK (if needed)
-- ============================================
-- Uncomment and run these if you need to remove everything

-- DROP TABLE IF EXISTS sales_requests CASCADE;
-- DROP TABLE IF EXISTS approved_locations CASCADE;
-- DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
