import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/xp_calculator.dart';

/// Barra de progresso de XP do nível atual.
class XpBar extends StatelessWidget {
  const XpBar({
    super.key,
    required this.progress,
    this.height = 12,
    this.showLabels = true,
  });

  final XpProgress progress;
  final double height;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: Stack(
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: height,
                    width: constraints.maxWidth * progress.fraction,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nível ${progress.level}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              Text(
                progress.isMaxLevel
                    ? 'Nível máximo'
                    : '${Formatters.xp(progress.xpIntoLevel)} / '
                          '${Formatters.xp(progress.xpToNextLevel)} XP',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
