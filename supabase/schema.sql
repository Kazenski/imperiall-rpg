-- Imperiall RPG - Schema inicial (ARPG mobile)
-- Idempotente. Aplicar ANTES de policies.sql

create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";

-- ---------------------------------
-- Perfis (link com auth.users)
-- ---------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (char_length(username) between 3 and 24),
  display_name text not null default 'Aventureiro',
  avatar_url text,
  role text not null default 'user' check (role in ('user','admin')),
  xp bigint not null default 0,
  level integer not null default 1 check (level >= 1),
  hp integer not null default 100 check (hp >= 0),
  max_hp integer not null default 100 check (max_hp >= 0),
  atk integer not null default 10,
  def integer not null default 5,
  gold integer not null default 0 check (gold >= 0),
  gems integer not null default 0 check (gems >= 0),
  stage_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Blinda contra `profiles` pré-existente (ex.: schema parcial ou outro projeto):
-- garante a coluna `role` usada pelas policies de admin.
alter table public.profiles
  add column if not exists role text not null default 'user';

-- ---------------------------------
-- Catálogo: Itens
-- ---------------------------------
create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  type text not null check (type in ('weapon','helmet','chest','gloves','boots','ring','necklace','consumable','material','misc')),
  rarity text not null default 'common' check (rarity in ('common','uncommon','rare','epic','legendary','mythic')),
  slot text check (slot in ('weapon','helmet','chest','gloves','boots','ring','necklace','none')),
  icon_url text,
  sprite_url text,
  stackable boolean not null default false,
  max_stack integer not null default 1 check (max_stack >= 1),
  price_gold integer not null default 0 check (price_gold >= 0),
  price_gems integer not null default 0 check (price_gems >= 0),
  stats jsonb not null default '{}', -- {atk:10, def:5, hp:20, crit:5,...}
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------
-- Catálogo: Skills
-- ---------------------------------
create table if not exists public.skills (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  type text not null check (type in ('active','passive')),
  target text not null check (target in ('self','enemy','enemies','ally','allies','aoe')),
  cooldown_ms integer not null default 0 check (cooldown_ms >= 0),
  mana_cost integer not null default 0 check (mana_cost >= 0),
  base_damage integer not null default 0 check (base_damage >= 0),
  icon_url text,
  animation_key text,
  effects jsonb not null default '{}',
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------
-- Catálogo: Mobs
-- ---------------------------------
create table if not exists public.mobs (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  tier text not null default 'normal' check (tier in ('normal','elite','boss','mini_boss')),
  hp integer not null default 50 check (hp >= 1),
  atk integer not null default 5 check (atk >= 1),
  def integer not null default 2 check (def >= 0),
  exp_reward integer not null default 10 check (exp_reward >= 0),
  gold_reward integer not null default 5 check (gold_reward >= 0),
  speed integer not null default 100 check (speed >= 0),
  attack_cooldown_ms integer not null default 800 check (attack_cooldown_ms >= 100),
  scale numeric(4,2) not null default 1.00 check (scale >= 0.25 and scale <= 3.00),
  sprite_idle_url text,
  sprite_run_url text,
  sprite_attack_url text,
  sprite_hit_url text,
  sprite_death_url text,
  hitbox_w integer not null default 32 check (hitbox_w >= 0),
  hitbox_h integer not null default 32 check (hitbox_h >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------
-- Zonas / Stages
-- ---------------------------------
create table if not exists public.zones (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  bg_url text,
  bg_parallax boolean not null default false,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stages (
  id uuid primary key default gen_random_uuid(),
  zone_id uuid references public.zones(id) on delete set null,
  slug text unique not null,
  name text not null,
  description text,
  stage_number integer not null default 1 check (stage_number >= 1),
  recommended_level integer not null default 1 check (recommended_level >= 1),
  energy_cost integer not null default 1 check (energy_cost >= 0),
  is_boss_stage boolean not null default false,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists stages_zone_idx on public.stages(zone_id);

-- ---------------------------------
-- Waves
-- ---------------------------------
create table if not exists public.waves (
  id uuid primary key default gen_random_uuid(),
  stage_id uuid not null references public.stages(id) on delete cascade,
  wave_number integer not null check (wave_number >= 1),
  spawn_delay_ms integer not null default 500 check (spawn_delay_ms >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(stage_id, wave_number)
);
create index if not exists waves_stage_idx on public.waves(stage_id);

create table if not exists public.wave_mobs (
  id uuid primary key default gen_random_uuid(),
  wave_id uuid not null references public.waves(id) on delete cascade,
  mob_id uuid not null references public.mobs(id) on delete restrict,
  quantity integer not null default 1 check (quantity >= 1),
  delay_between_ms integer not null default 250 check (delay_between_ms >= 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists wave_mobs_wave_idx on public.wave_mobs(wave_id);

-- ---------------------------------
-- Loot Tables
-- ---------------------------------
create table if not exists public.loot_tables (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  mob_id uuid references public.mobs(id) on delete set null,
  stage_id uuid references public.stages(id) on delete set null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists loot_tables_mob_idx on public.loot_tables(mob_id);
create index if not exists loot_tables_stage_idx on public.loot_tables(stage_id);

create table if not exists public.loot_table_entries (
  id uuid primary key default gen_random_uuid(),
  loot_table_id uuid not null references public.loot_tables(id) on delete cascade,
  item_id uuid not null references public.items(id) on delete restrict,
  quantity_min integer not null default 1 check (quantity_min >= 1),
  quantity_max integer not null default 1 check (quantity_max >= quantity_min),
  weight integer not null default 100 check (weight >= 1),
  drop_chance_percent numeric(6,2) default null check (drop_chance_percent is null or (drop_chance_percent >= 0 and drop_chance_percent <= 100)),
  guaranteed boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists loot_entries_table_idx on public.loot_table_entries(loot_table_id);

-- ---------------------------------
-- Progresso do Jogador
-- ---------------------------------
create table if not exists public.player_inventory (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.profiles(id) on delete cascade,
  item_id uuid not null references public.items(id) on delete restrict,
  quantity integer not null default 1 check (quantity >= 0),
  is_equipped boolean not null default false,
  acquired_at timestamptz not null default now(),
  unique(player_id, item_id)
);
create index if not exists inv_player_idx on public.player_inventory(player_id);

create table if not exists public.player_equipment (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.profiles(id) on delete cascade,
  slot text not null check (slot in ('weapon','helmet','chest','gloves','boots','ring','necklace')),
  item_id uuid not null references public.items(id) on delete restrict,
  equipped_at timestamptz not null default now(),
  unique(player_id, slot)
);
create index if not exists equip_player_idx on public.player_equipment(player_id);

create table if not exists public.player_skills (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.profiles(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete restrict,
  level integer not null default 1 check (level >= 1),
  unlocked_at timestamptz not null default now(),
  unique(player_id, skill_id)
);
create index if not exists pskills_player_idx on public.player_skills(player_id);

create table if not exists public.player_stage_progress (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.profiles(id) on delete cascade,
  stage_id uuid not null references public.stages(id) on delete restrict,
  best_clear_time_ms integer check (best_clear_time_ms >= 0),
  cleared_count integer not null default 0 check (cleared_count >= 0),
  last_cleared_at timestamptz,
  updated_at timestamptz not null default now(),
  unique(player_id, stage_id)
);
create index if not exists pstg_player_idx on public.player_stage_progress(player_id);

-- ---------------------------------
-- Triggers updated_at
-- ---------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$ begin
  if not exists (select 1 from pg_trigger where tgname='profiles_updated_at') then
    create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname='items_updated_at') then
    create trigger items_updated_at before update on public.items for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname='skills_updated_at') then
    create trigger skills_updated_at before update on public.skills for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname='mobs_updated_at') then
    create trigger mobs_updated_at before update on public.mobs for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname='zones_updated_at') then
    create trigger zones_updated_at before update on public.zones for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname='stages_updated_at') then
    create trigger stages_updated_at before update on public.stages for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname='waves_updated_at') then
    create trigger waves_updated_at before update on public.waves for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname='loot_tables_updated_at') then
    create trigger loot_tables_updated_at before update on public.loot_tables for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname='player_stage_progress_updated_at') then
    create trigger player_stage_progress_updated_at before update on public.player_stage_progress for each row execute function public.set_updated_at();
  end if;
end $$;
