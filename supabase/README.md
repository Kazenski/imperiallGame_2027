# Banco de dados (Supabase)

Como preparar o projeto Supabase para o app **connected mode** (v0.2.0+).

## Arquivos

| Arquivo | O que faz |
|---|---|
| `schema.sql` | Tabelas, índices, RPCs (`ensure_player`, `sync_game_state`, `reset_progress`, `guild_members`, `award_xp`) e a view `guild_ranking`. |
| `policies.sql` | Row Level Security: liga RLS e cria todas as policies. |

Ambos são **idempotentes** — podem ser executados mais de uma vez sem erro.

## Passo a passo (SQL Editor)

1. Abra o projeto no [Supabase Dashboard](https://supabase.com/dashboard) → **SQL Editor**.
2. Cole **todo** o conteúdo de [`schema.sql`](./schema.sql) e clique em **Run**.
3. Cole **todo** o conteúdo de [`policies.sql`](./policies.sql) e clique em **Run**.
4. (Recomendado) Confira que toda tabela tem RLS ligada:

   ```sql
   select schemaname, tablename, rowsecurity
     from pg_tables
    where schemaname = 'public'
    order by rowsecurity asc, tablename;
   ```

## Autenticação

No dashboard, em **Authentication → Providers → Email**:

- Para testes rápidos, você pode desligar **Confirm email** (o cadastro entra direto).
- Em produção, mantenha ligado — o app já trata o caso "confirme seu e-mail".

## O que o app grava

O cliente **não** faz `UPDATE` direto em `players`. Toda gravação de progresso passa
pela RPC `sync_game_state`, que:

- recalcula o **nível** a partir do XP (o cliente não decide o nível);
- grava o XP de forma **monotônica** (`greatest`) — nunca regride;
- insere atividades de forma **idempotente** por `client_ref`;
- faz `upsert` de missões e `insert` de conquistas (imutáveis).

Os invariantes são garantidos no servidor; as regras de progressão (quanto XP cada
treino vale, quando uma missão completa) rodam no app e migrarão para o servidor na
v0.3.0. Detalhes do modelo de confiança em [`../docs/SECURITY.md`](../docs/SECURITY.md).

## Verificação rápida das RPCs

Com um usuário logado (o app cuida disso), o servidor responde:

```sql
-- cria perfil + player do usuário autenticado
select * from public.ensure_player('Seu Nome');

-- sua guilda (se houver)
select * from public.guild_members('<uuid-da-guilda>');
```
