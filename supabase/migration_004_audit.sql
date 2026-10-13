-- Imperiall RPG — migração 004: auditoria de alterações (log completo)
-- Idempotente. Aplicar DEPOIS das anteriores.
--
-- Um trigger em cada tabela de catálogo/dados grava INSERT/UPDATE/DELETE em
-- public.admin_audit_log com data precisa, ator, entidade e resumo.
-- A função é SECURITY DEFINER: grava mesmo quando o usuário só tem as
-- policies normais de escrita.

create table if not exists public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  action text not null check (action in ('insert', 'update', 'delete')),
  entity text not null,
  entity_id text,
  summary text,
  data jsonb,
  actor text
);

create index if not exists audit_created_idx
  on public.admin_audit_log (created_at desc);
create index if not exists audit_entity_idx
  on public.admin_audit_log (entity, created_at desc);

alter table public.admin_audit_log enable row level security;

drop policy if exists "audit_admin_all" on public.admin_audit_log;
create policy "audit_admin_all"
  on public.admin_audit_log for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select on table public.admin_audit_log to authenticated;
grant usage, select on all sequences in schema public to authenticated;

create or replace function public.log_admin_audit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_data jsonb;
  v_summary text;
  v_eid text;
begin
  if TG_OP = 'DELETE' then
    v_data := to_jsonb(OLD);
  else
    v_data := to_jsonb(NEW);
  end if;

  v_eid := coalesce(v_data ->> 'id', '');
  v_summary := coalesce(
    v_data ->> 'slug',
    v_data ->> 'name',
    v_data ->> 'username',
    v_data ->> 'label',
    v_data ->> 'title',
    v_eid,
    ''
  );

  insert into public.admin_audit_log (action, entity, entity_id, summary, data, actor)
  values (
    lower(TG_OP),
    TG_TABLE_NAME,
    nullif(v_eid, ''),
    nullif(v_summary, ''),
    v_data,
    coalesce(auth.uid()::text, current_user)
  );

  if TG_OP = 'DELETE' then
    return OLD;
  else
    return NEW;
  end if;
end;
$$;

-- Aplica o trigger em todas as tabelas de conteúdo e dados do jogo.
do $$
declare
  t text;
  tables text[] := array[
    'profiles', 'items', 'skills', 'mobs', 'zones', 'stages',
    'waves', 'wave_mobs', 'loot_tables', 'loot_table_entries',
    'player_inventory', 'player_equipment', 'player_skills',
    'player_stage_progress', 'player_punishments',
    'npcs', 'stories', 'story_scenes', 'story_lines', 'story_choices',
    'player_story_progress', 'effects', 'skill_effects', 'item_effects',
    'characters', 'character_skills', 'character_traits', 'skill_nodes',
    'professions', 'recipes', 'recipe_materials',
    'item_upgrade_levels', 'item_upgrade_materials'
  ];
begin
  foreach t in array tables
  loop
    execute format('drop trigger if exists audit_%I on public.%I', t, t);
    execute format(
      'create trigger audit_%I after insert or update or delete on public.%I ' ||
      'for each row execute function public.log_admin_audit()',
      t, t
    );
  end loop;
end $$;
