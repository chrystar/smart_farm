-- Vet access table
CREATE TABLE IF NOT EXISTS vet_users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE vet_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Vets can read own vet record" ON vet_users;
CREATE POLICY "Vets can read own vet record"
  ON vet_users
  FOR SELECT
  USING (auth.uid() = user_id);

-- Droppings reports: vets can read all
DROP POLICY IF EXISTS "Vets can read droppings reports" ON droppings_reports;
CREATE POLICY "Vets can read droppings reports"
  ON droppings_reports
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM vet_users
      WHERE vet_users.user_id = auth.uid()
    )
  );
