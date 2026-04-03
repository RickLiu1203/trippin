create extension if not exists "pgcrypto";

create or replace function generate_nanoid(size int default 12)
returns text as $$
declare
    alphabet text := 'abcdefghijklmnopqrstuvwxyz0123456789';
    result text := '';
    i int;
begin
    for i in 1..size loop
        result := result || substr(alphabet, floor(random() * length(alphabet) + 1)::int, 1);
    end loop;
    return result;
end;
$$ language plpgsql volatile;

create table profiles (
    id uuid references auth.users on delete cascade primary key,
    display_name text not null default '',
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table trips (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users on delete cascade,
    name text not null,
    share_code text not null unique default generate_nanoid(12),
    album_identifier text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table trip_members (
    id uuid primary key default gen_random_uuid(),
    trip_id uuid not null references trips on delete cascade,
    user_id uuid not null references auth.users on delete cascade,
    display_name text not null,
    emoji text not null,
    color text not null,
    role text not null default 'member' check (role in ('owner', 'member', 'guest')),
    camera_identifier text,
    created_at timestamptz not null default now(),
    unique (trip_id, user_id),
    unique (trip_id, emoji),
    unique (trip_id, color)
);

create table photo_metadata (
    id uuid primary key default gen_random_uuid(),
    trip_id uuid not null references trips on delete cascade,
    member_id uuid references auth.users on delete set null,
    local_asset_id text not null,
    latitude double precision,
    longitude double precision,
    taken_at timestamptz not null,
    camera_make text,
    camera_model text,
    camera_serial text,
    category text check (category in ('food', 'scenery', 'landmark', 'activity')),
    confidence double precision,
    day_index int,
    unique (trip_id, local_asset_id)
);

create table places (
    id uuid primary key default gen_random_uuid(),
    google_place_id text,
    name text not null,
    address text,
    latitude double precision not null,
    longitude double precision not null,
    category text,
    source text not null default 'google' check (source in ('google', 'user_input'))
);

create table photo_clusters (
    id uuid primary key default gen_random_uuid(),
    trip_id uuid not null references trips on delete cascade,
    centroid_lat double precision not null,
    centroid_lon double precision not null,
    start_time timestamptz not null,
    end_time timestamptz not null,
    day_index int not null,
    cluster_order int not null,
    place_id uuid references places on delete set null,
    photo_count int not null default 0
);

create table cluster_photos (
    id uuid primary key default gen_random_uuid(),
    cluster_id uuid not null references photo_clusters on delete cascade,
    photo_metadata_id uuid not null references photo_metadata on delete cascade,
    unique (cluster_id, photo_metadata_id)
);

create table device_mappings (
    id uuid primary key default gen_random_uuid(),
    trip_id uuid not null references trips on delete cascade,
    camera_identifier text not null,
    member_id uuid not null references auth.users on delete cascade,
    unique (trip_id, camera_identifier)
);

create index idx_trips_owner on trips (owner_id);
create index idx_trips_share_code on trips (share_code);
create index idx_trip_members_trip on trip_members (trip_id);
create index idx_trip_members_user on trip_members (user_id);
create index idx_photo_metadata_trip on photo_metadata (trip_id);
create index idx_photo_metadata_member on photo_metadata (member_id);
create index idx_photo_metadata_trip_asset on photo_metadata (trip_id, local_asset_id);
create index idx_photo_clusters_trip on photo_clusters (trip_id);
create index idx_cluster_photos_cluster on cluster_photos (cluster_id);
create index idx_device_mappings_trip on device_mappings (trip_id);

create or replace function update_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
    before update on profiles
    for each row execute function update_updated_at();

create trigger trips_updated_at
    before update on trips
    for each row execute function update_updated_at();

create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, display_name)
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'full_name', '')
    );
    return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function handle_new_user();

alter table profiles enable row level security;
alter table trips enable row level security;
alter table trip_members enable row level security;
alter table photo_metadata enable row level security;
alter table photo_clusters enable row level security;
alter table cluster_photos enable row level security;
alter table places enable row level security;
alter table device_mappings enable row level security;

create policy "Users can read own profile"
    on profiles for select using (auth.uid() = id);

create policy "Users can update own profile"
    on profiles for update using (auth.uid() = id);

create policy "Members can read trip profiles"
    on profiles for select using (
        id in (
            select tm.user_id from trip_members tm
            where tm.trip_id in (
                select tm2.trip_id from trip_members tm2
                where tm2.user_id = auth.uid()
            )
        )
    );

create policy "Users can create trips"
    on trips for insert with check (auth.uid() = owner_id);

create policy "Members can read their trips"
    on trips for select using (
        id in (select trip_id from trip_members where user_id = auth.uid())
    );

create policy "Owners can update their trips"
    on trips for update using (auth.uid() = owner_id);

create policy "Owners can delete their trips"
    on trips for delete using (auth.uid() = owner_id);

create policy "Anyone can read trips by share code"
    on trips for select using (true);

create policy "Members can read trip members"
    on trip_members for select using (
        trip_id in (select trip_id from trip_members where user_id = auth.uid())
    );

create policy "Users can join trips"
    on trip_members for insert with check (auth.uid() = user_id);

create policy "Owners can manage members"
    on trip_members for delete using (
        trip_id in (select id from trips where owner_id = auth.uid())
    );

create policy "Members can read photo metadata"
    on photo_metadata for select using (
        trip_id in (select trip_id from trip_members where user_id = auth.uid())
    );

create policy "Members can insert photo metadata"
    on photo_metadata for insert with check (
        trip_id in (select trip_id from trip_members where user_id = auth.uid())
    );

create policy "Members can update photo metadata"
    on photo_metadata for update using (
        trip_id in (select trip_id from trip_members where user_id = auth.uid())
    );

create policy "Members can read clusters"
    on photo_clusters for select using (
        trip_id in (select trip_id from trip_members where user_id = auth.uid())
    );

create policy "Members can manage clusters"
    on photo_clusters for insert with check (
        trip_id in (select trip_id from trip_members where user_id = auth.uid())
    );

create policy "Members can update clusters"
    on photo_clusters for update using (
        trip_id in (select trip_id from trip_members where user_id = auth.uid())
    );

create policy "Members can delete clusters"
    on photo_clusters for delete using (
        trip_id in (select trip_id from trip_members where user_id = auth.uid())
    );

create policy "Members can read cluster photos"
    on cluster_photos for select using (
        cluster_id in (
            select id from photo_clusters
            where trip_id in (select trip_id from trip_members where user_id = auth.uid())
        )
    );

create policy "Members can manage cluster photos"
    on cluster_photos for insert with check (
        cluster_id in (
            select id from photo_clusters
            where trip_id in (select trip_id from trip_members where user_id = auth.uid())
        )
    );

create policy "Members can delete cluster photos"
    on cluster_photos for delete using (
        cluster_id in (
            select id from photo_clusters
            where trip_id in (select trip_id from trip_members where user_id = auth.uid())
        )
    );

create policy "Anyone can read places"
    on places for select using (true);

create policy "Authenticated users can create places"
    on places for insert with check (auth.uid() is not null);

create policy "Authenticated users can update places"
    on places for update using (auth.uid() is not null);

create policy "Members can read device mappings"
    on device_mappings for select using (
        trip_id in (select trip_id from trip_members where user_id = auth.uid())
    );

create policy "Members can manage device mappings"
    on device_mappings for insert with check (
        trip_id in (select trip_id from trip_members where user_id = auth.uid())
    );

create policy "Members can update device mappings"
    on device_mappings for update using (
        trip_id in (select trip_id from trip_members where user_id = auth.uid())
    );
