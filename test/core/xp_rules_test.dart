import 'package:flutter_test/flutter_test.dart';
import 'package:imperiall_game/core/constants/xp_rules.dart';
import 'package:imperiall_game/core/domain/activity.dart';

void main() {
  group('XpRules.baseXp', () {
    test('multiplica a quantidade pelo valor por unidade', () {
      expect(
        XpRules.baseXp(ActivityKind.strength, 10),
        XpRules.xpPerUnit[ActivityKind.strength]! * 10,
      );
      expect(
        XpRules.baseXp(ActivityKind.cardio, 5),
        XpRules.xpPerUnit[ActivityKind.cardio]! * 5,
      );
    });
  });

  group('multiplicadores', () {
    test('intensidade cresce de leve para intensa', () {
      expect(
        XpRules.intensityMultiplier(Intensity.light),
        lessThan(XpRules.intensityMultiplier(Intensity.moderate)),
      );
      expect(
        XpRules.intensityMultiplier(Intensity.moderate),
        lessThan(XpRules.intensityMultiplier(Intensity.intense)),
      );
    });

    test('streak dá 1% por dia e respeita o teto de +30%', () {
      expect(XpRules.streakMultiplier(0), 1.0);
      expect(XpRules.streakMultiplier(10), closeTo(1.10, 1e-9));
      expect(
        XpRules.streakMultiplier(1000),
        closeTo(1 + XpRules.streakBonusCap, 1e-9),
      );
    });

    test('bônus de guilda respeita o teto de +15%', () {
      expect(XpRules.guildMultiplier(0), 1.0);
      expect(XpRules.guildMultiplier(0.10), closeTo(1.10, 1e-9));
      expect(
        XpRules.guildMultiplier(1),
        closeTo(1 + XpRules.guildBonusCap, 1e-9),
      );
    });

    test('streak negativo não derruba o multiplicador abaixo de 1', () {
      expect(XpRules.streakMultiplier(-5), 1.0);
    });
  });

  group('curva de níveis', () {
    test('é estritamente crescente', () {
      for (var level = 1; level < 50; level++) {
        expect(
          XpRules.xpToAdvanceFrom(level + 1),
          greaterThan(XpRules.xpToAdvanceFrom(level)),
        );
      }
    });

    test('nível inválido retorna zero', () {
      expect(XpRules.xpToAdvanceFrom(0), 0);
    });
  });
}
