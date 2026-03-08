-- Add assigned_vet_id column to droppings_reports
ALTER TABLE droppings_reports ADD COLUMN IF NOT EXISTS assigned_vet_id UUID REFERENCES vets(id);

-- Policy: Only assigned vet can view droppings report
DROP POLICY IF EXISTS "Vets can view all droppings reports" ON droppings_reports;
CREATE POLICY "Assigned vet can view droppings report"
  ON droppings_reports FOR SELECT
  USING (
    (SELECT role FROM user_roles WHERE id = auth.uid()) = 'vet'
    AND assigned_vet_id = auth.uid()
  );

-- Policy: Farmer who submitted can view their own report
DROP POLICY IF EXISTS "Users can view own droppings reports" ON droppings_reports;
CREATE POLICY "Farmer can view own droppings report"
  ON droppings_reports FOR SELECT
  USING (
    (SELECT role FROM user_roles WHERE id = auth.uid()) = 'farmer'
    AND user_id = auth.uid()
  );
