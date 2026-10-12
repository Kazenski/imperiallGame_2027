-- =====================================================================
--  Imperiall Game — schema de referência (planejado para a v0.2.0)
--  Nada aqui é executado automaticamente. Rode manualmente no Supabase
--  ou via `supabase db push` quando a v0.2 começarem.
--
--  Princípios:
--   * RLS habilitada em TODAS as tabelas (ver policies.sql)
--   * XP só é alterado pela função award_xp (server-side)
--   * dados de saúde = dados sensíveis -> minimizar, criptografar em trânsito
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
    last_active_at   date,
    equipped_gear    text[] not null default '{}',
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
    duration_min integer check (duration_min >= 0),
    xp_awarded   integer not null check (xp_awarded >= 0),
    note         text,
    performed_at timestamptz not null default now(),
    created_at   timestamptz not null default now()
);

create index if not exists activities_player_idx
    on public.activities (player_id, performed_at desc);

-- ---------------------------------------------------------------------
-- quest_progress: progresso em missões (diárias/semanais/épicas)
-- ---------------------------------------------------------------------
create table if not exists public.quest_progress (
    id          uuid primary key default gen_random_uuid(),
    player_id   uuid not null references public.players (id) on delete cascade,
    quest_key   text not null,
    progress    integer not null default 0 check (progress >= 0),
    target      integer not null check (target > 0),
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
    v_level  integer;
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

    -- recalcula o nivel a partir do XP acumulado (mesma formula do app)
    v_level := greatest(1, floor(power(v_player.xp / 100.0, 1.0 / 1.5))::int);
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
