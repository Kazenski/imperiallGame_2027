import '../core/constants/xp_rules.dart';
import '../core/domain/activity.dart';
import '../core/utils/xp_calculator.dart';
import '../data/models/achievement.dart';
import '../data/models/activity_entry.dart';
import '../data/models/game_state.dart';
import '../data/models/gear_item.dart';
import '../data/models/player.dart';
import '../data/models/quest.dart';
import '../data/seed/achievement_catalog.dart';
import '../data/seed/gear_catalog.dart';

/// Resultado de aplicar uma progressão ao estado do jogo.
class ProgressionOutcome {
  const ProgressionOutcome({required this.result, required this.state});

  final WorkoutResult result;
  final GameState state;
}

/// Motor de progressão: calcula XP, atributos, missões, streak, conquistas e loot.
///
/// **Puro e determinístico** — mesmas entradas, mesmas saídas.
/// Toda a regra de negócio do jogo está aqui e é 100% testável.
class ProgressionEngine {
  const ProgressionEngine();

  /// Aplica o registro de uma atividade sobre o estado atual.
  ProgressionOutcome apply({
    required GameState state,
    required ActivityKind kind,
    required double amount,
    required Intensity intensity,
    String? note,
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final safeAmount = amount.isFinite
        ? amount.clamp(0, XpRules.maxAmountPerActivity).toDouble()
        : 0.0;

    final award = _calculateAward(
      state: state,
      kind: kind,
      amount: safeAmount,
      intensity: intensity,
    );

    final entry = ActivityEntry(
      id: 'act-${moment.microsecondsSinceEpoch}',
      kind: kind,
      amount: safeAmount,
      intensity: intensity,
      xpAwarded: award.totalXp,
      performedAt: moment,
      note: note,
    );

    // ---- Missões -------------------------------------------------------
    final questOutcome = _advanceQuests(
      quests: state.quests,
      kind: kind,
      amount: safeAmount,
    );

    // ---- Streak --------------------------------------------------------
    final streakOutcome = _advanceStreak(player: state.player, today: moment);

    // ---- Jogador -------------------------------------------------------
    final attributes = {...state.player.attributes};
    attributes[kind.primaryAttribute] =
        (attributes[kind.primaryAttribute] ?? 0) + award.totalXp;

    var player = state.player.copyWith(
      totalXp: state.player.totalXp + award.totalXp + questOutcome.bonusXp,
      attributes: attributes,
      coins: state.player.coins + questOutcome.bonusCoins + streakOutcome.coins,
      streakCurrent: streakOutcome.current,
      streakBest: streakOutcome.best,
      activitiesTotal: state.player.activitiesTotal + 1,
      questsCompletedTotal:
          state.player.questsCompletedTotal + questOutcome.completed.length,
      lastActiveDate: moment,
    );

    // ---- Conquistas ----------------------------------------------------
    final newlyUnlockedAchievements = _evaluateAchievements(player, state);

    // ---- Equipamento ---------------------------------------------------
    final newlyUnlockedGear = _evaluateGear(player);

    if (newlyUnlockedGear.isNotEmpty) {
      player = player.copyWith(
        unlockedGear: [
          ...player.unlockedGear,
          ...newlyUnlockedGear.map((item) => item.key),
        ],
      );
    }

    final newState = state.copyWith(
      player: player,
      activities: [...state.activities, entry],
      quests: questOutcome.quests,
      unlockedAchievements: {
        ...state.unlockedAchievements,
        ...newlyUnlockedAchievements.map((achievement) => achievement.key),
      },
    );

    return ProgressionOutcome(
      state: newState,
      result: WorkoutResult(
        entry: entry,
        award: award,
        completedQuests: questOutcome.completed,
        unlockedAchievements: newlyUnlockedAchievements,
        unlockedGear: newlyUnlockedGear,
        coinsGained: questOutcome.bonusCoins + streakOutcome.coins,
        streakIncreased: streakOutcome.increased,
        streakChestOpened: streakOutcome.chestOpened,
      ),
    );
  }

  /// Prévia do XP de uma atividade, sem alterar nada (para a UI mostrar antes de salvar).
  XpAward previewAward({
    required GameState state,
    required ActivityKind kind,
    required double amount,
    required Intensity intensity,
  }) {
    final safeAmount = amount.isFinite
        ? amount.clamp(0, XpRules.maxAmountPerActivity).toDouble()
        : 0.0;
    return _calculateAward(
      state: state,
      kind: kind,
      amount: safeAmount,
      intensity: intensity,
    );
  }

  // ------------------------------------------------------------------
  // Internos
  // ------------------------------------------------------------------

  XpAward _calculateAward({
    required GameState state,
    required ActivityKind kind,
    required double amount,
    required Intensity intensity,
  }) {
    // Bônus de guilda: 10% ao participar de uma guilda (teto de 15% em XpRules).
    const guildBonus = 0.10;

    return XpCalculator.calculate(
      baseXp: XpRules.baseXp(kind, amount),
      currentTotalXp: state.player.totalXp,
      intensityMultiplier: XpRules.intensityMultiplier(intensity),
      streakMultiplier: XpRules.streakMultiplier(state.player.streakCurrent),
      guildMultiplier: XpRules.guildMultiplier(
        state.player.guildId == null ? 0 : guildBonus,
      ),
    );
  }

  _QuestOutcome _advanceQuests({
    required List<QuestStatus> quests,
    required ActivityKind kind,
    required double amount,
  }) {
    final completed = <Quest>[];
    var bonusXp = 0;
    var bonusCoins = 0;

    final updated = quests.map((status) {
      final quest = status.quest;
      final matches = quest.kind == kind;

      if (!matches || status.completed) return status;

      final nextProgress = status.progress + amount;
      final isDone = nextProgress >= quest.target;

      if (isDone) {
        completed.add(quest);
        bonusXp += quest.rewardXp;
        bonusCoins += quest.rewardCoins;
      }

      return status.copyWith(progress: nextProgress, completed: isDone);
    }).toList();

    return _QuestOutcome(
      quests: updated,
      completed: completed,
      bonusXp: bonusXp,
      bonusCoins: bonusCoins,
    );
  }

  _StreakOutcome _advanceStreak({
    required Player player,
    required DateTime today,
  }) {
    final last = player.lastActiveDate;

    // Já treinou hoje: streak não muda.
    if (last != null && _isSameDay(last, today)) {
      return _StreakOutcome(
        current: player.streakCurrent,
        best: player.streakBest,
        increased: false,
        chestOpened: false,
        coins: 0,
      );
    }

    final wasYesterday =
        last != null &&
        _isSameDay(last, today.subtract(const Duration(days: 1)));

    final current = wasYesterday ? player.streakCurrent + 1 : 1;
    final best = current > player.streakBest ? current : player.streakBest;

    final chestOpened = current % XpRules.streakChestInterval == 0;

    return _StreakOutcome(
      current: current,
      best: best,
      increased: true,
      chestOpened: chestOpened,
      coins: chestOpened ? XpRules.streakChestCoins : 0,
    );
  }

  List<Achievement> _evaluateAchievements(Player player, GameState state) {
    final unlocked = <Achievement>[];

    for (final achievement in achievementCatalog) {
      if (state.unlockedAchievements.contains(achievement.key)) continue;
      if (_isAchievementSatisfied(achievement, player)) {
        unlocked.add(achievement);
      }
    }

    return unlocked;
  }

  bool _isAchievementSatisfied(Achievement achievement, Player player) {
    return switch (achievement.metric) {
      AchievementMetric.level => player.level >= achievement.threshold,
      AchievementMetric.streak => player.streakBest >= achievement.threshold,
      AchievementMetric.activities =>
        player.activitiesTotal >= achievement.threshold,
      AchievementMetric.quests =>
        player.questsCompletedTotal >= achievement.threshold,
      AchievementMetric.totalXp => player.totalXp >= achievement.threshold,
      AchievementMetric.attribute =>
        player.xpOf(achievement.attribute!) >= achievement.threshold,
      AchievementMetric.guild => player.guildId != null,
    };
  }

  List<GearItem> _evaluateGear(Player player) {
    return gearCatalog
        .where(
          (item) =>
              !player.unlockedGear.contains(item.key) &&
              item.isUnlockedFor(player),
        )
        .toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _QuestOutcome {
  const _QuestOutcome({
    required this.quests,
    required this.completed,
    required this.bonusXp,
    required this.bonusCoins,
  });

  final List<QuestStatus> quests;
  final List<Quest> completed;
  final int bonusXp;
  final int bonusCoins;
}

class _StreakOutcome {
  const _StreakOutcome({
    required this.current,
    required this.best,
    required this.increased,
    required this.chestOpened,
    required this.coins,
  });

  final int current;
  final int best;
  final bool increased;
  final bool chestOpened;
  final int coins;
}
