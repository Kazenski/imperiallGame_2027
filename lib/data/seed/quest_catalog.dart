import '../../core/constants/xp_rules.dart';
import '../../core/domain/activity.dart';
import '../models/quest.dart';

/// Missões diárias — renovadas na virada do dia.
const List<Quest> dailyQuests = [
  Quest(
    key: 'daily_strength_12',
    title: 'Deixe a preguiça no chão',
    description: 'Registre 12 séries de musculação.',
    period: QuestPeriod.daily,
    kind: ActivityKind.strength,
    target: 12,
    rewardXp: XpRules.dailyQuestXp,
    rewardCoins: 25,
  ),
  Quest(
    key: 'daily_cardio_3',
    title: 'Um pouco mais longe',
    description: 'Corra ou caminhe 3 km.',
    period: QuestPeriod.daily,
    kind: ActivityKind.cardio,
    target: 3,
    rewardXp: XpRules.dailyQuestXp,
    rewardCoins: 25,
  ),
  Quest(
    key: 'daily_mobility_15',
    title: 'Respire fundo',
    description: 'Acumule 15 minutos de mobilidade.',
    period: QuestPeriod.daily,
    kind: ActivityKind.mobility,
    target: 15,
    rewardXp: XpRules.dailyQuestXp,
    rewardCoins: 25,
  ),
];

/// Missões semanais — renovadas na segunda-feira.
const List<Quest> weeklyQuests = [
  Quest(
    key: 'weekly_strength_40',
    title: 'Ferro e vontade',
    description: 'Acumule 40 séries na semana.',
    period: QuestPeriod.weekly,
    kind: ActivityKind.strength,
    target: 40,
    rewardXp: XpRules.weeklyQuestXp,
    rewardCoins: 120,
  ),
  Quest(
    key: 'weekly_cardio_20',
    title: 'Fôlego de gigante',
    description: 'Acumule 20 km de cardio na semana.',
    period: QuestPeriod.weekly,
    kind: ActivityKind.cardio,
    target: 20,
    rewardXp: XpRules.weeklyQuestXp,
    rewardCoins: 120,
  ),
  Quest(
    key: 'weekly_recovery_60',
    title: 'Recuperar é treinar',
    description: 'Acumule 60 minutos de recuperação.',
    period: QuestPeriod.weekly,
    kind: ActivityKind.recovery,
    target: 60,
    rewardXp: XpRules.weeklyQuestXp,
    rewardCoins: 120,
  ),
  Quest(
    key: 'weekly_steps_35',
    title: 'Passos de império',
    description: 'Some 35 mil passos na semana.',
    period: QuestPeriod.weekly,
    kind: ActivityKind.steps,
    target: 35,
    rewardXp: XpRules.weeklyQuestXp,
    rewardCoins: 120,
  ),
  Quest(
    key: 'weekly_nutrition_10',
    title: 'Combustível do herói',
    description: 'Registre 10 refeições na semana.',
    period: QuestPeriod.weekly,
    kind: ActivityKind.nutrition,
    target: 10,
    rewardXp: XpRules.weeklyQuestXp,
    rewardCoins: 120,
  ),
];

/// Missão épica — desafio de longo prazo, sem prazo automático.
const List<Quest> epicQuests = [
  Quest(
    key: 'epic_cardio_100',
    title: 'A Maratona do Império',
    description: 'Acumule 100 km de cardio. Sem pressa, sem desculpa.',
    period: QuestPeriod.epic,
    kind: ActivityKind.cardio,
    target: 100,
    rewardXp: XpRules.epicQuestXp,
    rewardCoins: 500,
  ),
];

/// Catálogo completo.
const List<Quest> questCatalog = [
  ...dailyQuests,
  ...weeklyQuests,
  ...epicQuests,
];

/// Busca uma missão pela chave.
Quest? questByKey(String key) {
  for (final quest in questCatalog) {
    if (quest.key == key) return quest;
  }
  return null;
}
