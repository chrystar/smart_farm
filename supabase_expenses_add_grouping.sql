-- Add grouping columns to expenses table
ALTER TABLE expenses
  ADD COLUMN IF NOT EXISTS group_id TEXT,
  ADD COLUMN IF NOT EXISTS group_title TEXT;

-- Create index for group_id to improve query performance
CREATE INDEX IF NOT EXISTS idx_expenses_group_id
  ON expenses(group_id);
