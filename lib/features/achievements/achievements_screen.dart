import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/achievement.dart';
import '../../data/models/game_state.dart';
import '../../providers/game_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/async_game_view.dart';
import '../../shared/widgets/badges.dart';

/// Tela de conquistas, com progresso rumo às que faltam.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Conquistas'),
      ),
      body: AsyncGameView(
        builder: (context, state) {
          final views = ref.watch(achievementsProvider);
          final unlocked = views.where((v) => v.unlocked).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              AppSpacing.huge,
            ),
            children: [
              Text(
                '$unlocked de ${views.length} desbloqueadas',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final view in views)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _AchievementCard(
                    view: view,
                    current: _currentValue(view.achievement, state),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static int _currentValue(Achievement a, GameState state) {
    final player = state.player;
    return switch (a.metric) {
      AchievementMetric.level => player.level,
      AchievementMetric.streak => player.streakBest,
      AchievementMetric.activities => player.activitiesTotal,
      AchievementMetric.quests => player.questsCompletedTotal,
      AchievementMetric.totalXp => player.totalXp,
      AchievementMetric.attribute =>
        a.attribute == null ? 0 : player.xpOf(a.attribute!),
      AchievementMetric.guild => player.guildId == null ? 0 : 1,
    };
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.view, required this.current});

  final AchievementView view;
  final int current;

  @override
  Widget build(BuildContext context) {
    final achievement = view.achievement;
    final fraction = achievement.threshold <= 0
        ? 1.0
        : (current / achievement.threshold).clamp(0.0, 1.0);
    final color = rarityColor(achievement.rarity);

    return AppCard(
      borderColor: view.unlocked
          ? color.withValues(alpha: 0.6)
          : AppColors.outline,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AchievementIcon(achievement: achievement, unlocked: view.unlocked),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: view.unlocked
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (view.unlocked)
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.success,
                      )
                    else
                      RarityBadge(rarity: achievement.rarity, compact: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (view.unlocked)
                  Text(
                    'Desbloqueada',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceRaised,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$current / ${achievement.threshold}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
