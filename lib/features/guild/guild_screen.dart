import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/guild.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/async_game_view.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';

/// Tela da guilda: resumo e ranking semanal.
class GuildScreen extends ConsumerWidget {
  const GuildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Guilda'),
      ),
      body: AsyncGameView(
        builder: (context, state) {
          final guild = state.guild;

          // Ainda não há guilda (jogador novo no modo conectado).
          if (guild.id.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Sem guilda ainda',
              message:
                  'Criar e entrar em guildas chega em breve. '
                  'Por enquanto, treine e suba de nível!',
            );
          }

          final ranking = guild.ranking;
          final topXp = ranking.isEmpty ? 1 : ranking.first.weeklyXp;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              AppSpacing.huge,
            ),
            children: [
              _GuildHeader(guild: guild),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                title: 'Ranking da semana',
                subtitle: 'XP somado nos últimos 7 dias',
              ),
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < ranking.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _RankRow(
                        position: i + 1,
                        member: ranking[i],
                        topXp: topXp,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GuildHeader extends StatelessWidget {
  const _GuildHeader({required this.guild});

  final Guild guild;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: AppColors.arcaneGradient,
      borderColor: AppColors.arcane.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: AppColors.gold, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  guild.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (guild.currentUserRank != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    'Sua posição: #${guild.currentUserRank}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            guild.description,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _HeaderStat(
                icon: Icons.people_alt_outlined,
                label: 'Membros',
                value: '${guild.memberCount}/${guild.memberLimit}',
              ),
              _HeaderStat(
                icon: Icons.bolt,
                label: 'XP na semana',
                value: Formatters.xp(guild.weeklyXp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
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
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.position,
    required this.member,
    required this.topXp,
  });

  final int position;
  final GuildMember member;
  final int topXp;

  Color get _positionColor => switch (position) {
    1 => AppColors.gold,
    2 => AppColors.textSecondary,
    3 => AppColors.goldDeep,
    _ => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final fraction = topXp <= 0
        ? 0.0
        : (member.weeklyXp / topXp).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: member.isCurrentUser
            ? AppColors.gold.withValues(alpha: 0.08)
            : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$position',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: _positionColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: member.isCurrentUser
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: member.isCurrentUser
                            ? AppColors.gold
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (member.isCurrentUser) ...[
                      const SizedBox(width: 6),
                      const Text(
                        '(você)',
                        style: TextStyle(fontSize: 11, color: AppColors.gold),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${Formatters.xp(member.weeklyXp)} XP',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceRaised,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      member.isCurrentUser ? AppColors.gold : AppColors.arcane,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nível ${member.level}',
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
}
