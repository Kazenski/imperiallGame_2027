# Política de Segurança

## Versões suportadas

Apenas a versão mais recente publicada e a branch `main` recebem correções de segurança.

| Versão | Suportada |
|---|---|
| 0.1.x  | ✅ |
| < 0.1  | ❌ |

## Reportando uma vulnerabilidade

**Não abra uma issue pública.** Vulnerabilidades divulgadas antes da correção expõem usuários.

Use uma das opções privadas:

1. **GitHub Security Advisories** (preferido) —
   [Report a vulnerability](https://github.com/Kazenski/imperiallGame_2027/security/advisories/new)
2. **E-mail** — entre em contato pelo e-mail associado ao perfil [@Kazenski](https://github.com/Kazenski).

### Inclua no reporte

- Descrição do problema e impacto potencial
- Passos para reproduzir (ou prova de conceito)
- Versão do app e plataforma
- Se possível, sugestão de correção

### O que esperar

| Etapa | Prazo alvo |
|---|---|
| Confirmação de recebimento | 48 h |
| Avaliação inicial e severidade | 5 dias |
| Correção ou plano | 30 dias (crítica: mais rápido) |
| Crédito público | após a correção, se você quiser |

Pedimos que você **não** divulgue publicamente até a correção estar disponível.
Damos crédito pelo achado — com seu consentimento — no CHANGELOG, categoria `Segurança`.

## Escopo

**Dentro do escopo:** o app Flutter, os workflows de CI/CD, a configuração do Supabase
(políticas RLS, funções) e qualquer lógica de XP/ranking.

**Fora do escopo:** engenharia social, negação de serviço volumétrica, ataques físicos
e relatórios gerados automaticamente sem prova de exploração.

## Boas práticas que seguimos

- Nenhum segredo versionado (scan automático com gitleaks)
- RLS obrigatória no banco
- XP concedido apenas por função server-side
- Dependências atualizadas semanalmente (Dependabot)
- Permissões mínimas nos workflows do GitHub Actions
