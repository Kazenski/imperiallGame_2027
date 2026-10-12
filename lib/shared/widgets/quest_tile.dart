import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/attribute_visuals.dart';
import '../../data/models/quest.dart';
import 'app_card.dart';

/// Cartão de missão com barra de progresso e recompensa.
class QuestTile extends StatelessWidget {
  const QuestTile({super.key, required this.status});

  final QuestStatus status;

  @override
  Widget build(BuildContext context) {
    final quest = status.quest;
    final color = quest.kind.color;
    final percent = (status.fraction * 100).round();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: status.completed
          ? AppColors.success.withValues(alpha: 0.6)
          : AppColors.outline,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(
              status.completed ? Icons.check : quest.kind.icon,
              color: status.completed ? AppColors.success : color,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quest.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          decoration: status.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: status.completed
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _RewardTag(xp: quest.rewardXp, coins: quest.rewardCoins),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  quest.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        child: LinearProgressIndicator(
                          value: status.fraction,
                          minHeight: 7,
                          backgroundColor: AppColors.surfaceRaised,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            status.completed ? AppColors.success : color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      status.completed ? 'Concluída' : '$percent%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: status.completed
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(status.progress)} / ${_fmt(quest.target)} '
                  '${quest.kind.unitLabel}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _RewardTag extends StatelessWidget {
  const _RewardTag({required this.xp, required this.coins});

  final int xp;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bolt, size: 13, color: AppColors.gold),
        const SizedBox(width: 2),
        Text(
          '$xp',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.monetization_on, size: 11, color: AppColors.goldDeep),
        const SizedBox(width: 2),
        Text(
          '$coins',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.goldDeep,
          ),
        ),
      ],
    );
  }
}
