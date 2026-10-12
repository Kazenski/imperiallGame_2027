# Imperiall Game

> **Transforme disciplina em progressão de personagem.**
> App de fitness gamificado no estilo RPG: cada treino concluído vira XP, cada nível desbloqueia um personagem mais forte, cada dia seguido constrói uma lenda.

<!-- Badges — serão preenchidos automaticamente após o primeiro push -->
[![CI](https://github.com/Kazenski/imperiallGame_2027/actions/workflows/ci.yml/badge.svg)](https://github.com/Kazenski/imperiallGame_2027/actions/workflows/ci.yml)
[![Release](https://github.com/Kazenski/imperiallGame_2027/actions/workflows/release.yml/badge.svg)](https://github.com/Kazenski/imperiallGame_2027/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## O que é

`Imperiall Game` é um **aplicativo nativo** (não é página de navegador) que aplica mecânicas de RPG
por cima da sua rotina real de exercícios.

Você não "marca um treino como feito". Você **derrota a sessão**, ganha XP, evolui atributos,
cumpre missões diárias e sobe no ranking da sua guilda.

| Rotina real | Vira, no jogo |
|---|---|
| Correr 5 km | +80 XP de **Vigor**, progresso em *Missão: Resistência* |
| Treino de força | +120 XP de **Força**, desbloqueia equipamento de nível |
| Alongamento | +30 XP de **Foco**, mantém a *streak* viva |
| 7 dias seguidos | Conquista **"Inabalável"** + baú de recompensa |

---

## Funcionalidades

### ✅ Já implementado (v0.1.1)

- **Núcleo de XP e níveis** — curva de progressão, cálculo de XP por tipo de atividade e detecção de level-up.
- **Personagem/avatar evolutivo** — o avatar muda de aparência conforme o nível e o equipamento desbloqueado.
- **Atributos (stats)** — Força, Vigor, Foco e Disciplina evoluem conforme o tipo de treino.
- **Missões diárias e semanais** — objetivos rotativos com recompensa de XP e loot.
- **Streak e conquistas** — sequência de dias ativos, medalhas e desbloqueios.
- **Guildas e ranking** — placar interno, ranking semanal e progresso coletivo.
- **Registro de treino** — tela de entrada de atividade com estimativa de XP em tempo real.
- **Navegação completa** — app navegável com dados mockados (modo *demo*), pronto para plugar o backend.

### 🗄️ Backend (Supabase) — provisionado

O projeto Supabase **`imperiall-game`** já está criado e com o **schema aplicado**:
6 tabelas (`profiles`, `players`, `activities`, `quest_progress`, `achievements`, `guilds`),
RLS ligada em todas e a função `award_xp` como única porta de entrada de XP.

> O app **ainda roda em modo demo**. A autenticação e o `SupabaseGameRepository`
> chegam na **v0.2.0** (veja [`docs/ROADMAP.md`](docs/ROADMAP.md)); até lá o release
> é gerado com a variável de repositório `DEMO_MODE=true`.

### 🔜 Planejado

Veja [`docs/ROADMAP.md`](docs/ROADMAP.md) para a lista completa e priorizada.

- Autenticação real com Supabase (e-mail + OAuth).
- Sincronização offline-first (fila de operações local).
- Integração com Health Connect / Apple Health (importar passos e treinos).
- Notificações push de missões e streak em risco.
- Loja de itens e economia interna (ouro, gemas, cosméticos).
- Ranking global por temporada.

---

## Stack

| Camada | Tecnologia | Motivo |
|---|---|---|
| App | **Flutter 3.47 / Dart 3.x** | Um código → Android, iOS e Windows. UI 100% customizável. |
| Estado | **Riverpod** | Testável, sem `context`, escala bem. |
| Navegação | **go_router** | Rotas declarativas e deep links. |
| Backend | **Supabase** | Postgres + Auth + Storage + RLS (seguro por padrão). |
| Local | **shared_preferences** (+ SQLite na v0.2) | Cache e modo offline. |
| CI/CD | **GitHub Actions** | Analyze, testes, build e release automatizados. |

Arquitetura detalhada em [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## Como rodar

### Pré-requisitos

- Flutter SDK **3.47+** → <https://docs.flutter.dev/get-started/install>
- Android Studio ou VS Code com a extensão Flutter
- (Opcional) Conta Supabase para o modo conectado

### Passos

```bash
git clone https://github.com/Kazenski/imperiallGame_2027.git
cd imperiallGame_2027
flutter pub get
flutter run            # escolha o dispositivo (Android / Windows / Chrome p/ debug de UI)
```

O app sobe em **modo demo** por padrão, com dados mockados — não precisa de backend nem de
nenhuma chave para ver tudo funcionando.

### Modo conectado (Supabase)

```bash
copy .env.example .env              # Windows
# preencha SUPABASE_URL e SUPABASE_ANON_KEY
flutter run --dart-define-from-file=.env
```

> O arquivo `.env` está no `.gitignore`. **Nunca** faça commit de chaves.
> A `anon key` é pública por design (protegida por RLS); a `service_role` **nunca** vai para o app.

---

## Segurança

Segurança não é etapa final, é requisito:

- **Segredos fora do código** — `.env` ignorado; produção usa *GitHub Secrets* injetados via `--dart-define`.
- **Row Level Security** obrigatório em toda tabela do Supabase (ver `supabase/policies.sql`).
- **Scan de segredos** automático no CI (`gitleaks`) a cada push e pull request.
- **Dependabot** semanal para dependências do pub e das actions, com *security updates* e alertas ativos.
- **Branch protection** na `main`: só merge com CI e scans verdes; force-push e exclusão bloqueados.
- **Permissões mínimas** nos workflows (`contents: read` por padrão).
- Roteiro completo de setup seguro: [`docs/SECURITY.md`](docs/SECURITY.md).

Para reportar uma vulnerabilidade, veja [`SECURITY.md`](SECURITY.md).

---

## Estrutura do projeto

```text
imperiallGame_2027/
├── lib/
│   ├── main.dart                 # bootstrap
│   ├── app.dart                  # MaterialApp + tema
│   ├── core/                     # tema, rotas, constantes, utils
│   ├── data/                     # modelos, repositórios, dados mockados
│   ├── services/                 # XP, missões, auth, Supabase
│   ├── features/                 # uma pasta por tela/fluxo
│   └── shared/                   # widgets reutilizáveis
├── docs/                         # design do jogo, arquitetura, ferramentas, roadmap
├── assets/                       # imagens, áudio, fontes
├── design/concept/               # layouts, paletas, mockups
├── scripts/                      # automações locais
├── .github/workflows/            # CI, release e segurança
└── CHANGELOG.md
```

---

## Deploy e CI/CD

| Workflow | Gatilho | O que faz |
|---|---|---|
| `ci.yml` | push/PR na `main` | `flutter analyze` + `flutter test` |
| `release.yml` | tag `v*` | Build do **APK assinado** + publicação no GitHub Releases |
| `security.yml` | push/PR + semanal | Scan de segredos (gitleaks) + checagem de dependências |

Criar uma release:

```bash
git tag v0.1.1 && git push origin v0.1.1
```

O APK de release é assinado com um keystore PKCS12; os 4 segredos de assinatura e as
credenciais do Supabase ficam em **GitHub Secrets**. O modo demo é controlado pela
variável de repositório `DEMO_MODE` (padrão `true`).

Configuração de secrets: [`docs/SECURITY.md`](docs/SECURITY.md) e `scripts/setup-github-secrets.ps1`.

---

## Changelog

Mantido manualmente de forma **aditiva** (nunca sobrescrito) seguindo
[Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).
Veja [`CHANGELOG.md`](CHANGELOG.md) e a política em [`docs/CHANGELOG_POLICY.md`](docs/CHANGELOG_POLICY.md).

---

## Contribuindo

Leia [`CONTRIBUTING.md`](CONTRIBUTING.md). Resumo: branch com prefixo (`feat/`, `fix/`, `chore/`),
[Conventional Commits](https://www.conventionalcommits.org/), PR com CI verde e entrada no CHANGELOG.

---

## Licença

MIT — veja [`LICENSE`](LICENSE).
