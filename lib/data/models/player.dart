import '../../core/domain/attribute.dart';
import '../../core/utils/xp_calculator.dart';

/// Estado de jogo do jogador.
///
/// Imutável: qualquer mudança gera uma nova instância via [copyWith].
/// O `level` é **derivado** do XP total — assim nunca fica inconsistente.
class Player {
  const Player({
    required this.id,
    required this.username,
    required this.displayName,
    required this.totalXp,
    required this.attributes,
    required this.coins,
    required this.gems,
    required this.streakCurrent,
    required this.streakBest,
    required this.activitiesTotal,
    required this.questsCompletedTotal,
    required this.unlockedGear,
    required this.equippedGear,
    this.lastActiveDate,
    this.guildId,
  });

  final String id;
  final String username;
  final String displayName;

  /// XP acumulado (somente cresce).
  final int totalXp;

  /// XP acumulado por atributo (soma, não gastável).
  final Map<Attribute, int> attributes;

  final int coins;
  final int gems;
  final int streakCurrent;
  final int streakBest;
  final int activitiesTotal;
  final int questsCompletedTotal;

  /// Chaves dos itens já desbloqueados.
  final List<String> unlockedGear;

  /// Chaves dos itens equipados (no máximo 1 por slot).
  final List<String> equippedGear;

  /// Data (só o dia) da última atividade válida.
  final DateTime? lastActiveDate;

  final String? guildId;

  /// Nível derivado do XP — nunca armazenado.
  int get level => XpCalculator.levelForXp(totalXp);

  XpProgress get progress => XpCalculator.progress(totalXp);

  int xpOf(Attribute attribute) => attributes[attribute] ?? 0;

  /// Soma de todos os atributos — usada no ranking de guilda ("poder").
  int get power => attributes.values.fold<int>(0, (sum, value) => sum + value);

  /// Todos os atributos, sempre com as 4 chaves presentes.
  Map<Attribute, int> get completeAttributes => {
    for (final attribute in Attribute.values) attribute: xpOf(attribute),
  };

  /// Este jogador já treinou hoje?
  bool get isActiveToday {
    final last = lastActiveDate;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  Player copyWith({
    String? username,
    String? displayName,
    int? totalXp,
    Map<Attribute, int>? attributes,
    int? coins,
    int? gems,
    int? streakCurrent,
    int? streakBest,
    int? activitiesTotal,
    int? questsCompletedTotal,
    List<String>? unlockedGear,
    List<String>? equippedGear,
    DateTime? lastActiveDate,
    String? guildId,
    bool clearGuild = false,
  }) {
    return Player(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      totalXp: totalXp ?? this.totalXp,
      attributes: attributes ?? this.attributes,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      streakCurrent: streakCurrent ?? this.streakCurrent,
      streakBest: streakBest ?? this.streakBest,
      activitiesTotal: activitiesTotal ?? this.activitiesTotal,
      questsCompletedTotal: questsCompletedTotal ?? this.questsCompletedTotal,
      unlockedGear: unlockedGear ?? this.unlockedGear,
      equippedGear: equippedGear ?? this.equippedGear,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      guildId: clearGuild ? null : (guildId ?? this.guildId),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'total_xp': totalXp,
    'attributes': {
      for (final entry in attributes.entries) entry.key.name: entry.value,
    },
    'coins': coins,
    'gems': gems,
    'streak_current': streakCurrent,
    'streak_best': streakBest,
    'activities_total': activitiesTotal,
    'quests_completed_total': questsCompletedTotal,
    'unlocked_gear': unlockedGear,
    'equipped_gear': equippedGear,
    'last_active_date': lastActiveDate?.toIso8601String(),
    'guild_id': guildId,
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    final rawAttributes = (json['attributes'] as Map?) ?? const {};
    return Player(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'jogador',
      displayName: json['display_name'] as String? ?? 'Aventureiro',
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      attributes: {
        for (final attribute in Attribute.values)
          attribute: (rawAttributes[attribute.name] as num?)?.toInt() ?? 0,
      },
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
      streakCurrent: (json['streak_current'] as num?)?.toInt() ?? 0,
      streakBest: (json['streak_best'] as num?)?.toInt() ?? 0,
      activitiesTotal: (json['activities_total'] as num?)?.toInt() ?? 0,
      questsCompletedTotal:
          (json['quests_completed_total'] as num?)?.toInt() ?? 0,
      unlockedGear:
          (json['unlocked_gear'] as List?)?.cast<String>() ?? const [],
      equippedGear:
          (json['equipped_gear'] as List?)?.cast<String>() ?? const [],
      lastActiveDate: json['last_active_date'] == null
          ? null
          : DateTime.tryParse(json['last_active_date'] as String),
      guildId: json['guild_id'] as String?,
    );
  }
}
