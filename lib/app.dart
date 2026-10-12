import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Raiz do app Imperiall Game.
///
/// Mantém o `GoRouter` em um campo `late final` para que ele seja criado **uma
/// vez só** — recriar o roteador a cada build perderia o histórico das abas.
class ImperiallGameApp extends StatefulWidget {
  const ImperiallGameApp({super.key});

  @override
  State<ImperiallGameApp> createState() => _ImperiallGameAppState();
}

class _ImperiallGameAppState extends State<ImperiallGameApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void initState() {
    super.initState();
    // Habilita formatação de datas em pt-BR (ver `core/utils/formatters.dart`).
    initializeDateFormatting('pt_BR');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
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
