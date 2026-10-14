-- Imperiall RPG — conteúdo de exemplo (OPCIONAL, idempotente).
-- Aplicar DEPOIS de schema.sql + policies.sql + migrações.
--
-- Só serve para a tela de Fases do app (ondas/recompensas) ter o que mostrar
-- enquanto o catálogo real é cadastrado no painel admin. Pode ser ignorado ou
-- removido sem problema.
--
-- Usa os slugs já existentes no catálogo atual:
--   zona:   zona_renstenci_01
--   fases:  zona_renstenci_01_cidade_x, zona_renstenci_01_cidade_y
--   mob:    slime_normal_01
--   item:   teste_01
-- Ajuste os slugs abaixo caso o seu catálogo seja diferente.

-- ---------------------------------------------------------------------------
-- Ondas — Cidade X
-- ---------------------------------------------------------------------------
insert into public.waves (stage_id, wave_number, spawn_delay_ms)
select s.id, 1, 500
from public.stages s
where s.slug = 'zona_renstenci_01_cidade_x'
on conflict (stage_id, wave_number) do nothing;

insert into public.wave_mobs (wave_id, mob_id, quantity, delay_between_ms, sort_order)
select w.id, m.id, 3, 250, 0
from public.waves w
join public.stages s on s.id = w.stage_id
join public.mobs m on m.slug = 'slime_normal_01'
where s.slug = 'zona_renstenci_01_cidade_x'
  and w.wave_number = 1
  and not exists (
    select 1 from public.wave_mobs wm
    where wm.wave_id = w.id and wm.mob_id = m.id
  );

insert into public.waves (stage_id, wave_number, spawn_delay_ms)
select s.id, 2, 500
from public.stages s
where s.slug = 'zona_renstenci_01_cidade_x'
on conflict (stage_id, wave_number) do nothing;

insert into public.wave_mobs (wave_id, mob_id, quantity, delay_between_ms, sort_order)
select w.id, m.id, 5, 250, 0
from public.waves w
join public.stages s on s.id = w.stage_id
join public.mobs m on m.slug = 'slime_normal_01'
where s.slug = 'zona_renstenci_01_cidade_x'
  and w.wave_number = 2
  and not exists (
    select 1 from public.wave_mobs wm
    where wm.wave_id = w.id and wm.mob_id = m.id
  );

-- ---------------------------------------------------------------------------
-- Ondas — Cidade Y
-- ---------------------------------------------------------------------------
insert into public.waves (stage_id, wave_number, spawn_delay_ms)
select s.id, 1, 500
from public.stages s
where s.slug = 'zona_renstenci_01_cidade_y'
on conflict (stage_id, wave_number) do nothing;

insert into public.wave_mobs (wave_id, mob_id, quantity, delay_between_ms, sort_order)
select w.id, m.id, 5, 250, 0
from public.waves w
join public.stages s on s.id = w.stage_id
join public.mobs m on m.slug = 'slime_normal_01'
where s.slug = 'zona_renstenci_01_cidade_y'
  and w.wave_number = 1
  and not exists (
    select 1 from public.wave_mobs wm
    where wm.wave_id = w.id and wm.mob_id = m.id
  );

-- ---------------------------------------------------------------------------
-- Loot — Cidade X (item garantido, 1-2 unidades)
-- ---------------------------------------------------------------------------
insert into public.loot_tables (slug, name, stage_id, is_active)
select 'loot_cidade_x_01', 'Recompensas — Cidade X', s.id, true
from public.stages s
where s.slug = 'zona_renstenci_01_cidade_x'
on conflict (slug) do nothing;

insert into public.loot_table_entries
  (loot_table_id, item_id, quantity_min, quantity_max, drop_chance_percent, guaranteed, sort_order)
select lt.id, i.id, 1, 2, null, true, 0
from public.loot_tables lt
join public.items i on i.slug = 'teste_01'
where lt.slug = 'loot_cidade_x_01'
  and not exists (
    select 1 from public.loot_table_entries e
    where e.loot_table_id = lt.id and e.item_id = i.id
  );

-- ---------------------------------------------------------------------------
-- Loot — Cidade Y (item com 50% de chance)
-- ---------------------------------------------------------------------------
insert into public.loot_tables (slug, name, stage_id, is_active)
select 'loot_cidade_y_01', 'Recompensas — Cidade Y', s.id, true
from public.stages s
where s.slug = 'zona_renstenci_01_cidade_y'
on conflict (slug) do nothing;

insert into public.loot_table_entries
  (loot_table_id, item_id, quantity_min, quantity_max, drop_chance_percent, guaranteed, sort_order)
select lt.id, i.id, 1, 1, 50, false, 0
from public.loot_tables lt
join public.items i on i.slug = 'teste_01'
where lt.slug = 'loot_cidade_y_01'
  and not exists (
    select 1 from public.loot_table_entries e
    where e.loot_table_id = lt.id and e.item_id = i.id
  );

-- Fim. Verifique no app: Fases → toque numa fase → "Ondas" e "Recompensas".
