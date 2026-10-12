import '../../core/domain/attribute.dart';
import '../models/achievement.dart';

/// Catálogo de conquistas.
const List<Achievement> achievementCatalog = [
  Achievement(
    key: 'first_workout',
    title: 'O primeiro passo',
    description: 'Registre seu primeiro treino.',
    metric: AchievementMetric.activities,
    threshold: 1,
    rarity: Rarity.common,
  ),
  Achievement(
    key: 'streak_3',
    title: 'Aquecendo',
    description: 'Mantenha 3 dias consecutivos ativos.',
    metric: AchievementMetric.streak,
    threshold: 3,
    rarity: Rarity.common,
  ),
  Achievement(
    key: 'streak_7',
    title: 'Inabalável',
    description: 'Mantenha 7 dias consecutivos ativos.',
    metric: AchievementMetric.streak,
    threshold: 7,
    rarity: Rarity.rare,
  ),
  Achievement(
    key: 'streak_30',
    title: 'Lenda viva',
    description: 'Mantenha 30 dias consecutivos ativos.',
    metric: AchievementMetric.streak,
    threshold: 30,
    rarity: Rarity.epic,
  ),
  Achievement(
    key: 'level_5',
    title: 'Aprendiz dedicado',
    description: 'Alcance o nível 5.',
    metric: AchievementMetric.level,
    threshold: 5,
    rarity: Rarity.common,
  ),
  Achievement(
    key: 'level_10',
    title: 'Combatente',
    description: 'Alcance o nível 10.',
    metric: AchievementMetric.level,
    threshold: 10,
    rarity: Rarity.rare,
  ),
  Achievement(
    key: 'level_20',
    title: 'Veterano',
    description: 'Alcance o nível 20.',
    metric: AchievementMetric.level,
    threshold: 20,
    rarity: Rarity.epic,
  ),
  Achievement(
    key: 'level_50',
    title: 'Lenda',
    description: 'Alcance o nível 50.',
    metric: AchievementMetric.level,
    threshold: 50,
    rarity: Rarity.legendary,
  ),
  Achievement(
    key: 'strength_500',
    title: 'Força bruta',
    description: 'Acumule 500 pontos de Força.',
    metric: AchievementMetric.attribute,
    attribute: Attribute.strength,
    threshold: 500,
    rarity: Rarity.rare,
  ),
  Achievement(
    key: 'stamina_1000',
    title: 'Pulmão de aço',
    description: 'Acumule 1.000 pontos de Vigor.',
    metric: AchievementMetric.attribute,
    attribute: Attribute.stamina,
    threshold: 1000,
    rarity: Rarity.rare,
  ),
  Achievement(
    key: 'focus_800',
    title: 'Mente serena',
    description: 'Acumule 800 pontos de Foco.',
    metric: AchievementMetric.attribute,
    attribute: Attribute.focus,
    threshold: 800,
    rarity: Rarity.rare,
  ),
  Achievement(
    key: 'quests_10',
    title: 'Caçador de missões',
    description: 'Conclua 10 missões.',
    metric: AchievementMetric.quests,
    threshold: 10,
    rarity: Rarity.rare,
  ),
  Achievement(
    key: 'xp_25000',
    title: 'Vinte e cinco mil',
    description: 'Acumule 25.000 XP.',
    metric: AchievementMetric.totalXp,
    threshold: 25000,
    rarity: Rarity.epic,
  ),
  Achievement(
    key: 'join_guild',
    title: 'Ninguém luta sozinho',
    description: 'Entre em uma guilda.',
    metric: AchievementMetric.guild,
    threshold: 1,
    rarity: Rarity.common,
  ),
];

/// Busca uma conquista pela chave.
Achievement? achievementByKey(String key) {
  for (final achievement in achievementCatalog) {
    if (achievement.key == key) return achievement;
  }
  return null;
}
