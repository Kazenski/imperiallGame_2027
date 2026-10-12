# Design do Jogo

Documento de referência do sistema de progressão do **Imperiall Game**.
Complementa [`ARCHITECTURE.md`](ARCHITECTURE.md) (como o código é organizado) com o **porquê** de cada mecânica.

---

## 1. Pilar de design

> **A vida real é o grind. O app é a recompensa.**

Três regras que guiam toda decisão:

1. **A ação real vale mais que o toque na tela.** O jogador prova que treinou (foto, duração, distância, wearables) — não basta um checkbox.
2. **Sempre há algo a fazer hoje.** Missão diária + streak + ranking semanal garantem retorno diário.
3. **Progresso nunca regride.** XP só sobe. A *streak* pode quebrar, mas o personagem nunca "perde nível" — punir destrói hábito.

---

## 2. Loop principal

```text
   ┌──────────────────────────────────────────────────────────┐
   │                                                          │
   ▼                                                          │
 Registrar atividade  ──►  Ganhar XP + atributos  ──►  Subir de nível
   ▲                                                          │
   │                                                          ▼
   │                                            Desbloquear equipamento
   │                                                          │
   │                                                          ▼
   └──  Missão diária concluída ◄──  Novos desafios ◄──  Avatar evolui
                    │
                    ▼
             Streak + Ranking sobem
```

---

## 3. Tipos de atividade e recompensa

Cada atividade alimenta um **atributo** primário. O XP base é multiplicado por um fator de intensidade.

| Atividade | Atributo | XP base | Fator de intensidade |
|---|---|---|---|
| Corrida / caminhada | Vigor | 8 XP / km | ritmo, elevação |
| Musculação | Força | 15 XP / série | carga, volume |
| HIIT / circuito | Vigor | 100 XP / sessão | frequência cardíaca |
| Yoga / mobilidade | Foco | 30 XP / sessão | duração |
| Alongamento / recuperação | Foco | 20 XP / sessão | duração |
| Meta diária de passos | Disciplina | 5 XP / 1000 passos | constância |
| Registro de refeição | Disciplina | 10 XP | sequência |

> Os números vivem em `lib/core/constants/xp_rules.dart` — **fonte única da verdade**.
> Ajustar balanceamento é editar esse arquivo, nunca espalhar constantes pelo código.

### Fórmula de XP

```text
XP_final = XP_base × fator_intensidade × multiplicador_streak × multiplicador_guilda

multiplicador_streak  = 1.0 + min(streak_dias, 30) × 0.01   → até +30%
multiplicador_guilda  = 1.0 + min(bônus_guilda, 0.15)        → até +15%
```

Streak recompensa **consistência**, guilda recompensa **pertencimento**.

---

## 4. Curva de níveis

Progressão geométrica suave — os primeiros níveis vêm rápido (dopamina inicial), depois o custo cresce (longevidade).

```text
XP_para_nivel(n) = 100 × n^1.5        (arredondado)
```

| Nível | XP acumulado | Título | Marco |
|---|---|---|---|
| 1 | 0 | Novato | — |
| 5 | ~1.100 | Aprendiz | Desbloqueia missões semanais |
| 10 | ~3.200 | Combatente | Primeiro equipamento raro |
| 20 | ~8.900 | Veterano | Entra em guildas |
| 35 | ~20.700 | Campeão | Cosméticos exclusivos |
| 50 | ~35.400 | Lenda | Ranking global |

Títulos vivem em `lib/data/models/level_title.dart`.

---

## 5. Atributos

Quatro eixos, cada um com efeito visível no avatar e em missões:

- **Força** — treinos de resistência. Avatar ganha porte físico.
- **Vigor** — cardio. Avatar ganha aura/energia.
- **Foco** — mobilidade e recuperação. Avatar ganha postura e serenidade.
- **Disciplina** — constância (passos, refeições). Avatar ganha ícones de reputação.

Atributos são **soma acumulada** de XP por categoria, não gastáveis. Servem para progressão visual e para desbloquear missões específicas.

---

## 6. Missões

| Tipo | Renova | Quantidade | Recompensa |
|---|---|---|---|
| Diária | meia-noite local | 3 | XP + moedas |
| Semanal | segunda-feira | 5 | XP em dobro + item |
| Épica | manual | 1 | avatar + título |

Exemplos de missão diária:
- *"Deixe a preguiça no chão"* — registre 1 treino de Força.
- *"Respire fundo"* — acumule 20 min de Foco.
- *"Passos de gigante"* — 8.000 passos.

Regra anti-frustração: **missão não expira sem aviso** — a última hora do dia dispara uma notificação ("você está a 1 treino de completar o dia").

---

## 7. Streak

- Cada dia com **≥ 1 atividade válida** incrementa a streak.
- Cada **7 dias** → baú de recompensa (item aleatório + bônus de XP).
- Cada **30 dias** → cosmético exclusivo.
- **Escudo de streak** (item): protege 1 dia perdido. Vendido na loja ou ganho em baú. Isso suaviza a quebra e reduz churn.

---

## 8. Guildas e ranking

- Guilda = grupo de até 30 membros com **XP coletivo semanal**.
- Ranking interno: todos os membros veem a posição uns dos outros (motivação social).
- Ranking global: por guilda e por temporada (10 semanas).
- Bônus de guilda: guilda ativa concede até +15% de XP a todos.

Privacidade: o nome exibido é escolhido pelo usuário; a exportação de dados é sempre possível (LGPD).

---

## 9. Economia (planejada)

| Moeda | Origem | Uso |
|---|---|---|
| **Ouro** | missões, baús | cosméticos comuns, escudo de streak |
| **Gemas** | conquistas raras, temporada | itens premium cosméticos (nunca vantagem no ranking) |

**Princípio ético:** nada de pay-to-win. Dinheiro compra **estética**, nunca XP ou ranking.

---

## 10. Estado do personagem (avatar)

O avatar é **composto**, não um arquivo único — assim escala sem explodir o número de imagens:

```text
┌─ camada 1: corpo      (nível 1-5 / 6-15 / 16-35 / 36+)
├─ camada 2: equipamento (desbloqueado por atributo ou conquista)
├─ camada 3: aura        (efeito do atributo dominante)
└─ camada 4: moldura     (conquistas / temporada)
```

Renderizado em Flutter com `Stack` + `Image`. Um sistema de 4 corpos × 12 equipamentos × 5 auras
gera **centenas de combinações** com ~21 imagens. Ver produção em [`TOOLS.md`](TOOLS.md).

---

## 11. Balanceamento — onde mexer

| Quero mudar | Arquivo |
|---|---|
| XP por atividade | `lib/core/constants/xp_rules.dart` |
| Curva de níveis | `lib/core/utils/xp_calculator.dart` |
| Títulos | `lib/data/models/level_title.dart` |
| Missões | `lib/data/seed/quest_catalog.dart` |
| Conquistas | `lib/data/seed/achievement_catalog.dart` |
| Equipamentos/avatares | `lib/data/seed/gear_catalog.dart` |
