-- Imperiall RPG - RLS Policies
-- Idempotente: drop + create

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.skills enable row level security;
alter table public.mobs enable row level security;
alter table public.zones enable row level security;
alter table public.stages enable row level security;
alter table public.waves enable row level security;
alter table public.wave_mobs enable row level security;
alter table public.loot_tables enable row level security;
alter table public.loot_table_entries enable row level security;
alter table public.player_inventory enable row level security;
alter table public.player_equipment enable row level security;
alter table public.player_skills enable row level security;
alter table public.player_stage_progress enable row level security;

-- Helper: is admin
create or replace function public.is_admin(uid uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = uid and role = 'admin');
$$;

-- PROFILES
drop policy if exists "profiles_select_self_or_public" on public.profiles;
create policy "profiles_select_self_or_public"
  on public.profiles for select to authenticated
  using (auth.uid() = id or true); -- ranking/view minimal later

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
  on public.profiles for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
  on public.profiles for insert to authenticated
  with check (auth.uid() = id);

-- CATALOG (read-only for users, CRUD for admin)
do $$ begin
  -- items
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='items' and policyname='items_read_all') then
    create policy "items_read_all" on public.items for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='items' and policyname='items_admin_crud') then
    create policy "items_admin_crud" on public.items for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;

  -- skills
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skills' and policyname='skills_read_all') then
    create policy "skills_read_all" on public.skills for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skills' and policyname='skills_admin_crud') then
    create policy "skills_admin_crud" on public.skills for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;

  -- mobs
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='mobs' and policyname='mobs_read_all') then
    create policy "mobs_read_all" on public.mobs for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='mobs' and policyname='mobs_admin_crud') then
    create policy "mobs_admin_crud" on public.mobs for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;

  -- zones
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='zones' and policyname='zones_read_all') then
    create policy "zones_read_all" on public.zones for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='zones' and policyname='zones_admin_crud') then
    create policy "zones_admin_crud" on public.zones for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;

  -- stages
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='stages' and policyname='stages_read_all') then
    create policy "stages_read_all" on public.stages for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='stages' and policyname='stages_admin_crud') then
    create policy "stages_admin_crud" on public.stages for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;

  -- waves
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='waves' and policyname='waves_read_all') then
    create policy "waves_read_all" on public.waves for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='waves' and policyname='waves_admin_crud') then
    create policy "waves_admin_crud" on public.waves for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;

  -- wave_mobs
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='wave_mobs' and policyname='wave_mobs_read_all') then
    create policy "wave_mobs_read_all" on public.wave_mobs for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='wave_mobs' and policyname='wave_mobs_admin_crud') then
    create policy "wave_mobs_admin_crud" on public.wave_mobs for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;

  -- loot_tables
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='loot_tables' and policyname='loot_tables_read_all') then
    create policy "loot_tables_read_all" on public.loot_tables for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='loot_tables' and policyname='loot_tables_admin_crud') then
    create policy "loot_tables_admin_crud" on public.loot_tables for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;

  -- loot_table_entries
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='loot_table_entries' and policyname='loot_entries_read_all') then
    create policy "loot_entries_read_all" on public.loot_table_entries for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='loot_table_entries' and policyname='loot_entries_admin_crud') then
    create policy "loot_entries_admin_crud" on public.loot_table_entries for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
end $$;

-- PLAYER DATA (self only)
drop policy if exists "player_inv_self_crud" on public.player_inventory;
create policy "player_inv_self_crud"
  on public.player_inventory for all to authenticated
  using (auth.uid() = player_id) with check (auth.uid() = player_id);

drop policy if exists "player_equip_self_crud" on public.player_equipment;
create policy "player_equip_self_crud"
  on public.player_equipment for all to authenticated
  using (auth.uid() = player_id) with check (auth.uid() = player_id);

drop policy if exists "player_skills_self_crud" on public.player_skills;
create policy "player_skills_self_crud"
  on public.player_skills for all to authenticated
  using (auth.uid() = player_id) with check (auth.uid() = player_id);

drop policy if exists "player_stage_self_crud" on public.player_stage_progress;
create policy "player_stage_self_crud"
  on public.player_stage_progress for all to authenticated
  using (auth.uid() = player_id) with check (auth.uid() = player_id);

-- anon: read catalog only (opcional; melhor via authenticated)
grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to anon, authenticated;
grant insert, update, delete on table public.profiles to authenticated;
grant insert, update, delete on table public.player_inventory,public.player_equipment,public.player_skills,public.player_stage_progress to authenticated;
grant usage, select on all sequences in schema public to authenticated;
