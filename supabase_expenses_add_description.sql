-- Add description column to expenses table
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS description TEXT;

COMMENT ON COLUMN expenses.description IS 'Short description of what was bought';
