import 'dart:math' as math;

import '../domain/activity.dart';

/// Regras de XP — **fonte única da verdade** do balanceamento.
///
/// Nunca espalhe esses números pelo código. Quer ajustar o jogo?
/// Mude aqui e rode os testes. Ver `docs/GAME_DESIGN.md`.
class XpRules {
  const XpRules._();

  // ---------------------------------------------------------------
  // Curva de níveis: XP para ir do nível n para n+1
  // ---------------------------------------------------------------

  /// Nível máximo considerado no cálculo.
  static const int maxLevel = 100;

  /// XP necessário para ir do nível `level` para `level + 1`.
  static int xpToAdvanceFrom(int level) {
    if (level < 1) return 0;
    return (100 * math.pow(level, 1.5)).round();
  }

  // ---------------------------------------------------------------
  // XP base por unidade de cada atividade
  // ---------------------------------------------------------------

  /// Quanto XP vale **1 unidade** de cada atividade (1 série, 1 km, 1 minuto...).
  static const Map<ActivityKind, double> xpPerUnit = {
    ActivityKind.strength: 15,
    ActivityKind.cardio: 8,
    ActivityKind.mobility: 6,
    ActivityKind.recovery: 4,
    ActivityKind.steps: 40,
    ActivityKind.nutrition: 10,
  };

  /// XP base de uma atividade, antes de multiplicadores.
  static double baseXp(ActivityKind kind, double amount) {
    final perUnit = xpPerUnit[kind] ?? 0;
    return perUnit * amount;
  }

  // ---------------------------------------------------------------
  // Fatores de intensidade
  // ---------------------------------------------------------------

  static double intensityMultiplier(Intensity intensity) => switch (intensity) {
    Intensity.light => 0.8,
    Intensity.moderate => 1.0,
    Intensity.intense => 1.3,
  };

  // ---------------------------------------------------------------
  // Multiplicadores de bônus
  // ---------------------------------------------------------------

  /// Bônus por dia de streak (1% por dia, teto de +30%).
  static const double streakBonusPerDay = 0.01;
  static const double streakBonusCap = 0.30;

  /// Teto do bônus de guilda (+15%).
  static const double guildBonusCap = 0.15;

  /// Converte dias de streak em multiplicador (ex.: 10 dias -> 1.10).
  static double streakMultiplier(int streakDays) {
    final bonus = (streakDays.clamp(0, 300) * streakBonusPerDay).clamp(
      0.0,
      streakBonusCap,
    );
    return 1.0 + bonus;
  }

  /// Normaliza o bônus de guilda para o teto permitido.
  static double guildMultiplier(double guildBonus) =>
      1.0 + guildBonus.clamp(0.0, guildBonusCap);

  // ---------------------------------------------------------------
  // Limites de sanidade (anti-abuso / anti-typo)
  // ---------------------------------------------------------------

  /// Quantidade máxima aceita em um único registro.
  static const double maxAmountPerActivity = 100000;

  /// XP máximo aceito em um único registro.
  static const int maxXpPerActivity = 5000;

  /// Recompensa padrão ao completar uma missão.
  static const int dailyQuestXp = 50;
  static const int weeklyQuestXp = 200;
  static const int epicQuestXp = 500;

  /// Moedas recebidas ao abrir o baú de streak (a cada 7 dias).
  static const int streakChestCoins = 75;

  /// Frequência (em dias) do baú de streak.
  static const int streakChestInterval = 7;
}
