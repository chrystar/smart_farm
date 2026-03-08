-- Add batch-level profit insight metadata
ALTER TABLE public.batches
  ADD COLUMN IF NOT EXISTS profit_insight_id TEXT,
  ADD COLUMN IF NOT EXISTS profit_insight_title TEXT;

CREATE INDEX IF NOT EXISTS idx_batches_profit_insight_id
  ON public.batches(profit_insight_id);

-- Backfill existing rows so all existing batches get profit insight metadata
UPDATE public.batches
SET
  profit_insight_id = COALESCE(profit_insight_id, 'profit-insight-' || id::text),
  profit_insight_title = COALESCE(profit_insight_title, name || ' Profit Insight')
WHERE
  profit_insight_id IS NULL
  OR profit_insight_title IS NULL;
