import 'package:flutter_test/flutter_test.dart';
import 'package:imperiall_game/core/utils/xp_calculator.dart';
import 'package:imperiall_game/core/constants/xp_rules.dart';

void main() {
  group('XpCalculator.levelForXp', () {
    test('XP zero ou negativo é nível 1', () {
      expect(XpCalculator.levelForXp(0), 1);
      expect(XpCalculator.levelForXp(-100), 1);
    });

    test('o nível sobe exatamente nos limites de XP', () {
      for (var level = 1; level <= 20; level++) {
        final threshold = XpCalculator.totalXpForLevel(level);
        expect(
          XpCalculator.levelForXp(threshold),
          level,
          reason: 'XP $threshold deveria ser nível $level',
        );
        if (threshold > 0) {
          expect(
            XpCalculator.levelForXp(threshold - 1),
            level - 1,
            reason: 'XP ${threshold - 1} deveria ser nível ${level - 1}',
          );
        }
      }
    });

    test('nível nunca passa do máximo configurado', () {
      final huge = XpCalculator.totalXpForLevel(XpRules.maxLevel) * 10;
      expect(XpCalculator.levelForXp(huge), XpRules.maxLevel);
    });
  });

  group('XpCalculator.progress', () {
    test('frações ficam sempre entre 0 e 1', () {
      for (final xp in [0, 1, 500, 5000, 19260, 999999]) {
        final progress = XpCalculator.progress(xp);
        expect(progress.fraction, inInclusiveRange(0.0, 1.0));
        expect(progress.totalXp, xp);
      }
    });

    test('xpIntoLevel + restante equivale ao intervalo do nível', () {
      const totalXp = 19260;
      final progress = XpCalculator.progress(totalXp);
      expect(
        progress.xpIntoLevel + progress.xpRemaining,
        progress.xpToNextLevel,
      );
    });
  });

  group('XpCalculator.calculate', () {
    test('aplica os multiplicadores e arredonda', () {
      final award = XpCalculator.calculate(
        baseXp: 100,
        currentTotalXp: 0,
        intensityMultiplier: 1.3,
        streakMultiplier: 1.10,
        guildMultiplier: 1.10,
      );

      expect(award.totalXp, (100 * 1.3 * 1.10 * 1.10).round());
      expect(award.previousLevel, 1);
    });

    test('detecta level up', () {
      final threshold = XpCalculator.totalXpForLevel(2);
      final award = XpCalculator.calculate(
        baseXp: 1,
        currentTotalXp: threshold - 1,
        intensityMultiplier: 1.0,
        streakMultiplier: 1.0,
        guildMultiplier: 1.0,
      );

      expect(award.previousLevel, 1);
      expect(award.newLevel, 2);
      expect(award.didLevelUp, isTrue);
      expect(award.levelsGained, 1);
    });

    test('nunca ultrapassa o teto de XP por atividade', () {
      final award = XpCalculator.calculate(
        baseXp: 999999999,
        currentTotalXp: 0,
        intensityMultiplier: 5,
        streakMultiplier: 5,
        guildMultiplier: 5,
      );

      expect(award.totalXp, XpRules.maxXpPerActivity);
    });
  });
}
