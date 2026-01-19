-- ============================================
-- Migration: Add Currency Column to Batches
-- ============================================
-- Run this SQL in your Supabase SQL Editor to add the currency column
-- to an existing batches table

-- Add currency column if it doesn't exist
ALTER TABLE batches ADD COLUMN IF NOT EXISTS currency TEXT;

-- ============================================
-- Migration Complete!
-- ============================================
