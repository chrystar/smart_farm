-- Add batch-level folder metadata for expenses and sales logs
ALTER TABLE public.batches
  ADD COLUMN IF NOT EXISTS expense_log_folder_id TEXT,
  ADD COLUMN IF NOT EXISTS expense_log_folder_title TEXT,
  ADD COLUMN IF NOT EXISTS sales_log_folder_id TEXT,
  ADD COLUMN IF NOT EXISTS sales_log_folder_title TEXT;

CREATE INDEX IF NOT EXISTS idx_batches_expense_log_folder_id
  ON public.batches(expense_log_folder_id);

CREATE INDEX IF NOT EXISTS idx_batches_sales_log_folder_id
  ON public.batches(sales_log_folder_id);

-- Backfill existing rows so all old batches have folders too
UPDATE public.batches
SET
  expense_log_folder_id = COALESCE(expense_log_folder_id, 'exp-folder-' || id::text),
  expense_log_folder_title = COALESCE(expense_log_folder_title, name || ' Expenses'),
  sales_log_folder_id = COALESCE(sales_log_folder_id, 'sales-folder-' || id::text),
  sales_log_folder_title = COALESCE(sales_log_folder_title, name || ' Sales')
WHERE
  expense_log_folder_id IS NULL
  OR expense_log_folder_title IS NULL
  OR sales_log_folder_id IS NULL
  OR sales_log_folder_title IS NULL;
