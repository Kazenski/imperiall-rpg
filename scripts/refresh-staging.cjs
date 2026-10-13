/**
 * refresh-staging.cjs — copia o CATÁLOGO do banco oficial para o staging.
 *
 * Apaga o catálogo atual do staging e copia tudo do oficial (mesmos ids,
 * então os vínculos entre tabelas continuam valendo).
 *
 * NÃO copia: perfis, punições nem progresso de jogadores (dado de usuário
 * não viaja para o teste). Imagens continuam apontando para o bucket
 * oficial (URLs públicas, funcionam nos dois).
 *
 * Uso (PowerShell):
 *   $env:PROD_URL="https://xxx.supabase.co"; $env:PROD_KEY="sb_publishable_..."
 *   $env:STAGING_URL="https://yyy.supabase.co"; $env:STAGING_KEY="sb_publishable_..."
 *   node scripts/refresh-staging.cjs
 */
const PROD = { url: process.env.PROD_URL, key: process.env.PROD_KEY };
const STAG = { url: process.env.STAGING_URL, key: process.env.STAGING_KEY };

if (!PROD.url || !PROD.key || !STAG.url || !STAG.key) {
  console.error('Defina PROD_URL, PROD_KEY, STAGING_URL e STAGING_KEY.');
  process.exit(1);
}

// Pais antes dos filhos na inserção; exclusão faz o caminho inverso.
const INSERT_ORDER = [
  'items', 'skills', 'effects', 'mobs', 'zones', 'npcs', 'professions',
  'stories', 'characters', 'stages', 'story_scenes', 'recipes',
  'skill_nodes', 'story_lines', 'loot_tables', 'waves',
  'character_skills', 'character_traits', 'skill_effects', 'item_effects',
  'recipe_materials', 'item_upgrade_levels', 'story_choices',
  'wave_mobs', 'loot_table_entries', 'item_upgrade_materials',
];
const DELETE_ORDER = [...INSERT_ORDER].reverse();

const H = (k) => ({ apikey: k, Authorization: 'Bearer ' + k, 'Content-Type': 'application/json', Prefer: 'return=representation' });
const ALL = 'id=neq.00000000-0000-0000-0000-000000000000';

async function readAll(db, table) {
  const rows = [];
  let offset = 0;
  for (;;) {
    const r = await fetch(`${db.url}/rest/v1/${table}?select=*&limit=1000&offset=${offset}`, { headers: { apikey: db.key, Authorization: 'Bearer ' + db.key } });
    if (!r.ok) throw new Error(`leitura ${table}: HTTP ${r.status} ${(await r.text()).slice(0, 120)}`);
    const page = await r.json();
    rows.push(...page);
    if (page.length < 1000) break;
    offset += 1000;
  }
  return rows;
}

async function wipe(db, table) {
  const r = await fetch(`${db.url}/rest/v1/${table}?${ALL}`, { method: 'DELETE', headers: H(db.key) });
  if (!r.ok) throw new Error(`limpeza ${table}: HTTP ${r.status} ${(await r.text()).slice(0, 120)}`);
}

async function insertAll(db, table, rows) {
  if (rows.length === 0) return;
  // skill_nodes tem auto-referência: insere sem o pré-requisito e ajusta depois.
  let fixups = [];
  let payload = rows;
  if (table === 'skill_nodes') {
    fixups = rows.filter((n) => n.requires_node_id).map((n) => ({ id: n.id, requires_node_id: n.requires_node_id }));
    payload = rows.map((n) => ({ ...n, requires_node_id: null }));
  }
  const r = await fetch(`${db.url}/rest/v1/${table}`, { method: 'POST', headers: H(db.key), body: JSON.stringify(payload) });
  if (!r.ok) throw new Error(`cópia ${table}: HTTP ${r.status} ${(await r.text()).slice(0, 160)}`);
  for (const f of fixups) {
    const u = await fetch(`${db.url}/rest/v1/${table}?id=eq.${f.id}`, { method: 'PATCH', headers: H(db.key), body: JSON.stringify({ requires_node_id: f.requires_node_id }) });
    if (!u.ok) throw new Error(`ajuste ${table}: HTTP ${u.status}`);
  }
}

(async () => {
  console.log('Limpando staging...');
  for (const t of DELETE_ORDER) await wipe(STAG, t);
  console.log('Copiando oficial -> staging...');
  for (const t of INSERT_ORDER) {
    const rows = await readAll(PROD, t);
    await insertAll(STAG, t, rows);
    console.log(`  ${t}: ${rows.length} linha(s)`);
  }
  console.log('\nSTAGING SINCRONIZADO COM A PRODUÇÃO');
})().catch((e) => { console.error('\nFALHOU: ' + e.message); process.exit(1); });
