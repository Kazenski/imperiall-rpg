-- Supabase Storage buckets + policies
-- Aplicar após schema/policies
-- Idempotente: cada policy é removida antes de ser recriada.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('assets', 'assets', true, 5242880, array['image/png','image/jpeg','image/webp','image/gif'])
on conflict (id) do update set public = true;

-- leitura pública
drop policy if exists "assets_read_public" on storage.objects;
create policy "assets_read_public"
  on storage.objects for select
  to public
  using (bucket_id = 'assets');

-- escrita só para admins
drop policy if exists "assets_admin_write" on storage.objects;
create policy "assets_admin_write"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'assets' and public.is_admin(auth.uid()));

drop policy if exists "assets_admin_update" on storage.objects;
create policy "assets_admin_update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'assets' and public.is_admin(auth.uid()))
  with check (bucket_id = 'assets' and public.is_admin(auth.uid()));

drop policy if exists "assets_admin_delete" on storage.objects;
create policy "assets_admin_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'assets' and public.is_admin(auth.uid()));
