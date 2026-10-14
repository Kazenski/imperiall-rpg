-- Imperiall RPG — migração 005: herói escolhido pelo jogador
-- Idempotente. Aplicar DEPOIS de schema.sql + policies.sql + migration_002..004.
--
-- Liga o perfil a um herói do catálogo (`characters`, criado na migration_003).
-- O jogador escolhe na aba "Heróis" do app e o jogo lê `profiles.character_id`.
--
-- A escrita é liberada pela policy já existente `profiles_update_self`
-- (using/with check: auth.uid() = id), então nenhum GRANT/policy extra é
-- necessário.

alter table public.profiles
  add column if not exists character_id uuid
    references public.characters (id) on delete set null;

create index if not exists profiles_character_idx
  on public.profiles (character_id);
