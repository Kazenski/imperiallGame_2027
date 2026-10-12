import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/attribute.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/xp_calculator.dart';
import '../../data/models/game_state.dart';
import '../../data/models/gear_item.dart';
import '../../data/models/player.dart';
import '../../data/models/quest.dart';
import '../../providers/game_providers.dart';
import '../../shared/widgets/activity_tile.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/async_game_view.dart';
import '../../shared/widgets/quest_tile.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_chip.dart';
import '../../shared/widgets/hero_avatar.dart';
import '../../shared/widgets/xp_bar.dart';

/// Tela inicial: panorama do dia, atalho para treinar e resumo recente.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AsyncGameView(
        builder: (context, state) => _HomeContent(state: state),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = state.player;
    final xp = ref.watch(xpProgressProvider);
    final titleProgress = ref.watch(levelTitleProgressProvider);
    final equipped = ref.watch(equippedGearProvider);
    final dailyQuests = state.questsOf(QuestPeriod.daily);
    final activities = state.recentActivities.take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.huge,
      ),
      children: [
        _Header(player: player),
        const SizedBox(height: AppSpacing.lg),
        _HeroSummary(
          player: player,
          xp: xp,
          title: titleProgress?.current.title ?? '—',
          equipped: equipped,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.train),
          icon: const Icon(Icons.add),
          label: const Text('Registrar treino'),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(
          title: 'Missões de hoje',
          subtitle: 'Renovadas todos os dias',
        ),
        if (dailyQuests.isEmpty)
          const AppCard(child: Text('Nenhuma missão diária no momento.'))
        else
          ...dailyQuests
              .take(2)
              .map(
                (status) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: QuestTile(status: status),
                ),
              ),
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(
          title: 'Guilda',
          actionLabel: 'Abrir',
          onAction: () => context.go(AppRoutes.guild),
        ),
        _GuildTeaser(state: state),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: 'Atividade recente',
          actionLabel: 'Ver herói',
          onAction: () => context.go(AppRoutes.hero),
        ),
        AppCard(
          child: activities.isEmpty
              ? const Text(
                  'Nenhum treino registrado ainda.',
                  style: TextStyle(color: AppColors.textMuted),
                )
              : Column(
                  children: [
                    for (var i = 0; i < activities.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ActivityTile(entry: activities[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bem-vindo de volta',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                player.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Conquistas',
          onPressed: () => context.push(AppRoutes.achievements),
          icon: const Icon(Icons.emoji_events_outlined),
        ),
        IconButton(
          tooltip: 'Perfil',
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.player,
    required this.xp,
    required this.title,
    required this.equipped,
  });

  final Player player;
  final XpProgress xp;
  final String title;
  final List<GearItem> equipped;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: AppColors.arcaneGradient,
      borderColor: AppColors.arcane.withValues(alpha: 0.6),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              HeroAvatar(player: player, equipped: equipped, size: 88),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.xp(player.totalXp)} XP totais',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XpBar(progress: xp, showLabels: false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final attribute in Attribute.values)
                StatChip(
                  attribute: attribute,
                  value: player.xpOf(attribute),
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 18,
                color: AppColors.legendary,
              ),
              const SizedBox(width: 6),
              Text(
                'Sequência de ${player.streakCurrent} dias',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Recorde: ${player.streakBest}',
                style: const TextStyle(
                  fontSize: 12,
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

class _GuildTeaser extends StatelessWidget {
  const _GuildTeaser({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final guild = state.guild;
    final rank = guild.currentUserRank;

    return AppCard(
      onTap: () => context.go(AppRoutes.guild),
      child: Row(
        children: [
          const Icon(Icons.groups, color: AppColors.gold, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guild.name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${guild.memberCount} membros · '
                  '${Formatters.xp(guild.weeklyXp)} XP na semana',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (rank != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                '#$rank',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
