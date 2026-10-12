# Segurança — guia de configuração

Este documento é o **passo a passo** para deixar o projeto seguro do zero.
Ele cobre segredos locais, secrets do GitHub, assinatura de release e o backend Supabase.

---

## 1. Princípios

1. **Nenhum segredo no código.** Nunca. Nem "temporário", nem em comentário.
2. **Menor privilégio.** Tokens, permissões de workflow e roles do banco com o mínimo necessário.
3. **Rotacionar é barato.** Trate toda chave como descartável: se vazou, troca.
4. **Automático > disciplina.** Scan de segredos, Dependabot e RLS fazem o trabalho por nós.
5. **Segurança de dados de saúde é LGPD.** Dados de treino são dados sensíveis — criptografia em trânsito, RLS, e direito de exclusão.

---

## 2. Segredos locais

O arquivo `.env` está no `.gitignore` e nunca é versionado.

```powershell
Copy-Item .env.example .env
# edite .env com seus valores
flutter run --dart-define-from-file=.env
```

Verifique que está ignorado:

```bash
git check-ignore -v .env    # deve imprimir a linha do .gitignore
```

### Tipos de chave Supabase

| Chave | Onde usar | Segurança |
|---|---|---|
| `anon` | no app (Android/iOS) | **Pública por design.** Protegida por RLS. |
| `service_role` | **só** em backend/Edge Function | **Nunca** no app. Ignora RLS. |

Se você ver `service_role` dentro de `lib/`, é uma falha crítica. Remova e rotacione imediatamente.

---

## 3. GitHub Secrets

Configure uma vez com o script (ele lê do seu `.env` e **não** imprime valores):

```powershell
.\scripts\setup-github-secrets.ps1 -EnvFile .env
```

Ou manualmente:

```bash
gh secret set SUPABASE_URL --body "https://xxxx.supabase.co"
gh secret set SUPABASE_ANON_KEY --body "eyJ..."
```

### Lista de secrets

| Nome | Usado por | Obrigatório |
|---|---|---|
| `SUPABASE_URL` | release | só no modo conectado |
| `SUPABASE_ANON_KEY` | release | só no modo conectado |
| `ANDROID_KEYSTORE_BASE64` | release | para APK assinado |
| `ANDROID_KEYSTORE_PASSWORD` | release | para APK assinado |
| `ANDROID_KEY_ALIAS` | release | para APK assinado |
| `ANDROID_KEY_PASSWORD` | release | para APK assinado |

Se um secret não existir, o build de release **cai para APK debug** em vez de falhar — assim
você não trava o pipeline enquanto o backend não está pronto.

### Variável de repositório

| Nome | Valores | Padrão | Para quê |
|---|---|---|---|
| `DEMO_MODE` | `true` / `false` | `true` | se `true`, o APK abre com dados mockados (não usa o Supabase) |

```bash
gh variable set DEMO_MODE --body "true"
```

> Enquanto a v0.2.0 não implementar a autenticação e o `SupabaseGameRepository`,
> mantenha `DEMO_MODE=true` — senão o app abriria sem backend funcional.

---

## 4. Assinatura do Android (keystore)

Sem assinatura própria, a Play Store recusa a atualização. Gere uma vez:

```powershell
keytool -genkeypair -v -keystore android/app/upload-keystore.jks `
  -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload -storepass "<senha>" -keypass "<senha>" `
  -dname "CN=Imperiall Game, O=Imperiall, C=BR"
```

Converta para base64 e guarde no GitHub:

```powershell
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks"))
gh secret set ANDROID_KEYSTORE_BASE64 --body $b64
gh secret set ANDROID_KEY_ALIAS --body "upload"
gh secret set ANDROID_KEYSTORE_PASSWORD --body "<senha>"
gh secret set ANDROID_KEY_PASSWORD --body "<senha>"
```

> **Guarde o `.jks` e as senhas em um gerenciador de senhas.** Se perder o keystore,
> você perde a capacidade de atualizar o app na Play Store para sempre.

O `.jks`, `key.properties` e `local.properties` já estão no `.gitignore`.

---

## 5. Supabase — RLS obrigatório

**Toda** tabela com dado de usuário precisa de Row Level Security ligada:

```sql
alter table players enable row level security;

create policy "usuario le o proprio player"
  on players for select
  using (auth.uid() = id);

create policy "usuario atualiza o proprio player"
  on players for update
  using (auth.uid() = id)
  with check (auth.uid() = id);
```

### Anti-trapaça e modelo de confiança

O cliente **não** recebe policy de `UPDATE` em `players`. Toda gravação de progresso
passa pela RPC `sync_game_state` (`security definer`), que:

- recalcula o **nível** a partir do XP — o cliente não escolhe o nível;
- grava o XP de forma **monotônica** (`greatest(current, incoming)`) — nunca regride;
- insere atividades de forma **idempotente** por `client_ref`;
- valida faixas (`check`/`least`) antes de gravar.

**Invariantes garantidos no servidor:**

| Garantia | Onde |
|---|---|
| Um usuário só lê/escreve o próprio progresso | RLS (`auth.uid() = player_id`) |
| Dados públicos (perfil/ranking) são somente leitura | policy `select` + ausência de `update` |
| XP não regride e o nível é derivado | RPC `sync_game_state` |
| Atividade duplicada não conta duas vezes | índice único `(player_id, client_ref)` |

**Limite conhecido (v0.2.0):** as regras de *quanto* XP cada treino vale rodam no app
(`ProgressionEngine`). Um cliente modificado poderia informar um valor maior — o servidor
limita o teto por atividade, mas não conhece a regra completa. Mover as regras para o
servidor (SQL) é meta da **v0.3.0** e está registrado no `docs/ROADMAP.md`.

```sql
-- Porta de referência (server-side), mantida para uso futuro:
create or replace function award_xp(p_amount int, p_kind text, p_duration_min int default null)
returns players language plpgsql security definer set search_path = public as $$
declare v_player players;
begin
  if p_amount <= 0 or p_amount > 5000 then
    raise exception 'quantidade invalida';
  end if;

  update players
     set xp = xp + p_amount, updated_at = now()
   where id = auth.uid()
  returning * into v_player;

  insert into activities (player_id, kind, xp_awarded, duration_min)
  values (auth.uid(), p_kind, p_amount, p_duration_min);

  return v_player;
end;
$$;
```

### Checklist de segurança do Supabase

- [ ] RLS habilitada em **todas** as tabelas
- [ ] Cada tabela tem policy explícita (nada de "RLS ligada sem policy" = bloqueia tudo, ou pior, policy aberta)
- [ ] `service_role` só em Edge Function / backend
- [ ] Auth com confirmação de e-mail e rate limit ativos
- [ ] Storage com policy por usuário (`auth.uid() = owner`)
- [ ] Backups diários habilitados
- [ ] `security definer` sempre com `set search_path = public`

---

## 6. Automações de segurança

| Mecanismo | Arquivo | O que faz |
|---|---|---|
| Scan de segredos | `.github/workflows/security.yml` | gitleaks em cada push/PR |
| Dependabot | `.github/dependabot.yml` | PR semanal para `pub` e `github-actions` |
| Permissões mínimas | workflows | `contents: read` por padrão |
| Verificador de CHANGELOG | `ci.yml` | falha se histórico for apagado |

### Ativar proteção de branch (recomendado)

```bash
gh api -X PUT "repos/Kazenski/imperiallGame_2027/branches/main/protection" \
  -H "Accept: application/vnd.github+json" \
  -f "required_status_checks[strict]=true" \
  -f "required_status_checks[contexts][]=analyze-and-test" \
  -f "enforce_admins=false" \
  -F "required_pull_request_reviews[required_approving_review_count]=0" \
  -F "restrictions="
```

---

## 7. O que fazer se um segredo vazar

1. **Rotacione imediatamente** — gere a chave nova no provedor.
2. Revogue a antiga.
3. Se foi commitado: remova do histórico (`git filter-repo`) **e** force push — mas assuma que já vazou.
4. Se for a `service_role` do Supabase: rotacione, revise os logs de acesso e verifique se houve escrita indevida.
5. Registre no CHANGELOG, categoria `Segurança`.

> Rotacionar é mais rápido que limpar histórico. Sempre rotacione primeiro.

---

## 8. Resposta a incidentes

Ver [`../SECURITY.md`](../SECURITY.md) para o canal de reporte de vulnerabilidades.
