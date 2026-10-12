-- =====================================================================
--  Imperiall Game — schema (aplicado ao projeto Supabase `imperiall-game`)
--
--  Idempotente: pode rodar mais de uma vez no SQL Editor sem erro.
--  Ordem de aplicação: este arquivo e, em seguida, `policies.sql`.
--
--  Princípios:
--   * RLS habilitada em TODAS as tabelas (ver policies.sql)
--   * XP nunca regride: é gravado de forma monotônica (`greatest`) pelo servidor
--   * o `level` é SEMPRE recalculado no servidor a partir do XP (nunca confiado)
--   * dados de saúde = dados sensíveis -> minimizar, criptografar em trânsito
--
--  v0.2.0: entram `ensure_player`, `sync_game_state` e `reset_progress`, que dão
--  suporte ao app autenticado (login e-mail/senha + persistência real).
-- =====================================================================

-- gen_random_uuid() vem da extensão pgcrypto
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- profiles: identidade pública, ligada ao auth.users
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
    id            uuid primary key references auth.users (id) on delete cascade,
    username      text unique not null check (char_length(username) between 3 and 24),
    display_name  text not null default 'Aventureiro',
    avatar_seed   text not null default gen_random_uuid()::text,
    guild_id      uuid,
    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- players: estado de jogo do usuário
-- ---------------------------------------------------------------------
create table if not exists public.players (
    id               uuid primary key references public.profiles (id) on delete cascade,
    xp               integer not null default 0 check (xp >= 0),
    level            integer not null default 1 check (level >= 1),
    strength         integer not null default 0 check (strength >= 0),
    stamina          integer not null default 0 check (stamina >= 0),
    focus            integer not null default 0 check (focus >= 0),
    discipline       integer not null default 0 check (discipline >= 0),
    coins            integer not null default 0 check (coins >= 0),
    gems             integer not null default 0 check (gems >= 0),
    streak_current   integer not null default 0 check (streak_current >= 0),
    streak_best      integer not null default 0 check (streak_best >= 0),
    activities_total integer not null default 0 check (activities_total >= 0),
    quests_completed_total integer not null default 0 check (quests_completed_total >= 0),
    last_active_at   date,
    equipped_gear    text[] not null default '{}',
    unlocked_gear    text[] not null default '{}',
    created_at       timestamptz not null default now(),
    updated_at       timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- activities: registro de treinos (a prova do esforço real)
-- ---------------------------------------------------------------------
create table if not exists public.activities (
    id           uuid primary key default gen_random_uuid(),
    player_id    uuid not null references public.players (id) on delete cascade,
    kind         text not null,                 -- 'strength' | 'cardio' | 'mobility' | 'steps' | ...
    amount       numeric check (amount >= 0),   -- quantidade na unidade do tipo
    intensity    text,                          -- 'light' | 'moderate' | 'intense'
    duration_min integer check (duration_min >= 0),
    xp_awarded   integer not null check (xp_awarded >= 0),
    note         text,
    performed_at timestamptz not null default now(),
    client_ref   text,                          -- id local, p/ inserção idempotente
    created_at   timestamptz not null default now()
);

create index if not exists activities_player_idx
    on public.activities (player_id, performed_at desc);

-- Idempotência: reenviar a mesma atividade (mesmo `client_ref`) não duplica.
create unique index if not exists activities_player_client_ref_key
    on public.activities (player_id, client_ref);

-- ---------------------------------------------------------------------
-- quest_progress: progresso em missões (diárias/semanais/épicas)
-- ---------------------------------------------------------------------
create table if not exists public.quest_progress (
    id          uuid primary key default gen_random_uuid(),
    player_id   uuid not null references public.players (id) on delete cascade,
    quest_key   text not null,
    progress    numeric not null default 0 check (progress >= 0),
    target      numeric not null check (target > 0),
    completed   boolean not null default false,
    period_start date not null,
    completed_at timestamptz,
    unique (player_id, quest_key, period_start)
);

-- ---------------------------------------------------------------------
-- achievements: conquistas desbloqueadas
-- ---------------------------------------------------------------------
create table if not exists public.achievements (
    id           uuid primary key default gen_random_uuid(),
    player_id    uuid not null references public.players (id) on delete cascade,
    achievement_key text not null,
    unlocked_at  timestamptz not null default now(),
    unique (player_id, achievement_key)
);

-- ---------------------------------------------------------------------
-- guilds: grupos com progresso coletivo
-- ---------------------------------------------------------------------
create table if not exists public.guilds (
    id           uuid primary key default gen_random_uuid(),
    name         text unique not null check (char_length(name) between 3 and 40),
    description  text,
    owner_id     uuid not null references public.profiles (id) on delete restrict,
    weekly_xp    integer not null default 0 check (weekly_xp >= 0),
    created_at   timestamptz not null default now()
);

alter table public.profiles
    drop constraint if exists profiles_guild_id_fkey;

alter table public.profiles
    add constraint profiles_guild_id_fkey
    foreign key (guild_id) references public.guilds (id) on delete set null;

-- ---------------------------------------------------------------------
-- award_xp: única porta de entrada para XP (anti-trapaça)
--   security definer -> roda com privilégio do dono, permitindo atualizar
--   players mesmo com RLS restringindo UPDATE direto do cliente.
-- ---------------------------------------------------------------------
create or replace function public.award_xp(
    p_amount integer,
    p_kind   text,
    p_duration_min integer default null
)
returns public.players
language plpgsql
security definer
set search_path = public
as $$
declare
    v_player public.players;
    v_level  integer := 1;
    v_acc    integer := 0;
    v_next   integer;
    c_max_level constant integer := 100;
begin
    if p_amount is null or p_amount <= 0 or p_amount > 5000 then
        raise exception 'quantidade de XP invalida: %', p_amount
            using errcode = 'check_violation';
    end if;

    update public.players
       set xp = xp + p_amount,
           updated_at = now()
     where id = auth.uid()
    returning * into v_player;

    if v_player.id is null then
        raise exception 'player nao encontrado' using errcode = 'no_data_found';
    end if;

    -- Recalcula o nivel a partir do XP acumulado.
    -- Mesma curva do app (XpRules.xpToAdvanceFrom): 100 * nivel^1.5, somada
    -- nivel a nivel. Nao usar formula fechada: ela diverge da soma discreta.
    loop
        exit when v_level >= c_max_level;
        v_next := v_acc + round(100 * power(v_level::numeric, 1.5));
        exit when v_player.xp < v_next;
        v_acc := v_next;
        v_level := v_level + 1;
    end loop;

    if v_level <> v_player.level then
        update public.players set level = v_level where id = v_player.id
        returning * into v_player;
    end if;

    insert into public.activities (player_id, kind, duration_min, xp_awarded)
    values (auth.uid(), p_kind, p_duration_min, p_amount);

    return v_player;
end;
$$;

revoke all on function public.award_xp(integer, text, integer) from public;
grant execute on function public.award_xp(integer, text, integer) to authenticated;

-- ---------------------------------------------------------------------
-- ranking semanal (view materializada — atualizar via pg_cron)
-- ---------------------------------------------------------------------
create materialized view if not exists public.guild_ranking as
select g.id,
       g.name,
       coalesce(sum(p.strength + p.stamina + p.focus + p.discipline), 0) as power,
       count(pr.id) as members
  from public.guilds g
  left join public.profiles pr on pr.guild_id = g.id
  left join public.players  p  on p.id = pr.id
 group by g.id, g.name
 order by power desc;

create unique index if not exists guild_ranking_id_idx on public.guild_ranking (id);

-- =====================================================================
--  v0.2.0 — app autenticado (login + persistência real)
-- =====================================================================
--  Migrações incrementais: garantem que um banco criado antes da v0.2.0
--  receba as colunas novas. Idempotente.
-- ---------------------------------------------------------------------
alter table public.players
    add column if not exists activities_total integer not null default 0,
    add column if not exists quests_completed_total integer not null default 0,
    add column if not exists unlocked_gear text[] not null default '{}';

alter table public.activities
    add column if not exists amount numeric,
    add column if not exists intensity text,
    add column if not exists client_ref text;

create unique index if not exists activities_player_client_ref_key
    on public.activities (player_id, client_ref);

alter table public.quest_progress
    alter column progress type numeric using progress::numeric,
    alter column target type numeric using target::numeric;

-- ---------------------------------------------------------------------
-- ensure_player: cria perfil + player no primeiro acesso (idempotente).
-- Rodar no servidor evita corrida entre duas abas e username duplicado.
-- ---------------------------------------------------------------------
create or replace function public.ensure_player(
    p_display_name text default null
)
returns public.players
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid      uuid := auth.uid();
    v_username text;
    v_player   public.players;
begin
    if v_uid is null then
        raise exception 'nao autenticado' using errcode = '28000';
    end if;

    -- Username inicial determinístico e legível: hero_<8 primeiros do uuid>.
    v_username := 'hero_' || substr(replace(v_uid::text, '-', ''), 1, 8);

    insert into public.profiles (id, username, display_name)
    values (
        v_uid,
        v_username,
        coalesce(
            nullif(trim(p_display_name), ''),
            nullif(trim(auth.jwt() -> 'user_metadata' ->> 'display_name'), ''),
            'Aventureiro'
        )
    )
    on conflict (id) do nothing;

    insert into public.players (id)
    values (v_uid)
    on conflict (id) do nothing;

    select * into v_player from public.players where id = v_uid;
    return v_player;
end;
$$;

revoke all on function public.ensure_player(text) from public;
grant execute on function public.ensure_player(text) to authenticated;

-- ---------------------------------------------------------------------
-- sync_game_state: grava o estado do jogo de forma atômica.
--
--   * xp é MONOTÔNICO (`greatest`): o cliente nunca faz o XP regredir.
--   * `level` é recalculado aqui, ignorando qualquer valor do cliente.
--   * atividades são inseridas por `client_ref` (idempotente por envio).
--   * missões fazem upsert por (player_id, quest_key, period_start).
--   * conquistas são imutáveis (on conflict do nothing).
--
-- Nota de modelagem (v0.2.0): as regras de progressão vivem no app
-- (ProgressionEngine, puro e testado). O servidor protege o invariante
-- estrutural (XP não regride, level derivado, RLS por dono). Mover as
-- regras para o servidor é meta da v0.3.0 (ver docs/ROADMAP.md).
-- ---------------------------------------------------------------------
create or replace function public.sync_game_state(p_state jsonb)
returns public.players
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid    uuid := auth.uid();
    v_player public.players;
    v_stats  jsonb := coalesce(p_state -> 'attributes', '{}'::jsonb);
    v_item   jsonb;
    v_level  integer := 1;
    v_acc    integer := 0;
    v_next   integer;
    c_max_level constant integer := 100;
begin
    if v_uid is null then
        raise exception 'nao autenticado' using errcode = '28000';
    end if;

    perform public.ensure_player(p_state ->> 'display_name');

    update public.players p
       set xp = greatest(p.xp, coalesce((p_state ->> 'total_xp')::integer, p.xp)),
           strength   = greatest(0, coalesce((v_stats ->> 'strength')::integer, p.strength)),
           stamina    = greatest(0, coalesce((v_stats ->> 'stamina')::integer, p.stamina)),
           focus      = greatest(0, coalesce((v_stats ->> 'focus')::integer, p.focus)),
           discipline = greatest(0, coalesce((v_stats ->> 'discipline')::integer, p.discipline)),
           coins   = greatest(0, coalesce((p_state ->> 'coins')::integer, p.coins)),
           gems    = greatest(0, coalesce((p_state ->> 'gems')::integer, p.gems)),
           streak_current = greatest(0, coalesce((p_state ->> 'streak_current')::integer, p.streak_current)),
           streak_best    = greatest(0, coalesce((p_state ->> 'streak_best')::integer, p.streak_best)),
           activities_total = greatest(0, coalesce((p_state ->> 'activities_total')::integer, p.activities_total)),
           quests_completed_total = greatest(0, coalesce((p_state ->> 'quests_completed_total')::integer, p.quests_completed_total)),
           equipped_gear = coalesce(
               (select array_agg(value) from jsonb_array_elements_text(
                   coalesce(p_state -> 'equipped_gear', '[]'::jsonb)) as t(value)),
               '{}'::text[]),
           unlocked_gear = coalesce(
               (select array_agg(value) from jsonb_array_elements_text(
                   coalesce(p_state -> 'unlocked_gear', '[]'::jsonb)) as t(value)),
               '{}'::text[]),
           last_active_at = coalesce(
               nullif(left(coalesce(p_state ->> 'last_active_date', ''), 10), '')::date,
               p.last_active_at),
           updated_at = now()
     where p.id = v_uid
    returning * into v_player;

    if v_player.id is null then
        raise exception 'player nao encontrado' using errcode = 'no_data_found';
    end if;

    -- Recalcula o nível a partir do XP (mesma curva do app: soma de 100*n^1.5).
    loop
        exit when v_level >= c_max_level;
        v_next := v_acc + round(100 * power(v_level::numeric, 1.5));
        exit when v_player.xp < v_next;
        v_acc := v_next;
        v_level := v_level + 1;
    end loop;

    if v_level <> v_player.level then
        update public.players set level = v_level
         where id = v_player.id
        returning * into v_player;
    end if;

    update public.profiles
       set display_name = coalesce(nullif(trim(p_state ->> 'display_name'), ''), display_name),
           updated_at = now()
     where id = v_uid;

    -- Atividades novas (idempotente por client_ref).
    for v_item in
        select * from jsonb_array_elements(coalesce(p_state -> 'activities', '[]'::jsonb))
    loop
        insert into public.activities (
            player_id, kind, amount, intensity, duration_min,
            xp_awarded, note, performed_at, client_ref)
        values (
            v_uid,
            coalesce(nullif(v_item ->> 'kind', ''), 'strength'),
            nullif(v_item ->> 'amount', '')::numeric,
            nullif(v_item ->> 'intensity', ''),
            null,
            greatest(0, least(5000, coalesce((v_item ->> 'xp_awarded')::integer, 0))),
            nullif(v_item ->> 'note', ''),
            coalesce((v_item ->> 'performed_at')::timestamptz, now()),
            nullif(v_item ->> 'id', ''))
        on conflict (player_id, client_ref) do nothing;
    end loop;

    -- Missões (upsert por período).
    for v_item in
        select * from jsonb_array_elements(coalesce(p_state -> 'quests', '[]'::jsonb))
    loop
        insert into public.quest_progress (
            player_id, quest_key, progress, target, completed, period_start)
        values (
            v_uid,
            v_item ->> 'quest_key',
            greatest(0, coalesce((v_item ->> 'progress')::numeric, 0)),
            greatest(1, coalesce((v_item ->> 'target')::numeric, 1)),
            coalesce((v_item ->> 'completed')::boolean, false),
            coalesce(nullif(left(coalesce(v_item ->> 'period_start', ''), 10), '')::date,
                     current_date))
        on conflict (player_id, quest_key, period_start) do update
           set progress = excluded.progress,
               target = excluded.target,
               completed = excluded.completed,
               completed_at = case
                   when excluded.completed
                        and public.quest_progress.completed_at is null then now()
                   else public.quest_progress.completed_at
               end;
    end loop;

    -- Conquistas (imutáveis).
    for v_item in
        select * from jsonb_array_elements(coalesce(p_state -> 'achievements', '[]'::jsonb))
    loop
        insert into public.achievements (player_id, achievement_key)
        values (v_uid, v_item #>> '{}')
        on conflict (player_id, achievement_key) do nothing;
    end loop;

    return v_player;
end;
$$;

revoke all on function public.sync_game_state(jsonb) from public;
grant execute on function public.sync_game_state(jsonb) to authenticated;

-- ---------------------------------------------------------------------
-- reset_progress: zera o progresso do usuário autenticado.
-- ---------------------------------------------------------------------
create or replace function public.reset_progress()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid uuid := auth.uid();
begin
    if v_uid is null then
        raise exception 'nao autenticado' using errcode = '28000';
    end if;

    delete from public.activities      where player_id = v_uid;
    delete from public.quest_progress  where player_id = v_uid;
    delete from public.achievements    where player_id = v_uid;

    update public.players
       set xp = 0, level = 1,
           strength = 0, stamina = 0, focus = 0, discipline = 0,
           coins = 0, gems = 0,
           streak_current = 0, streak_best = 0,
           activities_total = 0, quests_completed_total = 0,
           equipped_gear = '{}', unlocked_gear = '{}',
           last_active_at = null, updated_at = now()
     where id = v_uid;
end;
$$;

revoke all on function public.reset_progress() from public;
grant execute on function public.reset_progress() to authenticated;

-- ---------------------------------------------------------------------
-- guild_members: ranking interno de uma guilda (XP dos últimos 7 dias).
--   Função (não view) para poder agregar `activities` de OUTROS membros,
--   o que a RLS de `activities` barraria numa view comum.
-- ---------------------------------------------------------------------
create or replace function public.guild_members(p_guild_id uuid)
returns table (
    player_id    uuid,
    display_name text,
    level        integer,
    weekly_xp    integer,
    is_me        boolean
)
language sql
security definer
set search_path = public
stable
as $$
    select pr.id,
           pr.display_name,
           coalesce(pl.level, 1),
           coalesce((
               select sum(a.xp_awarded)
                 from public.activities a
                where a.player_id = pr.id
                  and a.performed_at >= now() - interval '7 days'
           ), 0)::integer,
           pr.id = auth.uid()
      from public.profiles pr
      left join public.players pl on pl.id = pr.id
     where pr.guild_id = p_guild_id
     order by 4 desc;
$$;

revoke all on function public.guild_members(uuid) from public;
grant execute on function public.guild_members(uuid) to authenticated;
