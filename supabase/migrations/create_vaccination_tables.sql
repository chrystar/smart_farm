-- Create vaccine_schedules table
CREATE TABLE IF NOT EXISTS vaccine_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  batch_id UUID NOT NULL,
  vaccine_type TEXT NOT NULL,
  vaccine_name TEXT NOT NULL,
  age_in_days INTEGER NOT NULL,
  route TEXT NOT NULL,
  dosage TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE
);

-- Create vaccination_logs table
CREATE TABLE IF NOT EXISTS vaccination_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  batch_id UUID NOT NULL,
  schedule_id UUID,
  vaccine_type TEXT NOT NULL,
  vaccine_name TEXT NOT NULL,
  route TEXT NOT NULL,
  dosage TEXT NOT NULL,
  administered_date TIMESTAMP WITH TIME ZONE NOT NULL,
  expected_date TIMESTAMP WITH TIME ZONE NOT NULL,
  administered_by TEXT,
  notes TEXT,
  is_completed BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE,
  FOREIGN KEY (schedule_id) REFERENCES vaccine_schedules(id) ON DELETE SET NULL
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_vaccine_schedules_batch_id ON vaccine_schedules(batch_id);
CREATE INDEX IF NOT EXISTS idx_vaccine_schedules_user_id ON vaccine_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_vaccination_logs_batch_id ON vaccination_logs(batch_id);
CREATE INDEX IF NOT EXISTS idx_vaccination_logs_user_id ON vaccination_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_vaccination_logs_administered_date ON vaccination_logs(administered_date);

-- Enable RLS
ALTER TABLE vaccine_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaccination_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for vaccine_schedules
CREATE POLICY "Users can view their own vaccine schedules"
  ON vaccine_schedules FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can create vaccine schedules"
  ON vaccine_schedules FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own vaccine schedules"
  ON vaccine_schedules FOR UPDATE
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own vaccine schedules"
  ON vaccine_schedules FOR DELETE
  USING (auth.uid()::text = user_id);

-- Create RLS policies for vaccination_logs
CREATE POLICY "Users can view their own vaccination logs"
  ON vaccination_logs FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can create vaccination logs"
  ON vaccination_logs FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own vaccination logs"
  ON vaccination_logs FOR UPDATE
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own vaccination logs"
  ON vaccination_logs FOR DELETE
  USING (auth.uid()::text = user_id);
