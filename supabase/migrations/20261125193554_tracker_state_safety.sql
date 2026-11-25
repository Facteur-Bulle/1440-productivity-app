create or replace function public.normalize_tracker_state()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_active_count integer;
  v_latest_start bigint;
  v_keep_id text;
  v_now_ms bigint := floor(extract(epoch from clock_timestamp()) * 1000)::bigint;
begin
  new.entries := (
    select coalesce(jsonb_agg(item), '[]'::jsonb)
    from jsonb_array_elements(new.entries) as rows(item)
    where not (
      (item->>'id') = any (
        array(select jsonb_array_elements_text(new.deleted_entry_ids))
      )
    )
  );

  select count(*), max((item->>'start')::bigint)
    into v_active_count, v_latest_start
  from jsonb_array_elements(new.entries) as rows(item)
  where item->'end' = 'null'::jsonb;

  if v_active_count > 1 then
    select item->>'id'
      into v_keep_id
    from jsonb_array_elements(new.entries) as rows(item)
    where item->'end' = 'null'::jsonb
    order by (item->>'start')::bigint desc, item->>'id' desc
    limit 1;

    new.entries := (
      select coalesce(
        jsonb_agg(
          case
            when item->'end' = 'null'::jsonb and item->>'id' <> v_keep_id then
              item || jsonb_build_object(
                'end', greatest((item->>'start')::bigint, v_latest_start),
                'updatedAt', greatest(coalesce((item->>'updatedAt')::bigint, 0), v_now_ms)
              )
            else item
          end
        ),
        '[]'::jsonb
      )
      from jsonb_array_elements(new.entries) as rows(item)
    );
  end if;
  return new;
end;
$$;

revoke all on function public.normalize_tracker_state() from public, anon, authenticated;

create trigger normalize_tracker_state_before_write
  before insert or update of entries, deleted_entry_ids
  on public.tracker_states
  for each row execute function public.normalize_tracker_state();
