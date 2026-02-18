-- Add duration_days to vaccine_schedules
ALTER TABLE vaccine_schedules
  ADD COLUMN IF NOT EXISTS duration_days INTEGER NOT NULL DEFAULT 1;

-- Ensure existing rows are populated
UPDATE vaccine_schedules
SET duration_days = 1
WHERE duration_days IS NULL;
