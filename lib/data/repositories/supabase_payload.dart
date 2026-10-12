import '../models/activity_entry.dart';
import '../models/game_state.dart';

/// Serializa o [GameState] no formato aceito pela RPC `sync_game_state`.
///
/// Função **pura** (não toca no Supabase), para ser testada isoladamente.
/// O histórico só envia as atividades novas ([newActivities]); o resto do
/// estado é pequeno e vai inteiro.
Map<String, dynamic> buildSyncPayload(
  GameState state, {
  required Iterable<ActivityEntry> newActivities,
}) {
  final player = state.player;

  return {
    'display_name': player.displayName,
    'total_xp': player.totalXp,
    'attributes': {
      for (final entry in player.attributes.entries) entry.key.name: entry.value,
    },
    'coins': player.coins,
    'gems': player.gems,
    'streak_current': player.streakCurrent,
    'streak_best': player.streakBest,
    'activities_total': player.activitiesTotal,
    'quests_completed_total': player.questsCompletedTotal,
    'unlocked_gear': player.unlockedGear,
    'equipped_gear': player.equippedGear,
    'last_active_date': _isoDay(player.lastActiveDate),
    'activities': [
      for (final activity in newActivities)
        {
          'id': activity.id,
          'kind': activity.kind.name,
          'amount': activity.amount,
          'intensity': activity.intensity.name,
          'xp_awarded': activity.xpAwarded,
          'note': activity.note,
          'performed_at': activity.performedAt.toUtc().toIso8601String(),
        },
    ],
    'quests': [
      for (final status in state.quests)
        {
          'quest_key': status.quest.key,
          'progress': status.progress,
          'target': status.quest.target,
          'completed': status.completed,
          'period_start': _isoDay(state.questPeriodStart),
        },
    ],
    'achievements': state.unlockedAchievements.toList(growable: false),
  };
}

/// Data no formato `YYYY-MM-DD` (o banco guarda `date`, sem fuso).
String? _isoDay(DateTime? date) {
  if (date == null) return null;
  final day = DateTime(date.year, date.month, date.day);
  final month = day.month.toString().padLeft(2, '0');
  final dayOfMonth = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$dayOfMonth';
}
