# Imperiall RPG - Supabase Setup

## Ordem de aplicação (SQL Editor)

1. `schema.sql` - Tabelas, triggers, funções
2. `policies.sql` - RLS + policies
3. `migration_002_punishments.sql` - Moderação (mute/ban)
4. `migration_003_content.sql` - NPCs, história, efeitos, heróis, profissões, craft
5. `migration_004_audit.sql` - Log de auditoria do admin
6. `migration_005_player_character.sql` - Herói escolhido pelo jogador
7. `storage.sql` - Bucket `assets` + policies (admin pode upload)

Todos são **idempotentes**.

## Admin role

O app distingue `role` em `profiles.role` (`user` ou `admin`).

Para tornar um usuário admin:

```sql
update public.profiles
   set role = 'admin'
 where id = '<uuid-do-usuario>';
```

Ou, via email:

```sql
update public.profiles p
   set role = 'admin'
  from auth.users u
 where u.id = p.id
   and u.email = 'seu-email@exemplo.com';
```

## Catálogo vs Progresso

- **Catálogo** (items, skills, mobs, zones, stages, waves, loot_tables): leitura pública/auth, **somente admin** escreve.
- **Progresso jogador** (player_inventory, player_equipment, player_skills, player_stage_progress): **somente o próprio usuário** (RLS por `auth.uid()`).

## Storage (assets)

Bucket `assets` é **público** (URLs acessíveis direto). Upload/Update/Delete **restrito a admins** via RLS no Storage.
Tamanhos: max 5MB, formatos: PNG/JPEG/WebP/GIF. Organizar por pastas: `mobs/`, `items/`, `skills/`, `ui/`, `backgrounds/`.
