# Arquitetura

## Visão geral

```text
┌─────────────────────────────────────────────────────────────┐
│                        UI (features/)                       │
│   Telas por fluxo: home, workout, character, quests, guild  │
│   Só apresentação + eventos. Sem regra de negócio.          │
└───────────────────────────┬─────────────────────────────────┘
                            │ ref.watch / ref.read
┌───────────────────────────▼─────────────────────────────────┐
│                    Providers (Riverpod)                     │
│   Estado reativo + injeção de dependência.                  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                       Regras (services/, core/)             │
│   XP, níveis, missões, streak, conquistas. Puro e testável. │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                  Repositórios (data/repositories)           │
│   Interface única → implementações: Demo / Supabase / Local │
└─────────────────────────────────────────────────────────────┘
```

**Regra de ouro:** a UI nunca fala com o Supabase direto. Ela fala com um `Repository`.
Isso permite rodar 100% offline (demo) e trocar de backend sem tocar em tela.

---

## Camadas

### `lib/core/`
- `theme/` — cores, tipografia, espaçamento. Um só lugar para a identidade visual.
- `router/` — rotas declarativas (`go_router`).
- `constants/` — regras de XP, limites, chaves.
- `utils/` — funções puras (calculadora de XP, formatadores).

### `lib/data/`
- `models/` — entidades imutáveis com `copyWith` e `fromJson`/`toJson`.
- `repositories/` — **contratos** (abstract) + implementações.
- `seed/` — catálogos e dados mockados do modo demo.

### `lib/services/`
- Orquestra várias fontes (repositório + regras) para produzir um resultado de app.
- Ex.: `WorkoutService.complete()` → calcula XP, atualiza stats, checa missões, checa conquistas, checa level-up, persiste.

### `lib/features/`
Uma pasta por fluxo. Cada feature tem suas telas e widgets locais.
`features/home/`, `features/workout/`, `features/character/`, `features/quests/`,
`features/guild/`, `features/achievements/`, `features/profile/`.

### `lib/shared/`
Widgets reutilizáveis entre features: barra de XP, chip de atributo, avatar, botões.

---

## Fluxo: concluir um treino

```text
Usuário toca "Concluir"
        │
        ▼
WorkoutService.complete(input)
        │
        ├─► XpCalculator.calculate(...)          → xp, breakdown
        ├─► PlayerRepository.addXp(...)          → novo xp, levelUp?
        ├─► AttributeRepository.applyAllocation  → stats atualizados
        ├─► QuestService.evaluateProgress(...)   → missões completadas
        ├─► AchievementService.check(...)        → conquistas desbloqueadas
        └─► StreakService.registerActivity(...)  → streak atualizada
        │
        ▼
Resultado agregado → tela de recompensa (level-up, loot, conquistas)
```

Todo o cálculo é **determinístico e puro** — mesmas entradas, mesmas saídas.
Isso torna os testes triviais.

---

## Modelo de dados (Supabase)

```text
profiles              players
 ┌─────────────┐      ┌──────────────────────┐
 │ id (uuid)   │──1:1─│ id                   │
 │ username    │      │ xp, level            │
 │ display_name│      │ strength, stamina,   │
 │ avatar_seed │      │ focus, discipline    │
 │ guild_id    │      │ streak_current       │
 │ created_at  │      │ streak_best          │
 └─────────────┘      │ last_active_at       │
                      └──────────┬───────────┘
                                 │ 1:N
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
   activities                quest_progress          achievements
   (treinos)                 (progresso diário)      (desbloqueios)
```

- **RLS em todas as tabelas.** Padrão: `auth.uid() = id`. Um usuário só lê/escreve o próprio dado.
- Escritas de XP passam por **função SQL** (`award_xp`), não por `update` direto do cliente — impede trapaça simples.
- Ranking usa **view materializada** atualizada por cron (`pg_cron`).

Detalhes das políticas em `supabase/policies.md` (a criar na v0.2).

---

## Por que Riverpod

- Sem `BuildContext` → fácil de testar.
- Dependências declaradas → trocar `DemoRepository` por `SupabaseRepository` é uma linha.
- `AsyncValue` já modela loading/erro/sucesso.

## Por que go_router

Rotas nomeadas, deep links (`imperiall://workout/new`) e `ShellRoute` para a barra inferior —
tudo declarativo, sem empilhar rotas manualmente.

---

## Testes

| Nível | O que cobre | Onde |
|---|---|---|
| Unitário | Cálculo de XP, curva de níveis, streak | `test/core/` |
| Unitário | Serviços com repositório fake | `test/services/` |
| Widget | Telas principais renderizam | `test/features/` |

Meta: **regra de negócio 100% coberta**. Widget tests cobrem os caminhos felizes.

`flutter test` roda na CI a cada push.
