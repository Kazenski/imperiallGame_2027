import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/attribute.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/gear_item.dart';
import '../../data/models/player.dart';
import '../../data/seed/gear_catalog.dart';
import '../../providers/game_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/async_game_view.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/hero_avatar.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_chip.dart';
import '../../shared/widgets/xp_bar.dart';

/// Tela do personagem: avatar em camadas, atributos e equipamentos.
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AsyncGameView(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.huge,
          ),
          children: [
            Center(
              child: HeroAvatar(
                player: state.player,
                equipped: ref.watch(equippedGearProvider),
                size: 210,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(child: GearLegend(items: ref.watch(equippedGearProvider))),
            const SizedBox(height: AppSpacing.xl),
            _IdentityCard(player: state.player),
            const SizedBox(height: AppSpacing.xl),

            const SectionHeader(
              title: 'Atributos',
              subtitle: 'Cada atividade alimenta o atributo correspondente',
            ),
            _AttributesCard(player: state.player),
            const SizedBox(height: AppSpacing.xl),

            const SectionHeader(
              title: 'Equipamento',
              subtitle: 'Desbloqueie por nível e atributo; toque para equipar',
            ),
            for (final slot in GearSlot.values) ...[
              _SlotSection(slot: slot, player: state.player),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends ConsumerWidget {
  const _IdentityCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleProgress = ref.watch(levelTitleProgressProvider);
    final power = player.power;

    return AppCard(
      gradient: AppColors.arcaneGradient,
      borderColor: AppColors.arcane.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  player.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '@${player.username}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${titleProgress?.current.title ?? '—'} · Nível ${player.level}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
          if (titleProgress?.current.description != null) ...[
            const SizedBox(height: 4),
            Text(
              titleProgress!.current.description,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          XpBar(progress: player.progress),
          if (titleProgress != null && !titleProgress.isMaxTitle) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Próximo título: ${titleProgress.next!.title} em '
              '${titleProgress.levelsToNext} nível(is).',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _MiniStat(
                icon: Icons.local_fire_department,
                label: 'Sequência',
                value: '${player.streakCurrent} d',
              ),
              _MiniStat(
                icon: Icons.fitness_center,
                label: 'Treinos',
                value: '${player.activitiesTotal}',
              ),
              _MiniStat(
                icon: Icons.bolt,
                label: 'Poder',
                value: Formatters.xp(power),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AttributesCard extends StatelessWidget {
  const _AttributesCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final values = player.completeAttributes;
    final maxValue = values.values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );

    return AppCard(
      child: Column(
        children: [
          for (final attribute in Attribute.values)
            StatRow(
              attribute: attribute,
              value: player.xpOf(attribute),
              maxValue: maxValue,
            ),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              const Icon(Icons.insights, size: 18, color: AppColors.gold),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Poder total (soma dos atributos)',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Text(
                Formatters.xp(player.power),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotSection extends ConsumerWidget {
  const _SlotSection({required this.slot, required this.player});

  final GearSlot slot;
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = gearBySlot(slot);
    final equippedKey = player.equippedGear.firstWhere(
      (key) => gearByKey(key)?.slot == slot,
      orElse: () => '',
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                gearSlotIcon(slot),
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                slot.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items)
            _GearRow(
              item: item,
              player: player,
              equipped: item.key == equippedKey,
            ),
        ],
      ),
    );
  }
}

class _GearRow extends ConsumerWidget {
  const _GearRow({
    required this.item,
    required this.player,
    required this.equipped,
  });

  final GearItem item;
  final Player player;
  final bool equipped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = item.isUnlockedFor(player);
    final color = rarityColor(item.rarity);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(
              gearSlotIcon(item.slot),
              size: 18,
              color: unlocked ? color : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: unlocked
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    RarityBadge(rarity: item.rarity, compact: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  unlocked ? item.description : _lockLabel(item, player),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: LinearProgressIndicator(
                      value: item.progressFor(player),
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceRaised,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (equipped)
            TextButton(
              onPressed: () async {
                await ref
                    .read(gameControllerProvider.notifier)
                    .unequip(item.slot);
              },
              child: const Text('Desequipar'),
            )
          else
            FilledButton.tonal(
              onPressed: unlocked
                  ? () async {
                      final feedback = await ref
                          .read(gameControllerProvider.notifier)
                          .equip(item.key);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(feedback.message)),
                        );
                      }
                    }
                  : null,
              child: const Text('Equipar'),
            ),
        ],
      ),
    );
  }

  static String _lockLabel(GearItem item, Player player) {
    final parts = <String>[];
    if (player.level < item.requiredLevel) {
      parts.add('Nível ${item.requiredLevel}');
    }
    final attribute = item.requiredAttribute;
    if (attribute != null && player.xpOf(attribute) < item.attributeThreshold) {
      parts.add('${attribute.label} ${item.attributeThreshold}');
    }
    return parts.isEmpty ? 'Bloqueado' : 'Requer: ${parts.join(' · ')}';
  }
}

/// Ícone de cada slot de equipamento (visual, não domínio).
IconData gearSlotIcon(GearSlot slot) => switch (slot) {
  GearSlot.weapon => Icons.gavel,
  GearSlot.armor => Icons.shield_outlined,
  GearSlot.boots => Icons.hiking,
  GearSlot.trinket => Icons.auto_awesome,
};
