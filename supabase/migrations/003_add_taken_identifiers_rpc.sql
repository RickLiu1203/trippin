create or replace function get_trip_taken_identifiers(p_share_code text)
returns json as $$
select json_build_object(
    'trip_id', t.id,
    'emojis', coalesce((select json_agg(tm.emoji) from public.trip_members tm where tm.trip_id = t.id), '[]'::json),
    'colors', coalesce((select json_agg(tm.color) from public.trip_members tm where tm.trip_id = t.id), '[]'::json)
)
from public.trips t where t.share_code = p_share_code
$$ language sql security definer stable set search_path = public;
