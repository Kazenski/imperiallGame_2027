import '../../core/domain/activity.dart';

/// Frequência de renovação de uma missão.
enum QuestPeriod {
  daily('Diária'),
  weekly('Semanal'),
  epic('Épica');

  const QuestPeriod(this.label);

  final String label;
}

/// Definição de uma missão (catálogo).
class Quest {
  const Quest({
    required this.key,
    required this.title,
    required this.description,
    required this.period,
    required this.kind,
    required this.target,
    required this.rewardXp,
    required this.rewardCoins,
  });

  final String key;
  final String title;
  final String description;
  final QuestPeriod period;

  /// Atividade que progride esta missão.
  final ActivityKind kind;

  /// Quantas unidades da atividade são necessárias.
  final double target;

  final int rewardXp;
  final int rewardCoins;

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'description': description,
    'period': period.name,
    'kind': kind.name,
    'target': target,
    'reward_xp': rewardXp,
    'reward_coins': rewardCoins,
  };
}

/// Estado de andamento de uma missão para o jogador atual.
class QuestStatus {
  const QuestStatus({
    required this.quest,
    required this.progress,
    required this.completed,
  });

  final Quest quest;
  final double progress;
  final bool completed;

  double get fraction =>
      quest.target <= 0 ? 1 : (progress / quest.target).clamp(0.0, 1.0);

  double get remaining =>
      (quest.target - progress).clamp(0, quest.target).toDouble();

  QuestStatus copyWith({double? progress, bool? completed}) => QuestStatus(
    quest: quest,
    progress: progress ?? this.progress,
    completed: completed ?? this.completed,
  );
}
