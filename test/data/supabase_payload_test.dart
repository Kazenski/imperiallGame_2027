import 'package:flutter_test/flutter_test.dart';
import 'package:imperiall_game/core/domain/activity.dart';
import 'package:imperiall_game/core/domain/attribute.dart';
import 'package:imperiall_game/data/models/activity_entry.dart';
import 'package:imperiall_game/data/models/game_state.dart';
import 'package:imperiall_game/data/models/guild.dart';
import 'package:imperiall_game/data/models/player.dart';
import 'package:imperiall_game/data/models/quest.dart';
import 'package:imperiall_game/data/repositories/supabase_payload.dart';
import 'package:imperiall_game/data/seed/quest_catalog.dart';

GameState _state({required List<ActivityEntry> activities, Player? player}) {
  final quest = questByKey('daily_cardio_3')!;
  return GameState(
    player:
        player ??
        Player(
      id: 'u1',
      username: 'hero_abc',
      displayName: 'Eduardo',
      totalXp: 19260,
      attributes: const {
        Attribute.strength: 4200,
        Attribute.stamina: 5100,
        Attribute.focus: 2600,
        Attribute.discipline: 3400,
      },
      coins: 1240,
      gems: 12,
      streakCurrent: 9,
      streakBest: 21,
      activitiesTotal: 87,
      questsCompletedTotal: 30,
      unlockedGear: const ['blade_common'],
      equippedGear: const ['blade_common'],
      lastActiveDate: DateTime(2026, 10, 12),
    ),
    activities: activities,
    quests: [QuestStatus(quest: quest, progress: 6.4, completed: true)],
    unlockedAchievements: const {'first_blood', 'streak_7'},
    guild: const Guild(
      id: '',
      name: 'Sem guilda',
      description: '',
      members: [],
      memberLimit: 30,
    ),
    questPeriodStart: DateTime(2026, 10, 12),
    isDemo: false,
  );
}

void main() {
  group('buildSyncPayload', () {
    test('serializa o resumo do jogador', () {
      final payload = buildSyncPayload(
        _state(activities: const []),
        newActivities: const [],
      );

      expect(payload['display_name'], 'Eduardo');
      expect(payload['total_xp'], 19260);
      expect(payload['coins'], 1240);
      expect(payload['streak_best'], 21);
      expect(payload['activities_total'], 87);
      expect(payload['quests_completed_total'], 30);
      expect(payload['equipped_gear'], ['blade_common']);
      expect(payload['unlocked_gear'], ['blade_common']);
      expect(payload['last_active_date'], '2026-10-12');
      expect(payload['attributes'], {
        'strength': 4200,
        'stamina': 5100,
        'focus': 2600,
        'discipline': 3400,
      });
    });

    test('envia apenas as atividades novas', () {
      final entry = ActivityEntry(
        id: 'act-1',
        kind: ActivityKind.cardio,
        amount: 6.4,
        intensity: Intensity.intense,
        xpAwarded: 320,
        performedAt: DateTime.utc(2026, 10, 12, 7, 30),
        note: 'corrida',
      );

      final payload = buildSyncPayload(
        _state(activities: [entry]),
        newActivities: [entry],
      );

      final activities = payload['activities'] as List;
      expect(activities, hasLength(1));
      final first = activities.first as Map<String, dynamic>;
      expect(first['id'], 'act-1');
      expect(first['kind'], 'cardio');
      expect(first['intensity'], 'intense');
      expect(first['amount'], 6.4);
      expect(first['xp_awarded'], 320);
      expect(first['performed_at'], '2026-10-12T07:30:00.000Z');
      expect(first['note'], 'corrida');
    });

    test('não reenvia atividades já sincronizadas', () {
      final entry = ActivityEntry(
        id: 'act-1',
        kind: ActivityKind.strength,
        amount: 12,
        intensity: Intensity.moderate,
        xpAwarded: 100,
        performedAt: DateTime(2026, 10, 12),
      );

      final payload = buildSyncPayload(
        _state(activities: [entry]),
        newActivities: const [],
      );

      expect(payload['activities'], isEmpty);
    });

    test('serializa missões com período e progresso fracionado', () {
      final payload = buildSyncPayload(
        _state(activities: const []),
        newActivities: const [],
      );

      final quests = payload['quests'] as List;
      expect(quests, hasLength(1));
      final quest = quests.first as Map<String, dynamic>;
      expect(quest['quest_key'], 'daily_cardio_3');
      expect(quest['progress'], 6.4);
      expect(quest['target'], 3.0);
      expect(quest['completed'], true);
      expect(quest['period_start'], '2026-10-12');
    });

    test('data ausente vira null (não quebra o cast no servidor)', () {
      final fresh = Player(
        id: 'u1',
        username: 'hero_abc',
        displayName: 'Eduardo',
        totalXp: 0,
        attributes: const {
          Attribute.strength: 0,
          Attribute.stamina: 0,
          Attribute.focus: 0,
          Attribute.discipline: 0,
        },
        coins: 0,
        gems: 0,
        streakCurrent: 0,
        streakBest: 0,
        activitiesTotal: 0,
        questsCompletedTotal: 0,
        unlockedGear: const [],
        equippedGear: const [],
      );

      final payload = buildSyncPayload(
        _state(activities: const [], player: fresh),
        newActivities: const [],
      );

      expect(payload['last_active_date'], isNull);
    });

    test('lista de conquistas não é mutável pelo chamador', () {
      final payload = buildSyncPayload(
        _state(activities: const []),
        newActivities: const [],
      );

      expect(payload['achievements'], isA<List<String>>());
      expect(
        (payload['achievements'] as List).toSet(),
        {'first_blood', 'streak_7'},
      );
    });
  });
}
