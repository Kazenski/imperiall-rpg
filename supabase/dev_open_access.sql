-- Imperiall RPG — acesso temporário SEM login (ambiente de cadastro)
--
-- ATENÇÃO: este arquivo é só para a fase de cadastro sem autenticação.
-- Quando o admin tiver login + role, REMOVA estas policies e volte ao
-- modelo admin-only de policies.sql / migration_002.
--
-- Aplicar DEPOIS de schema.sql + policies.sql (+ migration_002).

-- Leitura anônima do catálogo e de usuários (listas do admin)
drop policy if exists "tmp_anon_read_items" on public.items;
create policy "tmp_anon_read_items" on public.items for select to anon using (true);

drop policy if exists "tmp_anon_read_skills" on public.skills;
create policy "tmp_anon_read_skills" on public.skills for select to anon using (true);

drop policy if exists "tmp_anon_read_mobs" on public.mobs;
create policy "tmp_anon_read_mobs" on public.mobs for select to anon using (true);

drop policy if exists "tmp_anon_read_zones" on public.zones;
create policy "tmp_anon_read_zones" on public.zones for select to anon using (true);

drop policy if exists "tmp_anon_read_stages" on public.stages;
create policy "tmp_anon_read_stages" on public.stages for select to anon using (true);

drop policy if exists "tmp_anon_read_waves" on public.waves;
create policy "tmp_anon_read_waves" on public.waves for select to anon using (true);

drop policy if exists "tmp_anon_read_wave_mobs" on public.wave_mobs;
create policy "tmp_anon_read_wave_mobs" on public.wave_mobs for select to anon using (true);

drop policy if exists "tmp_anon_read_loot" on public.loot_tables;
create policy "tmp_anon_read_loot" on public.loot_tables for select to anon using (true);

drop policy if exists "tmp_anon_read_entries" on public.loot_table_entries;
create policy "tmp_anon_read_entries" on public.loot_table_entries for select to anon using (true);

drop policy if exists "tmp_anon_read_profiles" on public.profiles;
create policy "tmp_anon_read_profiles" on public.profiles for select to anon using (true);

drop policy if exists "tmp_anon_read_punish" on public.player_punishments;
create policy "tmp_anon_read_punish" on public.player_punishments for select to anon using (true);

-- Escrita anônima (cadastro via admin sem login)
drop policy if exists "tmp_anon_write_items" on public.items;
create policy "tmp_anon_write_items" on public.items for all to anon, authenticated using (true) with check (true);

drop policy if exists "tmp_anon_write_skills" on public.skills;
create policy "tmp_anon_write_skills" on public.skills for all to anon, authenticated using (true) with check (true);

drop policy if exists "tmp_anon_write_mobs" on public.mobs;
create policy "tmp_anon_write_mobs" on public.mobs for all to anon, authenticated using (true) with check (true);

drop policy if exists "tmp_anon_write_zones" on public.zones;
create policy "tmp_anon_write_zones" on public.zones for all to anon, authenticated using (true) with check (true);

drop policy if exists "tmp_anon_write_stages" on public.stages;
create policy "tmp_anon_write_stages" on public.stages for all to anon, authenticated using (true) with check (true);

drop policy if exists "tmp_anon_write_waves" on public.waves;
create policy "tmp_anon_write_waves" on public.waves for all to anon, authenticated using (true) with check (true);

drop policy if exists "tmp_anon_write_wave_mobs" on public.wave_mobs;
create policy "tmp_anon_write_wave_mobs" on public.wave_mobs for all to anon, authenticated using (true) with check (true);

drop policy if exists "tmp_anon_write_loot" on public.loot_tables;
create policy "tmp_anon_write_loot" on public.loot_tables for all to anon, authenticated using (true) with check (true);

drop policy if exists "tmp_anon_write_entries" on public.loot_table_entries;
create policy "tmp_anon_write_entries" on public.loot_table_entries for all to anon, authenticated using (true) with check (true);

drop policy if exists "tmp_anon_write_profiles" on public.profiles;
create policy "tmp_anon_write_profiles" on public.profiles for all to anon, authenticated using (true) with check (true);

drop policy if exists "tmp_anon_write_punish" on public.player_punishments;
create policy "tmp_anon_write_punish" on public.player_punishments for all to anon, authenticated using (true) with check (true);

-- Storage: upload anônimo no bucket assets (cadastro de imagens sem login)
drop policy if exists "tmp_assets_insert" on storage.objects;
create policy "tmp_assets_insert" on storage.objects for insert to anon, authenticated with check (bucket_id = 'assets');

drop policy if exists "tmp_assets_update" on storage.objects;
create policy "tmp_assets_update" on storage.objects for update to anon, authenticated using (bucket_id = 'assets') with check (bucket_id = 'assets');

drop policy if exists "tmp_assets_delete" on storage.objects;
create policy "tmp_assets_delete" on storage.objects for delete to anon, authenticated using (bucket_id = 'assets');
