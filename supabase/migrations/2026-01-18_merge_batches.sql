-- Batch merge support: table + RPC
-- Run this in Supabase SQL editor or via CLI

-- 1) Merge history table
create table if not exists public.batch_merges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  primary_batch_id uuid not null,
  merged_batch_id uuid not null,
  combined_bird_count integer not null check (combined_bird_count >= 0),
  merge_reason text,
  merged_at timestamptz not null default now()
);

-- Helpful indexes for querying history
create index if not exists idx_batch_merges_primary on public.batch_merges(primary_batch_id);
create index if not exists idx_batch_merges_merged on public.batch_merges(merged_batch_id);

-- Conditionally add foreign keys only if public.batches exists
do $$
begin
  if exists (select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
             where c.relname = 'batches' and n.nspname = 'public') then
    begin
      alter table public.batch_merges
        add constraint fk_batch_merges_primary
        foreign key (primary_batch_id) references public.batches(id) on delete cascade;
    exception when duplicate_object then null; end;
    begin
      alter table public.batch_merges
        add constraint fk_batch_merges_merged
        foreign key (merged_batch_id) references public.batches(id) on delete cascade;
    exception when duplicate_object then null; end;
  end if;
end $$;

-- Ensure required columns exist on public.batches (if the table is present)
do $$
begin
  if exists (select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
             where c.relname = 'batches' and n.nspname = 'public') then
    alter table public.batches
      add column if not exists actual_quantity integer;
    alter table public.batches
      add column if not exists is_merged boolean default false;
    alter table public.batches
      add column if not exists merged_into_batch_id uuid;
    alter table public.batches
      add column if not exists status text default 'active';
  end if;
end $$;

-- 2) RPC: merge_batches
-- Updates both batches and records the merge event, returning the inserted row as JSON
create or replace function public.merge_batches(
  p_primary_batch_id uuid,
  p_merged_batch_id uuid,
  p_combined_bird_count integer,
  p_merge_reason text default null
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_merge_id uuid := gen_random_uuid();
  v_result jsonb;
begin
  if p_primary_batch_id is null or p_merged_batch_id is null then
    raise exception 'Batch IDs must not be null';
  end if;

  if p_primary_batch_id = p_merged_batch_id then
    raise exception 'Primary and merged batch cannot be the same';
  end if;

  -- Ensure batches exist and fetch user_id (assumes batches has user_id)
  select user_id into v_user_id from public.batches where id = p_primary_batch_id;
  if v_user_id is null then
    raise exception 'Primary batch not found: %', p_primary_batch_id;
  end if;

  perform 1 from public.batches where id = p_merged_batch_id;
  if not found then
    raise exception 'Merged batch not found: %', p_merged_batch_id;
  end if;

  -- Update primary batch actual quantity
  update public.batches
    set actual_quantity = p_combined_bird_count
  where id = p_primary_batch_id;

  -- Mark merged batch as merged into primary
  update public.batches
    set is_merged = true,
      status = 'merged',
      merged_into_batch_id = p_primary_batch_id
  where id = p_merged_batch_id;

  -- Record merge event
  insert into public.batch_merges (
    id,
    user_id,
    primary_batch_id,
    merged_batch_id,
    combined_bird_count,
    merge_reason,
    merged_at
  ) values (
    v_merge_id,
    v_user_id,
    p_primary_batch_id,
    p_merged_batch_id,
    p_combined_bird_count,
    p_merge_reason,
    now()
  );

  -- Return the inserted row as JSON
  select to_jsonb(bm) into v_result
  from public.batch_merges bm
  where bm.id = v_merge_id;

  return v_result;
end;
$$;

-- Optional: Row Level Security policies (adjust to your auth model)
-- Note: If RLS is enabled on batches/batch_merges, ensure policies allow owners to read/write.
-- Example read policy (requires batches.user_id = auth.uid() and a foreign key or join):
-- create policy "read_own_batch_merges" on public.batch_merges
--   for select using (
--     exists (
--       select 1 from public.batches b
--       where b.id = batch_merges.primary_batch_id
--         and b.user_id = auth.uid()
--     ) or exists (
--       select 1 from public.batches b2
--       where b2.id = batch_merges.merged_batch_id
--         and b2.user_id = auth.uid()
--     )
--   );
