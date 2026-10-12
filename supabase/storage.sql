-- Supabase Storage buckets + policies
-- Aplicar após schema/policies

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('assets', 'assets', true, 5242880, array['image/png','image/jpeg','image/webp','image/gif'])
on conflict (id) do update set public = true;

-- allow read for all
create policy if not exists "assets_read_public"
  on storage.objects for select
  to public
  using (bucket_id = 'assets');

-- allow upload/update/delete only for admins
create policy if not exists "assets_admin_write"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'assets' and public.is_admin(auth.uid()));

create policy if not exists "assets_admin_update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'assets' and public.is_admin(auth.uid()))
  with check (bucket_id = 'assets' and public.is_admin(auth.uid()));

create policy if not exists "assets_admin_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'assets' and public.is_admin(auth.uid()));
