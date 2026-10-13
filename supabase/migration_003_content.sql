-- Imperiall RPG — migração 003: história, efeitos, personagens, profissões, craft
-- Idempotente. Aplicar DEPOIS de schema.sql + policies.sql (+ migration_002).
--
-- Blocos:
--  A. NPCs e história visual (npcs, stories, story_scenes, story_lines,
--     story_choices, player_story_progress)
--  B. Catálogo de efeitos (effects, skill_effects, item_effects)
--  C. Personagens jogáveis (characters, character_skills, character_traits,
--     skill_nodes = árvore de habilidades)
--  D. Profissões e craft (professions, recipes, recipe_materials,
--     item_upgrade_levels, item_upgrade_materials)

-- =====================================================================
-- A. NPCs e história
-- =====================================================================

create table if not exists public.npcs (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  portrait_url text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  cover_url text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.story_scenes (
  id uuid primary key default gen_random_uuid(),
  story_id uuid not null references public.stories (id) on delete cascade,
  order_index integer not null default 0,
  title text,
  background_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (story_id, order_index)
);
create index if not exists story_scenes_story_idx on public.story_scenes (story_id);

create table if not exists public.story_lines (
  id uuid primary key default gen_random_uuid(),
  scene_id uuid not null references public.story_scenes (id) on delete cascade,
  order_index integer not null default 0,
  speaker_type text not null default 'narrator'
    check (speaker_type in ('narrator', 'npc', 'player')),
  speaker_name text,
  npc_id uuid references public.npcs (id) on delete set null,
  text text not null,
  portrait_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (scene_id, order_index)
);
create index if not exists story_lines_scene_idx on public.story_lines (scene_id);

-- Escolha ao final de uma fala: pula para outra cena e pode dar recompensa.
create table if not exists public.story_choices (
  id uuid primary key default gen_random_uuid(),
  line_id uuid not null references public.story_lines (id) on delete cascade,
  label text not null,
  next_scene_id uuid references public.story_scenes (id) on delete set null,
  reward_xp integer not null default 0 check (reward_xp >= 0),
  reward_item_id uuid references public.items (id) on delete set null,
  reward_qty integer not null default 1 check (reward_qty >= 1),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists story_choices_line_idx on public.story_choices (line_id);

-- Trajetória do jogador na história (quais escolhas fez).
create table if not exists public.player_story_progress (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.profiles (id) on delete cascade,
  story_id uuid not null references public.stories (id) on delete cascade,
  current_scene_id uuid references public.story_scenes (id) on delete set null,
  completed boolean not null default false,
  choice_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now(),
  unique (player_id, story_id)
);
create index if not exists pstory_player_idx on public.player_story_progress (player_id);

-- =====================================================================
-- B. Catálogo de efeitos (reutilizável por skills, itens e personagens)
-- =====================================================================

create table if not exists public.effects (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  category text not null default 'utility'
    check (category in ('buff', 'debuff', 'heal', 'damage', 'utility', 'control')),
  target text not null default 'enemy'
    check (target in ('self', 'enemy', 'enemies', 'ally', 'allies', 'aoe')),
  value_kind text not null default 'flat'
    check (value_kind in ('flat', 'percent', 'ms', 'seconds', 'count')),
  default_value numeric not null default 0,
  icon_url text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.skill_effects (
  id uuid primary key default gen_random_uuid(),
  skill_id uuid not null references public.skills (id) on delete cascade,
  effect_id uuid not null references public.effects (id) on delete restrict,
  value numeric not null default 0,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (skill_id, effect_id)
);
create index if not exists skill_effects_skill_idx on public.skill_effects (skill_id);

create table if not exists public.item_effects (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items (id) on delete cascade,
  effect_id uuid not null references public.effects (id) on delete restrict,
  value numeric not null default 0,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (item_id, effect_id)
);
create index if not exists item_effects_item_idx on public.item_effects (item_id);

-- =====================================================================
-- C. Personagens jogáveis + árvore de habilidades
-- =====================================================================

create table if not exists public.characters (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  portrait_url text,
  sprite_idle_url text,
  sprite_attack_url text,
  hp integer not null default 100 check (hp >= 1),
  atk integer not null default 10 check (atk >= 0),
  def integer not null default 5 check (def >= 0),
  speed integer not null default 100 check (speed >= 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.character_skills (
  id uuid primary key default gen_random_uuid(),
  character_id uuid not null references public.characters (id) on delete cascade,
  skill_id uuid not null references public.skills (id) on delete restrict,
  unlock_level integer not null default 1 check (unlock_level >= 1),
  created_at timestamptz not null default now(),
  unique (character_id, skill_id)
);
create index if not exists character_skills_char_idx on public.character_skills (character_id);

-- Vantagem/desvantagem por ambiente (environment ex.: 'floresta'; null = sempre).
create table if not exists public.character_traits (
  id uuid primary key default gen_random_uuid(),
  character_id uuid not null references public.characters (id) on delete cascade,
  effect_id uuid not null references public.effects (id) on delete restrict,
  value numeric not null default 0,
  environment text,
  created_at timestamptz not null default now(),
  unique (character_id, effect_id, environment)
);
create index if not exists character_traits_char_idx on public.character_traits (character_id);

-- Nó da árvore de habilidades (posição na grade + custos + pré-requisitos).
create table if not exists public.skill_nodes (
  id uuid primary key default gen_random_uuid(),
  character_id uuid not null references public.characters (id) on delete cascade,
  skill_id uuid not null references public.skills (id) on delete restrict,
  position_x integer not null default 0,
  position_y integer not null default 0,
  cost_points integer not null default 1 check (cost_points >= 0),
  cost_gold integer not null default 0 check (cost_gold >= 0),
  required_level integer not null default 1 check (required_level >= 1),
  requires_node_id uuid references public.skill_nodes (id) on delete set null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (character_id, skill_id)
);
create index if not exists skill_nodes_char_idx on public.skill_nodes (character_id);

-- =====================================================================
-- D. Profissões, receitas e upgrades
-- =====================================================================

create table if not exists public.professions (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  description text,
  icon_url text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recipes (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  output_item_id uuid not null references public.items (id) on delete restrict,
  output_qty integer not null default 1 check (output_qty >= 1),
  profession_id uuid references public.professions (id) on delete set null,
  required_prof_level integer not null default 1 check (required_prof_level >= 1),
  cost_gold integer not null default 0 check (cost_gold >= 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists recipes_prof_idx on public.recipes (profession_id);

create table if not exists public.recipe_materials (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references public.recipes (id) on delete cascade,
  item_id uuid not null references public.items (id) on delete restrict,
  qty integer not null default 1 check (qty >= 1),
  created_at timestamptz not null default now(),
  unique (recipe_id, item_id)
);
create index if not exists recipe_materials_recipe_idx on public.recipe_materials (recipe_id);

-- Níveis de upgrade por item (ex.: Espada +1..+10).
create table if not exists public.item_upgrade_levels (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.items (id) on delete cascade,
  level integer not null check (level >= 1),
  stat_mult numeric not null default 1 check (stat_mult >= 1),
  cost_gold integer not null default 0 check (cost_gold >= 0),
  created_at timestamptz not null default now(),
  unique (item_id, level)
);
create index if not exists upgrade_levels_item_idx on public.item_upgrade_levels (item_id);

create table if not exists public.item_upgrade_materials (
  id uuid primary key default gen_random_uuid(),
  upgrade_id uuid not null references public.item_upgrade_levels (id) on delete cascade,
  item_id uuid not null references public.items (id) on delete restrict,
  qty integer not null default 1 check (qty >= 1),
  created_at timestamptz not null default now(),
  unique (upgrade_id, item_id)
);
create index if not exists upgrade_mats_upgrade_idx on public.item_upgrade_materials (upgrade_id);

-- =====================================================================
-- RLS: catálogo público p/ leitura, admin escreve; progresso é do dono
-- =====================================================================

alter table public.npcs enable row level security;
alter table public.stories enable row level security;
alter table public.story_scenes enable row level security;
alter table public.story_lines enable row level security;
alter table public.story_choices enable row level security;
alter table public.player_story_progress enable row level security;
alter table public.effects enable row level security;
alter table public.skill_effects enable row level security;
alter table public.item_effects enable row level security;
alter table public.characters enable row level security;
alter table public.character_skills enable row level security;
alter table public.character_traits enable row level security;
alter table public.skill_nodes enable row level security;
alter table public.professions enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_materials enable row level security;
alter table public.item_upgrade_levels enable row level security;
alter table public.item_upgrade_materials enable row level security;

do $$ begin
  -- npcs
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='npcs' and policyname='npcs_read_all') then
    create policy "npcs_read_all" on public.npcs for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='npcs' and policyname='npcs_admin_crud') then
    create policy "npcs_admin_crud" on public.npcs for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- stories
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='stories' and policyname='stories_read_all') then
    create policy "stories_read_all" on public.stories for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='stories' and policyname='stories_admin_crud') then
    create policy "stories_admin_crud" on public.stories for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- story_scenes
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='story_scenes' and policyname='scenes_read_all') then
    create policy "scenes_read_all" on public.story_scenes for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='story_scenes' and policyname='scenes_admin_crud') then
    create policy "scenes_admin_crud" on public.story_scenes for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- story_lines
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='story_lines' and policyname='lines_read_all') then
    create policy "lines_read_all" on public.story_lines for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='story_lines' and policyname='lines_admin_crud') then
    create policy "lines_admin_crud" on public.story_lines for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- story_choices
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='story_choices' and policyname='choices_read_all') then
    create policy "choices_read_all" on public.story_choices for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='story_choices' and policyname='choices_admin_crud') then
    create policy "choices_admin_crud" on public.story_choices for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- effects
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='effects' and policyname='effects_read_all') then
    create policy "effects_read_all" on public.effects for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='effects' and policyname='effects_admin_crud') then
    create policy "effects_admin_crud" on public.effects for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- skill_effects
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skill_effects' and policyname='skilleff_read_all') then
    create policy "skilleff_read_all" on public.skill_effects for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skill_effects' and policyname='skilleff_admin_crud') then
    create policy "skilleff_admin_crud" on public.skill_effects for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- item_effects
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='item_effects' and policyname='itemeff_read_all') then
    create policy "itemeff_read_all" on public.item_effects for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='item_effects' and policyname='itemeff_admin_crud') then
    create policy "itemeff_admin_crud" on public.item_effects for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- characters
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='characters' and policyname='characters_read_all') then
    create policy "characters_read_all" on public.characters for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='characters' and policyname='characters_admin_crud') then
    create policy "characters_admin_crud" on public.characters for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- character_skills
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='character_skills' and policyname='charskills_read_all') then
    create policy "charskills_read_all" on public.character_skills for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='character_skills' and policyname='charskills_admin_crud') then
    create policy "charskills_admin_crud" on public.character_skills for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- character_traits
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='character_traits' and policyname='traits_read_all') then
    create policy "traits_read_all" on public.character_traits for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='character_traits' and policyname='traits_admin_crud') then
    create policy "traits_admin_crud" on public.character_traits for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- skill_nodes
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skill_nodes' and policyname='nodes_read_all') then
    create policy "nodes_read_all" on public.skill_nodes for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='skill_nodes' and policyname='nodes_admin_crud') then
    create policy "nodes_admin_crud" on public.skill_nodes for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- professions
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='professions' and policyname='professions_read_all') then
    create policy "professions_read_all" on public.professions for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='professions' and policyname='professions_admin_crud') then
    create policy "professions_admin_crud" on public.professions for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- recipes
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='recipes' and policyname='recipes_read_all') then
    create policy "recipes_read_all" on public.recipes for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='recipes' and policyname='recipes_admin_crud') then
    create policy "recipes_admin_crud" on public.recipes for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- recipe_materials
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='recipe_materials' and policyname='recipemats_read_all') then
    create policy "recipemats_read_all" on public.recipe_materials for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='recipe_materials' and policyname='recipemats_admin_crud') then
    create policy "recipemats_admin_crud" on public.recipe_materials for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- item_upgrade_levels
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='item_upgrade_levels' and policyname='upgrades_read_all') then
    create policy "upgrades_read_all" on public.item_upgrade_levels for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='item_upgrade_levels' and policyname='upgrades_admin_crud') then
    create policy "upgrades_admin_crud" on public.item_upgrade_levels for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
  -- item_upgrade_materials
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='item_upgrade_materials' and policyname='upgrademats_read_all') then
    create policy "upgrademats_read_all" on public.item_upgrade_materials for select to authenticated using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='item_upgrade_materials' and policyname='upgrademats_admin_crud') then
    create policy "upgrademats_admin_crud" on public.item_upgrade_materials for all to authenticated using (public.is_admin()) with check (public.is_admin());
  end if;
end $$;

drop policy if exists "pstory_self_crud" on public.player_story_progress;
create policy "pstory_self_crud"
  on public.player_story_progress for all to authenticated
  using (auth.uid() = player_id) with check (auth.uid() = player_id);

-- Grants (leitura p/ anon + authenticated; escrita autenticada via RLS)
grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to anon, authenticated;
grant insert, update, delete on table
  public.npcs, public.stories, public.story_scenes, public.story_lines,
  public.story_choices, public.effects, public.skill_effects, public.item_effects,
  public.characters, public.character_skills, public.character_traits,
  public.skill_nodes, public.professions, public.recipes, public.recipe_materials,
  public.item_upgrade_levels, public.item_upgrade_materials,
  public.player_story_progress
  to authenticated;
grant usage, select on all sequences in schema public to authenticated;
