-- =====================================================================
--  Imperiall Game — Row Level Security
--
--  Idempotente: pode rodar mais de uma vez no SQL Editor sem erro
--  (cada policy e removida antes de ser recriada).
--
--  Regra: RLS ligada em TODAS as tabelas, com policy EXPLÍCITA.
--  "RLS ligada sem policy" bloqueia tudo (ok, mas ruidoso);
--  "policy USING (true)" libera tudo (falha de segurança grave).
-- =====================================================================

-- ---------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------
alter table public.profiles enable row level security;

-- Qualquer usuário autenticado pode ler perfis (necessário p/ ranking/guilda),
-- mas só o dono altera o próprio.
drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_authenticated"
    on public.profiles for select
    to authenticated
    using (true);

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
    on public.profiles for insert
    to authenticated
    with check (auth.uid() = id);

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
    on public.profiles for update
    to authenticated
    using (auth.uid() = id)
    with check (auth.uid() = id);

-- ---------------------------------------------------------------------
-- players
--   SELECT liberado p/ ranking; UPDATE e INSERT APENAS via award_xp.
-- ---------------------------------------------------------------------
alter table public.players enable row level security;

drop policy if exists "players_select_authenticated" on public.players;
create policy "players_select_authenticated"
    on public.players for select
    to authenticated
    using (true);

drop policy if exists "players_insert_self" on public.players;
create policy "players_insert_self"
    on public.players for insert
    to authenticated
    with check (auth.uid() = id);

-- Nenhuma policy de UPDATE: XP/atributos só mudam pela função award_xp
-- (security definer). Isso impede o cliente de injetar XP direto.

-- ---------------------------------------------------------------------
-- activities — só o dono vê e cria. Imutável (sem update/delete pelo cliente).
-- ---------------------------------------------------------------------
alter table public.activities enable row level security;

drop policy if exists "activities_select_own" on public.activities;
create policy "activities_select_own"
    on public.activities for select
    to authenticated
    using (auth.uid() = player_id);

drop policy if exists "activities_insert_own" on public.activities;
create policy "activities_insert_own"
    on public.activities for insert
    to authenticated
    with check (auth.uid() = player_id);

-- ---------------------------------------------------------------------
-- quest_progress
-- ---------------------------------------------------------------------
alter table public.quest_progress enable row level security;

drop policy if exists "quest_progress_select_own" on public.quest_progress;
create policy "quest_progress_select_own"
    on public.quest_progress for select
    to authenticated
    using (auth.uid() = player_id);

drop policy if exists "quest_progress_upsert_own" on public.quest_progress;
create policy "quest_progress_upsert_own"
    on public.quest_progress for insert
    to authenticated
    with check (auth.uid() = player_id);

drop policy if exists "quest_progress_update_own" on public.quest_progress;
create policy "quest_progress_update_own"
    on public.quest_progress for update
    to authenticated
    using (auth.uid() = player_id)
    with check (auth.uid() = player_id);

-- ---------------------------------------------------------------------
-- achievements
-- ---------------------------------------------------------------------
alter table public.achievements enable row level security;

drop policy if exists "achievements_select_own" on public.achievements;
create policy "achievements_select_own"
    on public.achievements for select
    to authenticated
    using (auth.uid() = player_id);

drop policy if exists "achievements_insert_own" on public.achievements;
create policy "achievements_insert_own"
    on public.achievements for insert
    to authenticated
    with check (auth.uid() = player_id);

-- ---------------------------------------------------------------------
-- guilds
-- ---------------------------------------------------------------------
alter table public.guilds enable row level security;

drop policy if exists "guilds_select_authenticated" on public.guilds;
create policy "guilds_select_authenticated"
    on public.guilds for select
    to authenticated
    using (true);

drop policy if exists "guilds_insert_authenticated" on public.guilds;
create policy "guilds_insert_authenticated"
    on public.guilds for insert
    to authenticated
    with check (auth.uid() = owner_id);

drop policy if exists "guilds_update_owner" on public.guilds;
create policy "guilds_update_owner"
    on public.guilds for update
    to authenticated
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

-- ---------------------------------------------------------------------
-- Verificação rápida: toda tabela do schema public deve ter RLS ligada.
-- Rode como admin no SQL Editor do Supabase.
-- ---------------------------------------------------------------------
-- select schemaname, tablename, rowsecurity
--   from pg_tables
--  where schemaname = 'public'
--  order by rowsecurity asc, tablename;
