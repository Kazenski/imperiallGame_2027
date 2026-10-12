import 'package:flutter_test/flutter_test.dart';
import 'package:imperiall_game/core/constants/xp_rules.dart';
import 'package:imperiall_game/core/domain/activity.dart';
import 'package:imperiall_game/core/domain/attribute.dart';
import 'package:imperiall_game/data/models/game_state.dart';
import 'package:imperiall_game/data/models/guild.dart';
import 'package:imperiall_game/data/models/player.dart';
import 'package:imperiall_game/data/models/quest.dart';
import 'package:imperiall_game/services/progression_engine.dart';

final _now = DateTime(2026, 1, 15, 12);
final _yesterday = DateTime(2026, 1, 14, 12);

const _guild = Guild(
  id: 'g1',
  name: 'Teste',
  description: 'Guilda de teste',
  memberLimit: 10,
  members: [],
);

const _strengthQuest = Quest(
  key: 'test_strength',
  title: 'Força de teste',
  description: 'Acumule 10 séries.',
  period: QuestPeriod.daily,
  kind: ActivityKind.strength,
  target: 10,
  rewardXp: 50,
  rewardCoins: 25,
);

Player _player({
  int totalXp = 0,
  int streakCurrent = 0,
  int streakBest = 0,
  int activitiesTotal = 0,
  int questsCompletedTotal = 0,
  int coins = 0,
  DateTime? lastActiveDate,
  String? guildId,
  Map<Attribute, int> attributes = const {},
  List<String> unlockedGear = const [],
}) {
  return Player(
    id: 'p1',
    username: 'tester',
    displayName: 'Tester',
    totalXp: totalXp,
    attributes: attributes,
    coins: coins,
    gems: 0,
    streakCurrent: streakCurrent,
    streakBest: streakBest,
    activitiesTotal: activitiesTotal,
    questsCompletedTotal: questsCompletedTotal,
    unlockedGear: unlockedGear,
    equippedGear: const [],
    lastActiveDate: lastActiveDate,
    guildId: guildId,
  );
}

GameState _state({
  Player? player,
  List<QuestStatus> quests = const [],
  Set<String> unlockedAchievements = const {},
}) {
  return GameState(
    player: player ?? _player(),
    activities: const [],
    quests: quests,
    unlockedAchievements: unlockedAchievements,
    guild: _guild,
    questPeriodStart: DateTime(2026, 1, 15),
  );
}

void main() {
  const engine = ProgressionEngine();

  group('ProgressionEngine.apply', () {
    test('registra a atividade e credita XP ao atributo primário', () {
      final state = _state();
      final outcome = engine.apply(
        state: state,
        kind: ActivityKind.strength,
        amount: 10,
        intensity: Intensity.moderate,
        now: _now,
      );

      expect(outcome.state.activities, hasLength(1));
      expect(outcome.result.award.totalXp, greaterThan(0));
      expect(
        outcome.state.player.totalXp,
        state.player.totalXp + outcome.result.award.totalXp,
      );
      expect(
        outcome.state.player.xpOf(Attribute.strength),
        outcome.result.award.totalXp,
      );
      expect(outcome.state.player.activitiesTotal, 1);
    });

    test('não muta o estado original (puro)', () {
      final state = _state();
      engine.apply(
        state: state,
        kind: ActivityKind.cardio,
        amount: 5,
        intensity: Intensity.intense,
        now: _now,
      );

      expect(state.activities, isEmpty);
      expect(state.player.totalXp, 0);
    });

    test('quantidade negativa ou infinita vira zero', () {
      final neg = engine.apply(
        state: _state(),
        kind: ActivityKind.strength,
        amount: -50,
        intensity: Intensity.moderate,
        now: _now,
      );
      expect(neg.result.award.totalXp, 0);

      final inf = engine.apply(
        state: _state(),
        kind: ActivityKind.strength,
        amount: double.infinity,
        intensity: Intensity.moderate,
        now: _now,
      );
      expect(inf.result.award.totalXp, 0);
    });

    test('completa a missão e paga a recompensa', () {
      final state = _state(
        quests: const [
          QuestStatus(quest: _strengthQuest, progress: 0, completed: false),
        ],
      );

      final outcome = engine.apply(
        state: state,
        kind: ActivityKind.strength,
        amount: 12,
        intensity: Intensity.moderate,
        now: _now,
      );

      expect(outcome.result.completedQuests, hasLength(1));
      expect(outcome.state.quests.first.completed, isTrue);
      expect(outcome.state.player.coins, _strengthQuest.rewardCoins);
      expect(outcome.state.player.questsCompletedTotal, 1);
    });
  });

  group('streak', () {
    test('primeira atividade inicia a sequência em 1', () {
      final outcome = engine.apply(
        state: _state(),
        kind: ActivityKind.strength,
        amount: 5,
        intensity: Intensity.moderate,
        now: _now,
      );

      expect(outcome.state.player.streakCurrent, 1);
      expect(outcome.result.streakIncreased, isTrue);
    });

    test('atividade no dia seguinte incrementa a sequência', () {
      final outcome = engine.apply(
        state: _state(
          player: _player(
            streakCurrent: 5,
            streakBest: 5,
            lastActiveDate: _yesterday,
          ),
        ),
        kind: ActivityKind.strength,
        amount: 5,
        intensity: Intensity.moderate,
        now: _now,
      );

      expect(outcome.state.player.streakCurrent, 6);
      expect(outcome.result.streakChestOpened, isFalse);
    });

    test('treinar de novo no mesmo dia não mexe na sequência', () {
      final outcome = engine.apply(
        state: _state(player: _player(streakCurrent: 5, lastActiveDate: _now)),
        kind: ActivityKind.strength,
        amount: 5,
        intensity: Intensity.moderate,
        now: _now,
      );

      expect(outcome.state.player.streakCurrent, 5);
      expect(outcome.result.streakIncreased, isFalse);
    });

    test('abre o baú de sequência no ciclo configurado', () {
      final outcome = engine.apply(
        state: _state(
          player: _player(
            streakCurrent: XpRules.streakChestInterval - 1,
            lastActiveDate: _yesterday,
          ),
        ),
        kind: ActivityKind.strength,
        amount: 5,
        intensity: Intensity.moderate,
        now: _now,
      );

      expect(outcome.state.player.streakCurrent, XpRules.streakChestInterval);
      expect(outcome.result.streakChestOpened, isTrue);
      expect(outcome.state.player.coins, XpRules.streakChestCoins);
    });
  });

  group('conquistas e equipamento', () {
    test('desbloqueia a conquista do primeiro treino', () {
      final outcome = engine.apply(
        state: _state(),
        kind: ActivityKind.strength,
        amount: 5,
        intensity: Intensity.moderate,
        now: _now,
      );

      expect(
        outcome.result.unlockedAchievements.map((a) => a.key),
        contains('first_workout'),
      );
      expect(outcome.state.unlockedAchievements, contains('first_workout'));
    });

    test('desbloqueia equipamento por nível', () {
      final outcome = engine.apply(
        state: _state(player: _player(unlockedGear: const ['wooden_sword'])),
        kind: ActivityKind.strength,
        amount: 5,
        intensity: Intensity.moderate,
        now: _now,
      );

      final unlockedKeys = outcome.result.unlockedGear.map((g) => g.key);
      expect(unlockedKeys, contains('leather_vest'));
      expect(unlockedKeys, isNot(contains('wooden_sword')));
    });
  });

  group('previewAward', () {
    test('não altera o estado', () {
      final state = _state(player: _player(streakCurrent: 10, guildId: 'g1'));
      final award = engine.previewAward(
        state: state,
        kind: ActivityKind.strength,
        amount: 10,
        intensity: Intensity.intense,
      );

      expect(award.totalXp, greaterThan(0));
      expect(state.activities, isEmpty);
      expect(state.player.totalXp, 0);
    });
  });
}
