import '../../core/domain/activity.dart';
import '../../core/domain/attribute.dart';
import '../models/activity_entry.dart';
import '../models/game_state.dart';
import '../models/guild.dart';
import '../models/player.dart';
import '../models/quest.dart';
import 'quest_catalog.dart';

/// Dados de demonstração — permitem abrir o app sem backend nenhum.
///
/// Substituídos por dados reais quando `AppConfig.useDemoData` for `false`.
GameState buildDemoGameState({DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final yesterday = today.subtract(const Duration(days: 1));

  const player = Player(
    id: 'demo-player',
    username: 'kazenski',
    displayName: 'Eduardo',
    totalXp: 19260,
    attributes: {
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
    questsCompletedTotal: 34,
    unlockedGear: [
      'wooden_sword',
      'leather_vest',
      'worn_boots',
      'iron_blade',
      'chain_mail',
      'focus_stone',
    ],
    equippedGear: ['iron_blade', 'chain_mail', 'worn_boots', 'focus_stone'],
    guildId: 'guild-demo',
  );

  final activities = <ActivityEntry>[
    ActivityEntry(
      id: 'act-1',
      kind: ActivityKind.strength,
      amount: 16,
      intensity: Intensity.intense,
      xpAwarded: 335,
      performedAt: yesterday.add(const Duration(hours: 18)),
      note: 'Treino de peito e costas',
    ),
    ActivityEntry(
      id: 'act-2',
      kind: ActivityKind.mobility,
      amount: 20,
      intensity: Intensity.moderate,
      xpAwarded: 120,
      performedAt: yesterday.add(const Duration(hours: 7)),
    ),
    ActivityEntry(
      id: 'act-3',
      kind: ActivityKind.cardio,
      amount: 6.4,
      intensity: Intensity.moderate,
      xpAwarded: 51,
      performedAt: today.subtract(const Duration(days: 2, hours: 1)),
      note: 'Corrida no parque',
    ),
    ActivityEntry(
      id: 'act-4',
      kind: ActivityKind.strength,
      amount: 14,
      intensity: Intensity.moderate,
      xpAwarded: 210,
      performedAt: today.subtract(const Duration(days: 3)),
    ),
    ActivityEntry(
      id: 'act-5',
      kind: ActivityKind.steps,
      amount: 11,
      intensity: Intensity.moderate,
      xpAwarded: 440,
      performedAt: today.subtract(const Duration(days: 3, hours: 2)),
    ),
    ActivityEntry(
      id: 'act-6',
      kind: ActivityKind.recovery,
      amount: 25,
      intensity: Intensity.light,
      xpAwarded: 80,
      performedAt: today.subtract(const Duration(days: 4)),
    ),
    ActivityEntry(
      id: 'act-7',
      kind: ActivityKind.nutrition,
      amount: 3,
      intensity: Intensity.moderate,
      xpAwarded: 30,
      performedAt: today.subtract(const Duration(days: 5)),
    ),
  ];

  final quests = _buildDemoQuestProgress();

  const guild = Guild(
    id: 'guild-demo',
    name: 'Guardiões do Amanhecer',
    description: 'Treino consistente, sem drama. Progresso coletivo na semana.',
    memberLimit: 30,
    members: [
      GuildMember(id: 'm1', displayName: 'Larissa', level: 24, weeklyXp: 4820),
      GuildMember(id: 'm2', displayName: 'Rafael', level: 19, weeklyXp: 3960),
      GuildMember(
        id: 'demo-player',
        displayName: 'Eduardo',
        level: 12,
        weeklyXp: 2710,
        isCurrentUser: true,
      ),
      GuildMember(id: 'm3', displayName: 'Bruna', level: 15, weeklyXp: 2480),
      GuildMember(id: 'm4', displayName: 'Caio', level: 11, weeklyXp: 1930),
      GuildMember(id: 'm5', displayName: 'Marina', level: 9, weeklyXp: 1240),
      GuildMember(id: 'm6', displayName: 'Thiago', level: 7, weeklyXp: 880),
      GuildMember(id: 'm7', displayName: 'Júlia', level: 5, weeklyXp: 410),
    ],
  );

  return GameState(
    player: player,
    activities: activities,
    quests: quests,
    unlockedAchievements: const {
      'first_workout',
      'streak_3',
      'streak_7',
      'level_5',
      'level_10',
      'strength_500',
      'stamina_1000',
      'quests_10',
      'join_guild',
    },
    guild: guild,
    questPeriodStart: today,
    isDemo: true,
  );
}

/// Progresso parcial nas missões do dia/semana, para a UI não abrir "zerada".
List<QuestStatus> _buildDemoQuestProgress() {
  const progressByKey = <String, double>{
    'daily_strength_12': 6,
    'daily_cardio_3': 1.4,
    'daily_mobility_15': 15,
    'weekly_strength_40': 30,
    'weekly_cardio_20': 6.4,
    'weekly_recovery_60': 25,
    'weekly_steps_35': 11,
    'weekly_nutrition_10': 3,
    'epic_cardio_100': 41.8,
  };

  const completedKeys = {'daily_mobility_15'};

  return questCatalog.map((quest) {
    final progress = progressByKey[quest.key] ?? 0;
    return QuestStatus(
      quest: quest,
      progress: progress,
      completed: completedKeys.contains(quest.key),
    );
  }).toList();
}
