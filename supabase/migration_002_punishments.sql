-- Imperiall RPG — migração 002: moderação (silenciar/banir)
-- Idempotente. Aplicar DEPOIS de schema.sql + policies.sql.
--
-- Como o jogo usa: ao entrar, o cliente lê `profiles.muted_until` e
-- `profiles.banned_until` do próprio usuário. Se `banned_until` for futuro,
-- bloqueia o acesso; se `muted_until` for futuro, desativa o chat.

-- Colunas de punição ativa (leitura rápida pelo jogo)
alter table public.profiles
  add column if not exists muted_until timestamptz,
  add column if not exists banned_until timestamptz;

-- Histórico de punições
create table if not exists public.player_punishments (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.profiles (id) on delete cascade,
  type text not null check (type in ('mute', 'ban', 'warning')),
  reason text,
  expires_at timestamptz,
  created_by uuid references public.profiles (id) on delete set null,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists punish_player_idx
  on public.player_punishments (player_id, created_at desc);

alter table public.player_punishments enable row level security;

-- Admin gerencia tudo; jogador lê só o próprio histórico
drop policy if exists "punish_admin_all" on public.player_punishments;
create policy "punish_admin_all"
  on public.player_punishments for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "punish_read_own" on public.player_punishments;
create policy "punish_read_own"
  on public.player_punishments for select
  to authenticated
  using (auth.uid() = player_id);

grant select, insert, update, delete on table public.player_punishments to authenticated;
grant usage, select on all sequences in schema public to authenticated;
