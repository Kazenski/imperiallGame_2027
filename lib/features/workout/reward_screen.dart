import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/game_state.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/section_header.dart';

/// Tela de recompensa: o "clímax" de registrar um treino.
///
/// Recebe o [WorkoutResult] via `extra` da rota `/reward`.
class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key, required this.result});

  final WorkoutResult? result;

  @override
  Widget build(BuildContext context) {
    final outcome = result;
    if (outcome == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recompensa')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.help_outline,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Nenhum resultado para mostrar.'),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.xl,
              AppSpacing.screenPadding,
              AppSpacing.huge,
            ),
            children: [
              _BigXpBadge(result: outcome),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Text(
                  '${outcome.entry.kind.label} · ${outcome.entry.amountLabel}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              if (outcome.award.didLevelUp) ...[
                const _LevelUpBanner(),
                const SizedBox(height: AppSpacing.lg),
              ],

              if (outcome.streakChestOpened) ...[
                _InfoCard(
                  icon: Icons.card_giftcard,
                  color: AppColors.gold,
                  title: 'Baú de sequência aberto!',
                  message:
                      'Você completou mais um ciclo de sequência e ganhou '
                      '${Formatters.xp(outcome.coinsGained)} moedas.',
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (outcome.completedQuests.isNotEmpty) ...[
                const SectionHeader(title: 'Missões concluídas'),
                for (final quest in outcome.completedQuests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _InfoCard(
                      icon: Icons.flag,
                      color: AppColors.success,
                      title: quest.title,
                      message:
                          'Recompensa: +${quest.rewardXp} XP '
                          'e ${quest.rewardCoins} moedas.',
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (outcome.unlockedAchievements.isNotEmpty) ...[
                const SectionHeader(title: 'Novas conquistas'),
                for (final achievement in outcome.unlockedAchievements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Row(
                        children: [
                          AchievementIcon(
                            achievement: achievement,
                            unlocked: true,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  achievement.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  achievement.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RarityBadge(
                            rarity: achievement.rarity,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (outcome.unlockedGear.isNotEmpty) ...[
                const SectionHeader(title: 'Equipamento desbloqueado'),
                for (final item in outcome.unlockedGear)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _InfoCard(
                      icon: Icons.shield_outlined,
                      color: rarityColor(item.rarity),
                      title: item.name,
                      message:
                          '${item.slot.label} · ${item.rarity.label}. '
                          'Equipe na aba Herói.',
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (!outcome.hasRewardsBeyondXp && !outcome.award.didLevelUp) ...[
                const Text(
                  'Continue assim: constância bate intensidade.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              FilledButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigXpBadge extends StatelessWidget {
  const _BigXpBadge({required this.result});

  final WorkoutResult result;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 190,
        height: 190,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.arcaneGradient,
          border: Border.all(color: AppColors.gold, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'XP GANHO',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '+${Formatters.xp(result.award.totalXp)}',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: AppColors.gold,
              ),
            ),
            if (result.coinsGained > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: 16,
                    color: AppColors.goldDeep,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${result.coinsGained}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldDeep,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LevelUpBanner extends StatelessWidget {
  const _LevelUpBanner();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: AppColors.goldGradient,
      borderColor: AppColors.gold,
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFF2A1A00)),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Subiu de nível! Seu personagem evoluiu.',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF2A1A00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12.5,
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
