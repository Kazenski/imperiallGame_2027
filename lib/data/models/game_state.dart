import '../../core/domain/activity.dart';
import '../../core/utils/xp_calculator.dart';
import 'activity_entry.dart';
import 'achievement.dart';
import 'gear_item.dart';
import 'guild.dart';
import 'player.dart';
import 'quest.dart';

/// Fotografia completa do estado do jogo em um instante.
class GameState {
  const GameState({
    required this.player,
    required this.activities,
    required this.quests,
    required this.unlockedAchievements,
    required this.guild,
    required this.questPeriodStart,
    this.isDemo = true,
  });

  final Player player;
  final List<ActivityEntry> activities;
  final List<QuestStatus> quests;

  /// Chaves das conquistas já desbloqueadas.
  final Set<String> unlockedAchievements;

  final Guild guild;

  /// Início do período das missões diárias (para resetar na virada do dia).
  final DateTime questPeriodStart;

  final bool isDemo;

  List<QuestStatus> questsOf(QuestPeriod period) =>
      quests.where((status) => status.quest.period == period).toList();

  List<ActivityEntry> get recentActivities {
    final sorted = [...activities]
      ..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return sorted;
  }

  List<ActivityEntry> activitiesOfKind(ActivityKind kind) =>
      activities.where((activity) => activity.kind == kind).toList();

  bool get hasActivityToday {
    final now = DateTime.now();
    return activities.any(
      (activity) =>
          activity.performedAt.year == now.year &&
          activity.performedAt.month == now.month &&
          activity.performedAt.day == now.day,
    );
  }

  GameState copyWith({
    Player? player,
    List<ActivityEntry>? activities,
    List<QuestStatus>? quests,
    Set<String>? unlockedAchievements,
    Guild? guild,
    DateTime? questPeriodStart,
  }) {
    return GameState(
      player: player ?? this.player,
      activities: activities ?? this.activities,
      quests: quests ?? this.quests,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      guild: guild ?? this.guild,
      questPeriodStart: questPeriodStart ?? this.questPeriodStart,
      isDemo: isDemo,
    );
  }

  /// Média de XP por dia considerando os últimos [days] dias de histórico.
  int averageXpPerDay({int days = 7}) {
    if (days <= 0) return 0;
    final since = DateTime.now().subtract(Duration(days: days));
    final total = activities
        .where((activity) => activity.performedAt.isAfter(since))
        .fold<int>(0, (sum, activity) => sum + activity.xpAwarded);
    return (total / days).round();
  }
}

/// Resultado completo de registrar uma atividade — alimenta a tela de recompensa.
class WorkoutResult {
  const WorkoutResult({
    required this.entry,
    required this.award,
    required this.completedQuests,
    required this.unlockedAchievements,
    required this.unlockedGear,
    required this.coinsGained,
    required this.streakIncreased,
    required this.streakChestOpened,
  });

  final ActivityEntry entry;
  final XpAward award;
  final List<Quest> completedQuests;
  final List<Achievement> unlockedAchievements;
  final List<GearItem> unlockedGear;
  final int coinsGained;
  final bool streakIncreased;
  final bool streakChestOpened;

  bool get hasRewardsBeyondXp =>
      completedQuests.isNotEmpty ||
      unlockedAchievements.isNotEmpty ||
      unlockedGear.isNotEmpty ||
      streakChestOpened;
}
