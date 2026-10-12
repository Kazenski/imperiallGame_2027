# Política do CHANGELOG

## Regra central

> **O CHANGELOG é aditivo. Nunca sobrescreva, nunca reescreva o histórico, nunca reordene.**

Codificar o passado diferente do que aconteceu quebra a confiança em releases.
Se uma entrada estava errada, **não a edite** — adicione uma entrada nova corrigindo.

## Formato

Seguimos [Keep a Changelog 1.1.0](https://keepachangelog.com/pt-BR/1.1.0/) + [SemVer](https://semver.org/lang/pt-BR/).

```markdown
## [Não publicado]

### Adicionado
- descrição da feature nova

### Corrigido
- descrição do bug corrigido

## [1.2.0] - 2026-11-01

### Adicionado
- ...
```

### Categorias permitidas

| Categoria | Quando usar |
|---|---|
| `Adicionado` | funcionalidade nova |
| `Alterado` | mudança em algo existente |
| `Descontinuado` | ainda funciona, mas será removido |
| `Removido` | removido agora |
| `Corrigido` | correção de bug |
| `Segurança` | vulnerabilidade corrigida ou melhoria de segurança |

## Fluxo de trabalho

1. Crie/abra a seção `## [Não publicado]` no topo (logo após o cabeçalho do arquivo).
2. Adicione a linha na **categoria** correta, dentro de `Adicionado`/`Corrigido`/etc.
   Se a categoria não existir sob `[Não publicado]`, crie o subtítulo `### Categoria`.
3. **Nunca** remova linhas antigas nem crie uma segunda seção `[Não publicado]`.
4. No release: renomeie `[Não publicado]` → `[x.y.z] - AAAA-MM-DD` e crie uma nova
   seção `[Não publicado]` vazia no topo. Só isso muda no histórico.

## Automação

Para evitar erro humano, use o script:

```powershell
# Adiciona automaticamente em "Não publicado" > categoria
.\scripts\new-changelog-entry.ps1 -Category Adicionado -Message "Loja de itens com escudo de streak"

# Cria a versão a partir do que está em "Não publicado"
.\scripts\new-changelog-entry.ps1 -Release 0.2.0
```

O script **só insere/renomeia** — jamais apaga conteúdo existente.

## Checklist de PR

- [ ] Toda mudança visível ao usuário tem uma linha no CHANGELOG
- [ ] A linha está em `[Não publicado]`, não em uma versão já publicada
- [ ] Nada foi removido do histórico
- [ ] Categoria correta (especialmente `Segurança` para correções de falha)

## Revisão automática

A CI roda um verificador que falha o PR se o CHANGELOG perder linhas de versões
já publicadas. Assim a regra "sem sobrescrever" é garantida por máquina, não por disciplina.
