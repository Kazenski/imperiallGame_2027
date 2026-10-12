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

[0.1.1]: https://github.com/Kazenski/imperiallGame_2027/releases/tag/v0.1.1
[0.1.0]: https://github.com/Kazenski/imperiallGame_2027/releases/tag/v0.1.0
[Não publicado]: https://github.com/Kazenski/imperiallGame_2027/compare/v0.1.1...HEAD
