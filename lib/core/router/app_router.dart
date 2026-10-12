import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/game_state.dart';
import '../../features/achievements/achievements_screen.dart';
import '../../features/character/character_screen.dart';
import '../../features/guild/guild_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/quests/quests_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/workout/log_activity_screen.dart';
import '../../features/workout/reward_screen.dart';

/// Nomes das rotas, centralizados para evitar strings soltas na UI.
class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const train = '/train';
  static const hero = '/hero';
  static const quests = '/quests';
  static const guild = '/guild';
  static const achievements = '/achievements';
  static const profile = '/profile';
  static const reward = '/reward';
}

/// Roteador do app.
///
/// As cinco abas vivem dentro de um `StatefulShellRoute` (cada uma mantém
/// o próprio histórico). Telas que devem cobrir a barra de navegação
/// (como a recompensa) ficam fora do shell.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.train,
                builder: (context, state) => const LogActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.hero,
                builder: (context, state) => const CharacterScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.quests,
                builder: (context, state) => const QuestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.guild,
                builder: (context, state) => const GuildScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.reward,
        builder: (context, state) {
          final result = state.extra;
          if (result is! WorkoutResult) {
            return const RewardScreen(result: null);
          }
          return RewardScreen(result: result);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Rota não encontrada: ${state.uri}')),
    ),
  );
}
