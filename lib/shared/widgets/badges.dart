import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/attribute_visuals.dart';
import '../../data/models/achievement.dart';

/// Cores por raridade, reutilizadas em conquistas e itens.
Color rarityColor(Rarity rarity) => switch (rarity) {
  Rarity.common => AppColors.textSecondary,
  Rarity.rare => AppColors.focus,
  Rarity.epic => AppColors.arcane,
  Rarity.legendary => AppColors.legendary,
};

/// Selo de raridade.
class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity, this.compact = false});

  final Rarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(rarity);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        rarity.label.toUpperCase(),
        style: TextStyle(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

/// Ícone circular de conquista, colorido pela raridade e com estado bloqueado.
class AchievementIcon extends StatelessWidget {
  const AchievementIcon({
    super.key,
    required this.achievement,
    required this.unlocked,
    this.size = 44,
  });

  final Achievement achievement;
  final bool unlocked;
  final double size;

  IconData get _icon => switch (achievement.metric) {
    AchievementMetric.level => Icons.trending_up,
    AchievementMetric.streak => Icons.local_fire_department,
    AchievementMetric.activities => Icons.fitness_center,
    AchievementMetric.quests => Icons.flag_outlined,
    AchievementMetric.totalXp => Icons.star_outline,
    AchievementMetric.attribute => achievement.attribute?.icon ?? Icons.bolt,
    AchievementMetric.guild => Icons.groups_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = unlocked
        ? rarityColor(achievement.rarity)
        : AppColors.textMuted;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: unlocked ? 0.16 : 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Icon(_icon, size: size * 0.5, color: color),
    );
  }
}
