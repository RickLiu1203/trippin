create or replace function get_my_trip_ids()
returns setof uuid as $$
    select trip_id from public.trip_members where user_id = auth.uid()
$$ language sql security definer stable set search_path = public;

drop policy if exists "Members can read trip members" on trip_members;
create policy "Members can read trip members"
    on trip_members for select using (
        trip_id in (select get_my_trip_ids())
    );

drop policy if exists "Members can read their trips" on trips;
create policy "Members can read their trips"
    on trips for select using (
        id in (select get_my_trip_ids())
    );

drop policy if exists "Members can read trip profiles" on profiles;
create policy "Members can read trip profiles"
    on profiles for select using (
        id in (
            select tm.user_id from public.trip_members tm
            where tm.trip_id in (select get_my_trip_ids())
        )
    );

drop policy if exists "Members can read photo metadata" on photo_metadata;
create policy "Members can read photo metadata"
    on photo_metadata for select using (
        trip_id in (select get_my_trip_ids())
    );

drop policy if exists "Members can insert photo metadata" on photo_metadata;
create policy "Members can insert photo metadata"
    on photo_metadata for insert with check (
        trip_id in (select get_my_trip_ids())
    );

drop policy if exists "Members can update photo metadata" on photo_metadata;
create policy "Members can update photo metadata"
    on photo_metadata for update using (
        trip_id in (select get_my_trip_ids())
    );

drop policy if exists "Members can read clusters" on photo_clusters;
create policy "Members can read clusters"
    on photo_clusters for select using (
        trip_id in (select get_my_trip_ids())
    );

drop policy if exists "Members can manage clusters" on photo_clusters;
create policy "Members can manage clusters"
    on photo_clusters for insert with check (
        trip_id in (select get_my_trip_ids())
    );

drop policy if exists "Members can update clusters" on photo_clusters;
create policy "Members can update clusters"
    on photo_clusters for update using (
        trip_id in (select get_my_trip_ids())
    );

drop policy if exists "Members can delete clusters" on photo_clusters;
create policy "Members can delete clusters"
    on photo_clusters for delete using (
        trip_id in (select get_my_trip_ids())
    );

drop policy if exists "Members can read cluster photos" on cluster_photos;
create policy "Members can read cluster photos"
    on cluster_photos for select using (
        cluster_id in (
            select id from photo_clusters
            where trip_id in (select get_my_trip_ids())
        )
    );

drop policy if exists "Members can manage cluster photos" on cluster_photos;
create policy "Members can manage cluster photos"
    on cluster_photos for insert with check (
        cluster_id in (
            select id from photo_clusters
            where trip_id in (select get_my_trip_ids())
        )
    );

drop policy if exists "Members can delete cluster photos" on cluster_photos;
create policy "Members can delete cluster photos"
    on cluster_photos for delete using (
        cluster_id in (
            select id from photo_clusters
            where trip_id in (select get_my_trip_ids())
        )
    );

drop policy if exists "Members can read device mappings" on device_mappings;
create policy "Members can read device mappings"
    on device_mappings for select using (
        trip_id in (select get_my_trip_ids())
    );

drop policy if exists "Members can manage device mappings" on device_mappings;
create policy "Members can manage device mappings"
    on device_mappings for insert with check (
        trip_id in (select get_my_trip_ids())
    );

drop policy if exists "Members can update device mappings" on device_mappings;
create policy "Members can update device mappings"
    on device_mappings for update using (
        trip_id in (select get_my_trip_ids())
    );
