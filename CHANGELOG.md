# Changelog

Todas as mudanças relevantes deste projeto são documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e o projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

> **Regra de ouro:** este arquivo é **aditivo**. Nunca reescreva ou remova entradas
> já publicadas — apenas adicione novas linhas na seção apropriada.
> Detalhes em [`docs/CHANGELOG_POLICY.md`](docs/CHANGELOG_POLICY.md).

Categorias: `Adicionado`, `Alterado`, `Descontinuado`, `Removido`, `Corrigido`, `Segurança`.

## [Não publicado]

### Adicionado

- **Interface navegável completa**: telas de início, treino, herói, missões, guilda, conquistas e perfil.
- **Registro de treino com prévia de XP em tempo real** e tela de recompensa (level-up, missões, conquistas e loot).
- **Testes automatizados**: unidade para XP/regras/motor de progressão e teste de fumaça da navegação.
- **Plataforma web** adicionada para validar o build e permitir pré-visualização.
- Estrutura inicial do repositório: README, CHANGELOG, LICENSE (MIT), CONTRIBUTING e SECURITY.
- Documentação de design do jogo (`docs/GAME_DESIGN.md`), arquitetura (`docs/ARCHITECTURE.md`),
  ferramentas de produção de assets (`docs/TOOLS.md`) e roadmap (`docs/ROADMAP.md`).
- Pipeline de CI (`ci.yml`) com `flutter analyze` e `flutter test`.
- Pipeline de release (`release.yml`) que gera APK assinado e publica no GitHub Releases em tags `v*`.
- Workflow de segurança (`security.yml`) com varredura de segredos via gitleaks.
- Configuração do Dependabot para `pub` e `github-actions`.

### Alterado

- **Actions do CI atualizadas** para as versões atuais (`checkout@v7`, `setup-java@v6`,
  `upload-artifact@v7`, `action-gh-release@v3`), removendo os avisos de Node 20 depreciado.
- **`docs/SECURITY.md`** alinhado ao setup real: comando do keystore com PKCS12, os 4
  segredos de assinatura e a variável de repositório `DEMO_MODE`.

## [0.2.0] - 2026-10-12

O app passa a ter **backend real**: login por e-mail/senha, progresso persistido
no Supabase e proteção de rota. O modo demo continua disponível (sem credenciais)
e é o padrão do release enquanto não houver um projeto Supabase configurado.

### Adicionado

- **Autenticação (Supabase Auth)**: tela de login/cadastro por e-mail e senha,
  sessão persistente, mensagens de erro em português e proteção de rota — quem
  não está autenticado só vê a tela de entrada.
- **`SupabaseGameRepository` implementado**: `load()` lê perfil, jogador,
  atividades, missões, conquistas e guilda; `save()` grava tudo; `reset()` zera
  o progresso. Substitui o stub que lançava `UnimplementedError`.
- **RPC `sync_game_state`**: gravação atômica e idempotente do estado, com
  **XP monotônico** (nunca regride) e **nível recalculado no servidor**.
- **RPC `ensure_player`**: cria perfil + jogador no primeiro acesso, sem corrida
  entre abas nem username duplicado.
- **RPC `reset_progress`**: zera atividades, missões e conquistas do usuário.
- **Função `guild_members`**: ranking interno da guilda (XP dos últimos 7 dias),
  via `security definer` para agregar atividades de outros membros.
- **Seção "Conta" no perfil**: mostra o e-mail e permite sair da conta.
- **Serialização testável** (`buildSyncPayload`): função pura que monta o pacote
  enviado ao servidor, com **6 testes** novos.
- **`supabase/README.md`**: passo a passo para aplicar schema e policies.

### Alterado

- **`main.dart`** inicializa o Supabase apenas quando há credenciais; sem elas, o
  app abre em modo demonstração.
- **`gameRepositoryProvider` e `GameController`** observam o usuário atual e
  recarregam o estado ao entrar/sair/trocar de conta.
- **`anonKey` → `publishableKey`** na inicialização (API atual do `supabase_flutter`).
- **`quest_progress.progress` e `target`** passam de `integer` para `numeric`,
  preservando progresso fracionado (ex.: 6,4 km).
- **`activities`** ganha `amount`, `intensity` e `client_ref` (inserção idempotente).
- **`players`** ganha `activities_total`, `quests_completed_total` e `unlocked_gear`.
- Versão do app: **0.2.0+3**.

### Segurança

- **Schema e policies validados em um Postgres real** (PGlite/WASM): idempotência,
  RPCs, XP monotônico, RLS bloqueando acesso entre usuários e reset.
- **Modelo de confiança documentado** em `docs/SECURITY.md`: o servidor protege os
  invariantes estruturais (XP não regride, nível derivado, RLS por dono); a
  progressão detalhada roda no app e migrará para o servidor na v0.3.0.

## [0.1.1] - 2026-10-12

Infraestrutura de backend e publicação. O app continua em **modo demo**, mas o
projeto Supabase real já está provisionado e o APK passa a ser **assinado de verdade**.

### Adicionado

- **Schema do Supabase aplicado** ao projeto `imperiall-game`: tabelas `profiles`,
  `players`, `activities`, `quest_progress`, `achievements` e `guilds`.
- **Row Level Security** ligada em todas as tabelas, com 15 policies explícitas
  (`supabase/policies.sql` agora é idempotente e pode rodar mais de uma vez).
- **Função `award_xp`** como única porta de entrada de XP (server-side, `security definer`).
- **View materializada `guild_ranking`** para o ranking semanal.
- **Assinatura de release**: keystore PKCS12 (RSA 2048) + `android/key.properties`,
  com os 4 segredos de assinatura configurados no repositório.
- **Variável de repositório `DEMO_MODE`** para alternar o modo demo no build sem
  depender da presença de credenciais.

### Alterado

- **Curva de nível no banco** agora replica exatamente a do app (`100 · nível^1.5`
  somada nível a nível), em vez de uma fórmula fechada que divergia da real.
- **`release.yml`**: o modo demo passa a ser controlado por `vars.DEMO_MODE`
  (padrão `true`), evitando gerar um APK que abriria sem backend implementado.

### Segurança

- **`scripts/setup-github-secrets.ps1`** passa a usar `gh secret set --body`,
  evitando o `\n` que o pipe do PowerShell acrescenta (corrompia senhas).
- **Branch protection** na `main`: exige CI, changelog guard e scans de segurança,
  com force-push e exclusão bloqueados.
- **Alertas de vulnerabilidade** e **Dependabot security updates** habilitados.

## [0.1.0] - 2026-10-12

Primeira versão navegável do esqueleto (modo demo, dados mockados).

### Adicionado

- **Núcleo de XP e níveis**: curva de progressão, XP por tipo de atividade e detecção de level-up.
- **Atributos do personagem**: Força, Vigor, Foco e Disciplina.
- **Personagem/avatar evolutivo**: aparência atrelada ao nível e ao equipamento desbloqueado.
- **Missões diárias e semanais**: objetivos rotativos com recompensa.
- **Streak diária e conquistas**: sequência de dias ativos e medalhas.
- **Guildas e ranking**: placar interno e ranking semanal.
- **Registro de treino**: entrada de atividade com estimativa de XP em tempo real.
- **Navegação completa** entre as telas principais.

[0.2.0]: https://github.com/Kazenski/imperiallGame_2027/releases/tag/v0.2.0
[0.1.1]: https://github.com/Kazenski/imperiallGame_2027/releases/tag/v0.1.1
[0.1.0]: https://github.com/Kazenski/imperiallGame_2027/releases/tag/v0.1.0
[Não publicado]: https://github.com/Kazenski/imperiallGame_2027/compare/v0.2.0...HEAD
