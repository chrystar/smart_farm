-- Droppings reports table
CREATE TABLE IF NOT EXISTS droppings_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  notes TEXT,
  image_url TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_droppings_reports_user_id
  ON droppings_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_droppings_reports_batch_id
  ON droppings_reports(batch_id);

ALTER TABLE droppings_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own droppings reports" ON droppings_reports;
CREATE POLICY "Users can view own droppings reports"
  ON droppings_reports
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own droppings reports" ON droppings_reports;
CREATE POLICY "Users can create own droppings reports"
  ON droppings_reports
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);
