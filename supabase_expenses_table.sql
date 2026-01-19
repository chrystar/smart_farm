-- Create expenses table
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'USD',
    category TEXT NOT NULL,
    custom_category TEXT,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    batch_id UUID REFERENCES batches(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_batch_id ON expenses(batch_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON expenses(user_id, date DESC);

-- Enable Row Level Security
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own expenses"
    ON expenses FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own expenses"
    ON expenses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own expenses"
    ON expenses FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own expenses"
    ON expenses FOR DELETE
    USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_expenses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER expenses_updated_at_trigger
    BEFORE UPDATE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_expenses_updated_at();

-- Add comments for documentation
COMMENT ON TABLE expenses IS 'Stores farm expense records';
COMMENT ON COLUMN expenses.id IS 'Unique expense identifier';
COMMENT ON COLUMN expenses.user_id IS 'User who created the expense';
COMMENT ON COLUMN expenses.amount IS 'Expense amount (positive decimal)';
COMMENT ON COLUMN expenses.currency IS 'Currency code (e.g., USD, NGN, GHS)';
COMMENT ON COLUMN expenses.category IS 'Expense category (feed, birds, medicine, etc.)';
COMMENT ON COLUMN expenses.custom_category IS 'Custom category name if user created one';
COMMENT ON COLUMN expenses.date IS 'Date of expense';
COMMENT ON COLUMN expenses.batch_id IS 'Optional link to specific batch';
COMMENT ON COLUMN expenses.created_at IS 'Timestamp when record was created';
COMMENT ON COLUMN expenses.updated_at IS 'Timestamp when record was last updated';
