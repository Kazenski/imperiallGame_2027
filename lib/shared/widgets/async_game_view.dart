import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_state.dart';
import '../../providers/game_providers.dart';
import 'empty_state.dart';

/// Trata os estados de carregamento/erro do estado do jogo em um só lugar.
///
/// Toda tela que precisa do [GameState] usa este wrapper para não repetir
/// o mesmo `when(...)` em cada arquivo.
class AsyncGameView extends ConsumerWidget {
  const AsyncGameView({super.key, required this.builder});

  final Widget Function(BuildContext context, GameState state) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(gameControllerProvider);

    return asyncState.when(
      data: (state) => builder(context, state),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => ErrorView(
        message: '$error',
        onRetry: () => ref.invalidate(gameControllerProvider),
      ),
    );
  }
}
