# Contribuindo

Obrigado pelo interesse! Este documento é curto e direto.

## Antes de começar

```bash
git clone https://github.com/Kazenski/imperiallGame_2027.git
cd imperiallGame_2027
flutter pub get
flutter run
```

Se você não configurou Supabase, não tem problema: o app sobe em **modo demo**.

## Fluxo de trabalho

1. **Abra uma issue** descrevendo o que você quer fazer (evita trabalho duplicado).
2. Crie uma branch a partir da `main`:

   ```bash
   git checkout -b feat/loja-de-itens
   ```

   Prefixos: `feat/` (funcionalidade), `fix/` (correção), `chore/` (manutenção),
   `docs/` (documentação), `refactor/`, `test/`.

3. Faça commits pequenos e focados, em [Conventional Commits](https://www.conventionalcommits.org/pt-br/v1.0.0/):

   ```text
   feat(quests): adicionar missão diária de passos
   fix(xp): corrigir arredondamento no cálculo de level-up
   docs(readme): documentar modo demo
   ```

4. Rode os checks locais antes de subir:

   ```bash
   dart format .
   flutter analyze
   flutter test
   ```

5. **Atualize o `CHANGELOG.md`** (aditivo, nunca sobrescreva) — ou use o script:

   ```powershell
   .\scripts\new-changelog-entry.ps1 -Category Adicionado -Message "Loja de itens"
   ```

6. Abra o Pull Request. A CI precisa ficar verde.

## Checklist do Pull Request

- [ ] Descrição clara do **porquê** (não só do "o quê")
- [ ] `flutter analyze` sem warnings novos
- [ ] `flutter test` verde, com teste novo para lógica nova
- [ ] `CHANGELOG.md` atualizado em `[Não publicado]`
- [ ] `README.md` atualizado se a feature for visível ao usuário
- [ ] Nenhum segredo, chave ou `.env` commitado
- [ ] Widgets com `Semantics`/labels quando fizer sentido (acessibilidade)

## Padrões de código

- **Dart**: siga `dart format` e `flutter_lints`. Nada de `print()` — use um logger.
- **Nomes**: classes em `PascalCase`, arquivos em `snake_case`.
- **Regra de negócio** fica em `lib/services` ou `lib/core` — **nunca** dentro de um widget.
- **Widgets** só apresentam e disparam eventos.
- **Funções puras** sempre que possível (mais fáceis de testar).
- **Comentários** explicam o *porquê*, não o *o quê*. O código já diz o "o quê".

## Estrutura de pastas

Uma feature nova = uma pasta em `lib/features/`. Detalhes em
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Regra de ouro do balanceamento

Nunca espalhe números mágicos de XP pelo código. Tudo vive em
`lib/core/constants/xp_rules.dart` e nos catálogos em `lib/data/seed/`.

## Dúvidas

Abra uma issue com a label `question`. Nenhuma pergunta é boba.
