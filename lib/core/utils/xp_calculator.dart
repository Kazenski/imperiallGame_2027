import 'dart:math' as math;

import '../constants/xp_rules.dart';

/// Progresso de XP dentro do nível atual.
class XpProgress {
  const XpProgress({
    required this.level,
    required this.xpIntoLevel,
    required this.xpToNextLevel,
    required this.totalXp,
    required this.isMaxLevel,
  });

  final int level;

  /// XP acumulado dentro do nível atual.
  final int xpIntoLevel;

  /// XP necessário para subir do nível atual. `0` no nível máximo.
  final int xpToNextLevel;

  final int totalXp;
  final bool isMaxLevel;

  /// Fração 0..1 de preenchimento da barra de XP.
  double get fraction {
    if (isMaxLevel || xpToNextLevel == 0) return 1;
    return (xpIntoLevel / xpToNextLevel).clamp(0.0, 1.0);
  }

  int get xpRemaining => math.max(0, xpToNextLevel - xpIntoLevel);
}

/// Resultado do cálculo de uma concessão de XP.
class XpAward {
  const XpAward({
    required this.baseXp,
    required this.intensityMultiplier,
    required this.streakMultiplier,
    required this.guildMultiplier,
    required this.totalXp,
    required this.previousLevel,
    required this.newLevel,
  });

  final double baseXp;
  final double intensityMultiplier;
  final double streakMultiplier;
  final double guildMultiplier;
  final int totalXp;
  final int previousLevel;
  final int newLevel;

  int get levelsGained => newLevel - previousLevel;

  bool get didLevelUp => levelsGained > 0;

  /// Bônus (em %) vindo apenas do streak, para exibir na UI.
  double get streakBonus => streakMultiplier - 1;
}

/// Calculadora pura de XP e níveis. Um dos poucos lugares com matemática do jogo.
class XpCalculator {
  const XpCalculator._();

  /// XP total acumulado necessário para **estar** no nível informado.
  ///
  /// O nível 1 começa em 0 XP.
  static int totalXpForLevel(int level) {
    if (level <= 1) return 0;
    var total = 0;
    final target = math.min(level, XpRules.maxLevel);
    for (var i = 1; i < target; i++) {
      total += XpRules.xpToAdvanceFrom(i);
    }
    return total;
  }

  /// Deduz o nível a partir do XP total.
  static int levelForXp(int totalXp) {
    if (totalXp <= 0) return 1;

    var level = 1;
    var accumulated = 0;
    while (level < XpRules.maxLevel) {
      final next = accumulated + XpRules.xpToAdvanceFrom(level);
      if (totalXp < next) break;
      accumulated = next;
      level++;
    }
    return level;
  }

  /// Progresso detalhado dentro do nível.
  static XpProgress progress(int totalXp) {
    final safeXp = math.max(0, totalXp);
    final level = levelForXp(safeXp);
    final xpIntoLevel = safeXp - totalXpForLevel(level);
    final isMaxLevel = level >= XpRules.maxLevel;

    return XpProgress(
      level: level,
      xpIntoLevel: xpIntoLevel,
      xpToNextLevel: isMaxLevel ? 0 : XpRules.xpToAdvanceFrom(level),
      totalXp: safeXp,
      isMaxLevel: isMaxLevel,
    );
  }

  /// Calcula a concessão de XP de uma atividade.
  ///
  /// [baseXp] já vem de `XpRules.baseXp(...)`.
  static XpAward calculate({
    required double baseXp,
    required int currentTotalXp,
    required double intensityMultiplier,
    required double streakMultiplier,
    required double guildMultiplier,
  }) {
    final safeBase = math.max(0.0, baseXp);
    final raw =
        safeBase * intensityMultiplier * streakMultiplier * guildMultiplier;

    final total = raw.round().clamp(0, XpRules.maxXpPerActivity);

    return XpAward(
      baseXp: safeBase,
      intensityMultiplier: intensityMultiplier,
      streakMultiplier: streakMultiplier,
      guildMultiplier: guildMultiplier,
      totalXp: total,
      previousLevel: levelForXp(currentTotalXp),
      newLevel: levelForXp(currentTotalXp + total),
    );
  }
}
