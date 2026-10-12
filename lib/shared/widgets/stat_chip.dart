import 'package:flutter/material.dart';

import '../../core/domain/attribute.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/attribute_visuals.dart';
import '../../core/utils/formatters.dart';

/// Chip de atributo: ícone colorido + valor.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.attribute,
    required this.value,
    this.compact = false,
  });

  final Attribute attribute;
  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = attribute.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 6 : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(attribute.icon, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 6),
          if (!compact) ...[
            Text(
              attribute.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            Formatters.number(value),
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de um atributo com barra proporcional (usado na tela do herói).
class StatRow extends StatelessWidget {
  const StatRow({
    super.key,
    required this.attribute,
    required this.value,
    required this.maxValue,
  });

  final Attribute attribute;
  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final color = attribute.color;
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(attribute.icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      attribute.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      Formatters.number(value),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceRaised,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
