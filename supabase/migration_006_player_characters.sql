-- Imperiall RPG — migração 006: vários heróis por jogador
-- Idempotente. Aplicar DEPOIS de schema.sql + policies.sql + migrations 002..005.
--
-- Até a 005 o jogador tinha UM herói: `profiles.character_id` (qual herói do
-- catálogo) e o nível/XP ficavam em `profiles`. Aqui nasce `player_characters`:
-- cada linha é uma INSTÂNCIA de um herói do catálogo com progresso próprio,
-- então dá para ter vários heróis e criar um novo que começa do zero.
--
-- `profiles.active_player_character_id` aponta para o herói em uso (o nível/XP
-- do perfil continuam sendo espelho do herói ativo, para compatibilidade).
--
-- O app detecta sozinho se esta migração já foi aplicada: sem a tabela, ele
-- continua no modelo antigo (herói único).

create table if not exists public.player_characters (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references auth.users (id) on delete cascade,
  character_id uuid not null references public.characters (id) on delete cascade,
  name text,
  level integer not null default 1 check (level >= 1),
  xp bigint not null default 0 check (xp >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists player_characters_player_idx
  on public.player_characters (player_id);

create index if not exists player_characters_character_idx
  on public.player_characters (character_id);

alter table public.profiles
  add column if not exists active_player_character_id uuid
    references public.player_characters (id) on delete set null;

-- ---------------------------------
-- RLS: cada jogador só vê/edita os próprios heróis
-- ---------------------------------
alter table public.player_characters enable row level security;

drop policy if exists "player_characters_select_own" on public.player_characters;
create policy "player_characters_select_own"
  on public.player_characters for select to authenticated
  using (player_id = auth.uid());

drop policy if exists "player_characters_insert_own" on public.player_characters;
create policy "player_characters_insert_own"
  on public.player_characters for insert to authenticated
  with check (player_id = auth.uid());

drop policy if exists "player_characters_update_own" on public.player_characters;
create policy "player_characters_update_own"
  on public.player_characters for update to authenticated
  using (player_id = auth.uid())
  with check (player_id = auth.uid());

drop policy if exists "player_characters_delete_own" on public.player_characters;
create policy "player_characters_delete_own"
  on public.player_characters for delete to authenticated
  using (player_id = auth.uid());

-- ---------------------------------
-- Migra o herói já escolhido (modelo antigo) para a nova tabela
-- ---------------------------------
insert into public.player_characters (player_id, character_id, level, xp)
select p.id, p.character_id, p.level, p.xp
from public.profiles p
where p.character_id is not null
  and not exists (
    select 1 from public.player_characters pc where pc.player_id = p.id
  );

-- Ativa o primeiro herói de quem ainda não tiver um ativo.
update public.profiles p
set active_player_character_id = (
  select pc.id
  from public.player_characters pc
  where pc.player_id = p.id
  order by pc.created_at
  limit 1
)
where p.active_player_character_id is null;
