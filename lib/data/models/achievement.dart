import '../../core/domain/attribute.dart';

/// Raridade de uma conquista ou item.
enum Rarity {
  common('Comum'),
  rare('Rara'),
  epic('Épica'),
  legendary('Lendária');

  const Rarity(this.label);

  final String label;
}

/// Métrica avaliada por uma conquista.
enum AchievementMetric {
  level('nível'),
  streak('dias de sequência'),
  activities('treinos registrados'),
  quests('missões concluídas'),
  attribute('pontos de atributo'),
  totalXp('XP acumulado'),
  guild('guilda');

  const AchievementMetric(this.label);

  final String label;
}

/// Conquista definida no catálogo.
class Achievement {
  const Achievement({
    required this.key,
    required this.title,
    required this.description,
    required this.metric,
    required this.threshold,
    required this.rarity,
    this.attribute,
  });

  final String key;
  final String title;
  final String description;
  final AchievementMetric metric;

  /// Valor a atingir na métrica.
  final int threshold;

  final Rarity rarity;

  /// Preenchido apenas quando `metric == AchievementMetric.attribute`.
  final Attribute? attribute;

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'description': description,
    'metric': metric.name,
    'threshold': threshold,
    'rarity': rarity.name,
    'attribute': attribute?.name,
  };
}
