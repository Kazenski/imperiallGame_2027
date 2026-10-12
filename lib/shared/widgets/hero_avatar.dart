import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/domain/attribute.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/attribute_visuals.dart';
import '../../data/models/achievement.dart';
import '../../data/models/gear_item.dart';
import '../../data/models/player.dart';

/// Avatar do herói, **composto em camadas** como descrito em `docs/GAME_DESIGN.md`.
///
/// Enquanto os PNGs de arte não existem, cada camada é desenhada
/// proceduralmente (gradiente + ícones). Quando a arte chegar, basta trocar
/// cada camada por um `Image.asset` — a estrutura de composição já está pronta.
///
///   camada 1: corpo      -> porte/tier conforme o nível
///   camada 2: aura       -> cor do atributo dominante
///   camada 3: moldura    -> raridade do equipamento mais raro
///   camada 4: equipamento -> ícones dos itens equipados
class HeroAvatar extends StatelessWidget {
  const HeroAvatar({
    super.key,
    required this.player,
    required this.equipped,
    this.size = 180,
  });

  final Player? player;
  final List<GearItem> equipped;
  final double size;

  /// Tier de corpo por nível (4 tiers visuais).
  int get _bodyTier {
    final level = player?.level ?? 1;
    if (level >= 36) return 4;
    if (level >= 16) return 3;
    if (level >= 6) return 2;
    return 1;
  }

  IconData get _bodyIcon => switch (_bodyTier) {
    4 => Icons.shield_moon,
    3 => Icons.shield,
    2 => Icons.sports_martial_arts,
    _ => Icons.person_outline,
  };

  /// Atributo dominante define a aura.
  Attribute get _dominantAttribute {
    final attributes = player?.completeAttributes;
    if (attributes == null || attributes.isEmpty) return Attribute.discipline;

    var best = Attribute.discipline;
    var bestValue = -1;
    for (final entry in attributes.entries) {
      if (entry.value > bestValue) {
        best = entry.key;
        bestValue = entry.value;
      }
    }
    return best;
  }

  Rarity get _frameRarity {
    if (equipped.isEmpty) return Rarity.common;
    const order = [Rarity.common, Rarity.rare, Rarity.epic, Rarity.legendary];
    return equipped
        .map((item) => item.rarity)
        .reduce((a, b) => order.indexOf(a) >= order.indexOf(b) ? a : b);
  }

  Color get _frameColor => switch (_frameRarity) {
    Rarity.common => AppColors.outline,
    Rarity.rare => AppColors.focus,
    Rarity.epic => AppColors.arcane,
    Rarity.legendary => AppColors.legendary,
  };

  static const Map<GearSlot, IconData> _slotIcons = {
    GearSlot.weapon: Icons.gavel,
    GearSlot.armor: Icons.shield_outlined,
    GearSlot.boots: Icons.hiking,
    GearSlot.trinket: Icons.auto_awesome,
  };

  @override
  Widget build(BuildContext context) {
    final auraColor = _dominantAttribute.color;
    final innerSize = size * 0.68;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Camada 2 — aura
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  auraColor.withValues(alpha: 0.35),
                  auraColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          // Camada 3 — moldura
          Container(
            width: size * 0.86,
            height: size * 0.86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _frameColor, width: 2.5),
              color: AppColors.surfaceRaised,
              boxShadow: [
                BoxShadow(
                  color: _frameColor.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Camada 1 — corpo
          Container(
            width: innerSize,
            height: innerSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.arcaneGradient,
            ),
            child: Icon(
              _bodyIcon,
              size: innerSize * 0.5,
              color: AppColors.textPrimary,
            ),
          ),

          // Camada 4 — equipamento (ícones por slot)
          ..._equippedBadges(),

          // Selo de nível
          Positioned(
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                'NÍVEL ${player?.level ?? 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: Color(0xFF2A1A00),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _equippedBadges() {
    if (equipped.isEmpty) return const [];

    final radius = size * 0.42;

    return [
      for (var i = 0; i < equipped.length; i++)
        _badge(equipped[i], i, equipped.length, radius),
    ];
  }

  Widget _badge(GearItem item, int index, int total, double radius) {
    // Distribui os ícones ao redor do círculo, começando no topo.
    final angle = -math.pi / 2 + (index * 2 * math.pi / total);
    final dx = radius * math.cos(angle);
    final dy = radius * math.sin(angle);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: _rarityColor(item.rarity), width: 1.5),
        ),
        child: Icon(
          _slotIcons[item.slot] ?? Icons.auto_awesome,
          size: 15,
          color: _rarityColor(item.rarity),
        ),
      ),
    );
  }

  static Color _rarityColor(Rarity rarity) => switch (rarity) {
    Rarity.common => AppColors.textSecondary,
    Rarity.rare => AppColors.focus,
    Rarity.epic => AppColors.arcane,
    Rarity.legendary => AppColors.legendary,
  };
}

/// Legenda compacta dos itens equipados (usada abaixo do avatar).
class GearLegend extends StatelessWidget {
  const GearLegend({super.key, required this.items});

  final List<GearItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'Nenhum equipamento equipado',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: HeroAvatar._rarityColor(item.rarity)
                    .withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: HeroAvatar._rarityColor(item.rarity),
              ),
            ),
          ),
      ],
    );
  }
}
