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

[0.1.0]: https://github.com/Kazenski/imperiallGame_2027/releases/tag/v0.1.0
[Não publicado]: https://github.com/Kazenski/imperiallGame_2027/compare/v0.1.0...HEAD
