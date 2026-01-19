-- ============================================
-- Smart Farm - Supabase Database Setup
-- ============================================
-- Run this SQL in your Supabase SQL Editor to create the necessary tables

-- ============================================
-- 1. BATCHES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    bird_type TEXT NOT NULL CHECK (bird_type IN ('broiler', 'layer')),
    breed TEXT,
    expected_quantity INTEGER NOT NULL CHECK (expected_quantity > 0),
    actual_quantity INTEGER CHECK (actual_quantity >= 0),
    status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'completed')),
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    purchase_cost DECIMAL(10, 2),
    currency TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_batches_user_id ON batches(user_id);
CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);
CREATE INDEX IF NOT EXISTS idx_batches_created_at ON batches(created_at DESC);

-- ============================================
-- 2. DAILY RECORDS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS daily_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    mortality_count INTEGER NOT NULL DEFAULT 0 CHECK (mortality_count >= 0),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure only one record per batch per day
    UNIQUE(batch_id, date)
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_daily_records_batch_id ON daily_records(batch_id);
CREATE INDEX IF NOT EXISTS idx_daily_records_date ON daily_records(date DESC);

-- ============================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on batches table
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own batches" ON batches;
DROP POLICY IF EXISTS "Users can create their own batches" ON batches;
DROP POLICY IF EXISTS "Users can update their own batches" ON batches;
DROP POLICY IF EXISTS "Users can delete their own batches" ON batches;

-- Policy: Users can view their own batches
CREATE POLICY "Users can view their own batches"
    ON batches FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can create their own batches
CREATE POLICY "Users can create their own batches"
    ON batches FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own batches
CREATE POLICY "Users can update their own batches"
    ON batches FOR UPDATE
    USING (auth.uid() = user_id);

-- Policy: Users can delete their own batches
CREATE POLICY "Users can delete their own batches"
    ON batches FOR DELETE
    USING (auth.uid() = user_id);

-- Enable RLS on daily_records table
ALTER TABLE daily_records ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view daily records of their batches" ON daily_records;
DROP POLICY IF EXISTS "Users can create daily records for their batches" ON daily_records;
DROP POLICY IF EXISTS "Users can update daily records of their batches" ON daily_records;
DROP POLICY IF EXISTS "Users can delete daily records of their batches" ON daily_records;

-- Policy: Users can view daily records of their batches
CREATE POLICY "Users can view daily records of their batches"
    ON daily_records FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM batches
            WHERE batches.id = daily_records.batch_id
            AND batches.user_id = auth.uid()
        )
    );

-- Policy: Users can create daily records for their batches
CREATE POLICY "Users can create daily records for their batches"
    ON daily_records FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM batches
            WHERE batches.id = daily_records.batch_id
            AND batches.user_id = auth.uid()
        )
    );

-- Policy: Users can update daily records of their batches
CREATE POLICY "Users can update daily records of their batches"
    ON daily_records FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM batches
            WHERE batches.id = daily_records.batch_id
            AND batches.user_id = auth.uid()
        )
    );

-- Policy: Users can delete daily records of their batches
CREATE POLICY "Users can delete daily records of their batches"
    ON daily_records FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM batches
            WHERE batches.id = daily_records.batch_id
            AND batches.user_id = auth.uid()
        )
    );

-- ============================================
-- 4. UPDATED_AT TRIGGERS
-- ============================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_batches_updated_at ON batches;
DROP TRIGGER IF EXISTS update_daily_records_updated_at ON daily_records;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for batches table
CREATE TRIGGER update_batches_updated_at
    BEFORE UPDATE ON batches
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for daily_records table
CREATE TRIGGER update_daily_records_updated_at
    BEFORE UPDATE ON daily_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Setup Complete!
-- ============================================
-- You can now use these tables in your Flutter app
