# Roadmap

Priorizado por **impacto no hábito do usuário**, não por facilidade técnica.

Estados: ✅ pronto · 🚧 em andamento · 📋 planejado · 💤 ideia futura

---

## v0.1.0 — Esqueleto navegável ✅

- ✅ Repositório, README, CHANGELOG, LICENSE, CONTRIBUTING, SECURITY
- ✅ CI (analyze + test), release (APK), scan de segredos
- ✅ Núcleo de XP, níveis, atributos
- ✅ Avatar evolutivo, missões, streak, conquistas
- ✅ Guildas e ranking (dados mockados)
- ✅ Registro de treino com estimativa de XP
- ✅ Navegação completa em modo demo

## v0.1.1 — Assinatura e backend provisionado ✅

- ✅ Schema do Supabase aplicado + RLS em todas as tabelas
- ✅ Keystore PKCS12 e APK de release assinado
- ✅ Branch protection, Dependabot e alertas de vulnerabilidade

## v0.2.0 — Backend real 🚧

- ✅ Autenticação Supabase (e-mail/senha) com proteção de rota e sessão persistente
- ✅ Schema do banco + **RLS em todas as tabelas**
- ✅ RPC `sync_game_state` (gravação atômica, XP monotônico, nível derivado no servidor)
- ✅ `SupabaseGameRepository` real (load/save/reset)
- ✅ Ranking interno da guilda (`guild_members`)
- 📋 OAuth Google (além de e-mail/senha)
- 📋 Sincronização offline-first (fila local + resolução de conflito)
- 📋 Edição de perfil (nome, avatar) e Storage de avatar customizado
- 📋 Mover as regras de progressão para o servidor (anti-trapaça completo)

## v0.3.0 — Engajamento 📋

- 📋 Notificações push (missão não concluída, streak em risco)
- 📋 Health Connect / Apple Health (importar passos e treinos)
- 📋 Escudo de streak e loja de itens
- 📋 Compartilhar conquista como imagem
- 📋 Sons e animações de level-up (Rive)

## v0.4.0 — Social 📋

- 📋 Criar/entrar em guilda
- 📋 Ranking de guilda em tempo real
- 📋 Temporadas (10 semanas) com reset de ranking
- 📋 Chat de guilda (moderação desde o dia 1)

## v1.0.0 — Lançamento 💤

- 💤 Publicação na Google Play e App Store
- 💤 Onboarding polido + tutorial
- 💤 Localização (pt-BR, en, es)
- 💤 Acessibilidade completa (contraste, escala de fonte, leitor de tela)
- 💤 Política de privacidade e conformidade LGPD
- 💤 Analytics respeitando privacidade (sem dados sensíveis de saúde)

---

## Ideias futuras 💤

- Integração com relógios (Wear OS / watchOS)
- AR: personagem "treinando junto" via câmera
- Modo cooperativo (meta coletiva de km da guilda)
- Marketplace de cosméticos entre usuários
- API pública para integrações (Strava, Garmin, Nike Run Club)

---

## Critérios de conclusão de uma versão

Uma versão só é *release* quando:

1. `flutter analyze` sem erros e `flutter test` verde.
2. Cobertura de regras de negócio ≥ 80%.
3. CHANGELOG atualizado (aditivo).
4. README refletindo as features novas.
5. Nenhum segredo commitado (gitleaks limpo).
6. Testado em Android físico, não só emulador.
