import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/router_providers.dart';

/// Raiz do app Imperiall Game.
///
/// O `GoRouter` vem de `appRouterProvider`, que se reconstrói quando a sessão
/// muda (login/logout). Dentro de uma sessão ele é estável, preservando o
/// histórico das abas.
class ImperiallGameApp extends ConsumerStatefulWidget {
  const ImperiallGameApp({super.key});

  @override
  ConsumerState<ImperiallGameApp> createState() => _ImperiallGameAppState();
}

class _ImperiallGameAppState extends ConsumerState<ImperiallGameApp> {
  @override
  void initState() {
    super.initState();
    // Habilita formatação de datas em pt-BR (ver `core/utils/formatters.dart`).
    initializeDateFormatting('pt_BR');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        // Trava o tamanho de fonte para o layout não quebrar em telas grandes.
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
