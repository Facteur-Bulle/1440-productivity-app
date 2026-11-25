create table public.tracker_states (
  user_id uuid primary key references auth.users(id) on delete cascade,
  categories jsonb not null default '[]'::jsonb check (jsonb_typeof(categories) = 'array'),
  entries jsonb not null default '[]'::jsonb check (jsonb_typeof(entries) = 'array'),
  deleted_entry_ids jsonb not null default '[]'::jsonb check (jsonb_typeof(deleted_entry_ids) = 'array'),
  updated_at timestamptz not null default now()
);

alter table public.tracker_states enable row level security;
grant select, insert, update on public.tracker_states to authenticated;

create policy "Users can read their own tracker state"
  on public.tracker_states for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can create their own tracker state"
  on public.tracker_states for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can update their own tracker state"
  on public.tracker_states for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create or replace function public.merge_tracker_state(
  p_categories jsonb,
  p_entries jsonb,
  p_deleted_entry_ids jsonb
) returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_state public.tracker_states;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if jsonb_typeof(p_categories) <> 'array'
     or jsonb_typeof(p_entries) <> 'array'
     or jsonb_typeof(p_deleted_entry_ids) <> 'array' then
    raise exception 'Invalid tracker state';
  end if;

  insert into public.tracker_states as existing
    (user_id, categories, entries, deleted_entry_ids, updated_at)
  values
    (v_user_id, p_categories, p_entries, p_deleted_entry_ids, now())
  on conflict (user_id) do update set
    categories = (
      select coalesce(jsonb_agg(item), '[]'::jsonb)
      from (
        select distinct on (item->>'id') item
        from (
          select jsonb_array_elements(existing.categories) as item
          union all
          select jsonb_array_elements(excluded.categories) as item
        ) versions
        order by item->>'id', coalesce((item->>'updatedAt')::bigint, 0) desc
      ) latest
    ),
    entries = (
      select coalesce(jsonb_agg(item), '[]'::jsonb)
      from (
        select distinct on (item->>'id') item
        from (
          select jsonb_array_elements(existing.entries) as item
          union all
          select jsonb_array_elements(excluded.entries) as item
        ) versions
        order by item->>'id', coalesce((item->>'updatedAt')::bigint, 0) desc
      ) latest
    ),
    deleted_entry_ids = (
      select coalesce(jsonb_agg(distinct deleted_id), '[]'::jsonb)
      from (
        select jsonb_array_elements_text(existing.deleted_entry_ids) as deleted_id
        union
        select jsonb_array_elements_text(excluded.deleted_entry_ids) as deleted_id
      ) deleted
    ),
    updated_at = now()
  returning * into v_state;

  return jsonb_build_object(
    'categories', v_state.categories,
    'entries', v_state.entries,
    'deleted_entry_ids', v_state.deleted_entry_ids,
    'updated_at', v_state.updated_at
  );
end;
$$;

revoke all on function public.merge_tracker_state(jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.merge_tracker_state(jsonb, jsonb, jsonb) to authenticated;
