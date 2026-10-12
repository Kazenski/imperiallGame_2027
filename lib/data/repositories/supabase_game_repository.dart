import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/domain/activity.dart';
import '../../core/domain/attribute.dart';
import '../models/activity_entry.dart';
import '../models/game_state.dart';
import '../models/guild.dart';
import '../models/player.dart';
import '../models/quest.dart';
import '../seed/quest_catalog.dart';
import 'game_repository.dart';
import 'supabase_payload.dart';

/// Implementação real, via Supabase (v0.2.0).
///
/// * `load()`  -> `rpc('ensure_player')` + `select` em `profiles`, `players`,
///   `activities`, `quest_progress`, `achievements` e `guild_members`.
/// * `save()`  -> `rpc('sync_game_state')`, que grava tudo de forma atômica e
///   **recalcula o nível no servidor** (o XP nunca regride).
/// * `reset()` -> `rpc('reset_progress')`.
///
/// A RLS garante que cada usuário só lê/escreve o próprio progresso; os dados
/// públicos de ranking (`profiles`, `players`) são somente leitura.
class SupabaseGameRepository implements GameRepository {
  SupabaseGameRepository({SupabaseClient? client}) : _clientOverride = client;

  /// Injetável em testes; em produção usa o cliente global.
  final SupabaseClient? _clientOverride;

  /// Ids das atividades já sincronizadas — evita reenviar o histórico inteiro
  /// a cada gravação.
  final Set<String> _syncedActivityIds = <String>{};

  static const Guild _noGuild = Guild(
    id: '',
    name: 'Sem guilda',
    description: 'Você ainda não faz parte de uma guilda.',
    members: [],
    memberLimit: 30,
  );

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Nenhum usuário autenticado.');
    }
    return user.id;
  }

  @override
  Future<GameState> load() async {
    final client = _client;
    final uid = _uid;

    // Cria perfil + player no primeiro acesso (idempotente, no servidor).
    await client.rpc('ensure_player');

    final profile = await client
        .from('profiles')
        .select('username, display_name, guild_id')
        .eq('id', uid)
        .maybeSingle();

    final playerRow = await client
        .from('players')
        .select()
        .eq('id', uid)
        .single();

    final activityRows = await client
        .from('activities')
        .select(
          'id, kind, amount, intensity, xp_awarded, note, performed_at, client_ref',
        )
        .eq('player_id', uid)
        .order('performed_at', ascending: false)
        .limit(300);

    final questRows = await client
        .from('quest_progress')
        .select('quest_key, progress, target, completed, period_start')
        .eq('player_id', uid);

    final achievementRows = await client
        .from('achievements')
        .select('achievement_key')
        .eq('player_id', uid);

    _syncedActivityIds
      ..clear()
      ..addAll([for (final row in activityRows) _activityId(row)]);

    return GameState(
      player: _playerFromRow(uid: uid, profile: profile, row: playerRow),
      activities: [for (final row in activityRows) _activityFromRow(row)],
      quests: _questsFromRows(questRows),
      unlockedAchievements: {
        for (final row in achievementRows) row['achievement_key'] as String,
      },
      guild: await _loadGuild(profile?['guild_id'] as String?),
      questPeriodStart: _today(),
      isDemo: false,
    );
  }

  @override
  Future<GameState> save(GameState state) async {
    final newActivities = [
      for (final activity in state.activities)
        if (!_syncedActivityIds.contains(activity.id)) activity,
    ];

    await _client.rpc(
      'sync_game_state',
      params: {
        'p_state': buildSyncPayload(state, newActivities: newActivities),
      },
    );

    for (final activity in newActivities) {
      _syncedActivityIds.add(activity.id);
    }
    return state;
  }

  @override
  Future<void> reset() async {
    await _client.rpc('reset_progress');
    _syncedActivityIds.clear();
  }

  // -------------------------------------------------------------------
  // Mapeamento banco -> modelos
  // -------------------------------------------------------------------

  Player _playerFromRow({
    required String uid,
    required Map<String, dynamic>? profile,
    required Map<String, dynamic> row,
  }) {
    int number(String key) => (row[key] as num?)?.toInt() ?? 0;

    return Player(
      id: uid,
      username: (profile?['username'] as String?) ?? 'hero',
      displayName: (profile?['display_name'] as String?) ?? 'Aventureiro',
      totalXp: number('xp'),
      attributes: {
        Attribute.strength: number('strength'),
        Attribute.stamina: number('stamina'),
        Attribute.focus: number('focus'),
        Attribute.discipline: number('discipline'),
      },
      coins: number('coins'),
      gems: number('gems'),
      streakCurrent: number('streak_current'),
      streakBest: number('streak_best'),
      activitiesTotal: number('activities_total'),
      questsCompletedTotal: number('quests_completed_total'),
      unlockedGear: _stringList(row['unlocked_gear']),
      equippedGear: _stringList(row['equipped_gear']),
      lastActiveDate: _parseDate(row['last_active_at']),
      guildId: profile?['guild_id'] as String?,
    );
  }

  ActivityEntry _activityFromRow(Map<String, dynamic> row) => ActivityEntry(
    id: _activityId(row),
    kind: ActivityKind.fromName(row['kind'] as String? ?? 'strength'),
    amount: (row['amount'] as num?)?.toDouble() ?? 0,
    intensity: Intensity.fromName(row['intensity'] as String? ?? 'moderate'),
    xpAwarded: (row['xp_awarded'] as num?)?.toInt() ?? 0,
    performedAt:
        DateTime.tryParse(row['performed_at'] as String? ?? '') ??
        DateTime.now(),
    note: row['note'] as String?,
  );

  /// Id estável da atividade: o `client_ref` local quando existe, senão o uuid.
  String _activityId(Map<String, dynamic> row) =>
      (row['client_ref'] as String?) ?? (row['id'] as String);

  List<QuestStatus> _questsFromRows(List<dynamic> rows) {
    // Uma linha por período: fica com a mais recente de cada missão.
    final latest = <String, Map<String, dynamic>>{};
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final key = row['quest_key'] as String;
      final current = latest[key];
      final incoming = '${row['period_start']}';
      if (current == null ||
          '${current['period_start']}'.compareTo(incoming) < 0) {
        latest[key] = row;
      }
    }

    return [
      for (final quest in questCatalog)
        QuestStatus(
          quest: quest,
          progress: (latest[quest.key]?['progress'] as num?)?.toDouble() ?? 0,
          completed: latest[quest.key]?['completed'] == true,
        ),
    ];
  }

  Future<Guild> _loadGuild(String? guildId) async {
    if (guildId == null) return _noGuild;

    final client = _client;
    final guildRow = await client
        .from('guilds')
        .select('id, name, description')
        .eq('id', guildId)
        .maybeSingle();
    if (guildRow == null) return _noGuild;

    final memberRows = await client.rpc(
      'guild_members',
      params: {'p_guild_id': guildId},
    );

    return Guild(
      id: guildId,
      name: (guildRow['name'] as String?) ?? 'Guilda',
      description: (guildRow['description'] as String?) ?? '',
      memberLimit: 30,
      members: [
        for (final raw in (memberRows as List).cast<Map<String, dynamic>>())
          GuildMember(
            id: raw['player_id'] as String,
            displayName: (raw['display_name'] as String?) ?? 'Herói',
            level: (raw['level'] as num?)?.toInt() ?? 1,
            weeklyXp: (raw['weekly_xp'] as num?)?.toInt() ?? 0,
            isCurrentUser: raw['is_me'] == true,
          ),
      ],
    );
  }

  static List<String> _stringList(Object? value) =>
      (value as List?)?.cast<String>() ?? const [];

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
