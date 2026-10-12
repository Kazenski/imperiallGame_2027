import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import 'auth_providers.dart';

/// Roteador reativo à sessão.
///
/// É reconstruído quando o usuário entra ou sai — o que reinicia a navegação
/// (esperado nessas transições). Em modo demonstração não há login.
final appRouterProvider = Provider<GoRouter>((ref) {
  final enableAuth = ref.watch(authEnabledProvider);
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return createAppRouter(
    enableAuth: enableAuth,
    isAuthenticated: isAuthenticated,
  );
});
