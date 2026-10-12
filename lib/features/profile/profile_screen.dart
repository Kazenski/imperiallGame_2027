import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/player.dart';
import '../../providers/auth_providers.dart';
import '../../providers/game_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/async_game_view.dart';
import '../../shared/widgets/section_header.dart';

/// Perfil e configurações. Em modo demo, permite zerar o progresso.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Perfil'),
      ),
      body: AsyncGameView(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.huge,
          ),
          children: [
            _IdentityCard(player: state.player),
            const SizedBox(height: AppSpacing.xl),

            const SectionHeader(title: 'Resumo'),
            AppCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.local_fire_department,
                    label: 'Sequência atual',
                    value: '${state.player.streakCurrent} dias',
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.emoji_events_outlined,
                    label: 'Melhor sequência',
                    value: '${state.player.streakBest} dias',
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.fitness_center,
                    label: 'Treinos registrados',
                    value: '${state.player.activitiesTotal}',
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.flag_outlined,
                    label: 'Missões concluídas',
                    value: '${state.player.questsCompletedTotal}',
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.trending_up,
                    label: 'XP médio (7 dias)',
                    value: Formatters.xp(state.averageXpPerDay()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Conquistas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.achievements),
            ),
            const SizedBox(height: AppSpacing.xl),

            if (state.isDemo) ...[
              const SectionHeader(title: 'Modo demonstração'),
              AppCard(
                borderColor: AppColors.warning.withValues(alpha: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.science_outlined,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Dados mockados',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Este progresso é local e some ao fechar o app. '
                      'Nenhuma credencial é necessária para testar. '
                      'Ao conectar o Supabase, os dados passam a ser '
                      'persistidos com autenticação e RLS.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () => _confirmReset(context, ref),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Zerar progresso'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ] else ...[
              const SectionHeader(title: 'Conta'),
              AppCard(
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.alternate_email,
                      label: 'E-mail',
                      value: ref
                              .watch(supabaseClientProvider)
                              ?.auth
                              .currentUser
                              ?.email ??
                          '—',
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.logout,
                        color: AppColors.danger,
                      ),
                      title: const Text(
                        'Sair da conta',
                        style: TextStyle(color: AppColors.danger),
                      ),
                      onTap: () => _confirmSignOut(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            const SectionHeader(title: 'Sobre'),
            AppCard(
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Aplicativo',
                    value: AppConfig.appName,
                    icon: Icons.sports_martial_arts,
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    label: 'Versão',
                    value: AppConfig.appVersion,
                    icon: Icons.tag,
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    label: 'Ambiente',
                    value: AppConfig.env,
                    icon: Icons.dns_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Zerar progresso?'),
        content: const Text(
          'Todo o progresso da demonstração será apagado e o estado inicial '
          'será restaurado. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Zerar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(gameControllerProvider.notifier).resetProgress();
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sair da conta?'),
        content: const Text(
          'Seu progresso fica salvo no servidor. Você pode entrar de novo '
          'quando quiser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(authControllerProvider)?.signOut();
    // O roteador reage à sessão e leva de volta para a tela de login.
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.surfaceRaised,
            child: Text(
              player.displayName.isNotEmpty
                  ? player.displayName.characters.first.toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '@${player.username} · Nível ${player.level}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _Currency(
                      icon: Icons.monetization_on,
                      color: AppColors.goldDeep,
                      value: player.coins,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _Currency(
                      icon: Icons.diamond,
                      color: AppColors.arcane,
                      value: player.gems,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Currency extends StatelessWidget {
  const _Currency({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          Formatters.xp(value),
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
