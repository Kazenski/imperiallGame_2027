import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imperiall_game/app.dart';
import 'package:imperiall_game/data/repositories/demo_game_repository.dart';
import 'package:imperiall_game/providers/game_providers.dart';

/// Repositório de demonstração sem latência, para os testes não esperarem.
DemoGameRepository _fastRepository() {
  final repository = DemoGameRepository.seeded();
  repository.simulatedLatency = Duration.zero;
  return repository;
}

Future<void> _pumpApp(WidgetTester tester) async {
  // Viewport alto para o formulário inteiro caber sem rolagem no teste.
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [gameRepositoryProvider.overrideWithValue(_fastRepository())],
      child: const ImperiallGameApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('abre no início com os dados de demonstração', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('Eduardo'), findsWidgets);
    expect(find.text('Registrar treino'), findsOneWidget);
  });

  testWidgets('navega para a aba de treino', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Treinar'));
    await tester.pumpAndSettle();

    expect(find.text('O que você fez?'), findsOneWidget);
    expect(find.text('Salvar treino'), findsOneWidget);
  });

  testWidgets('registra um treino e mostra a recompensa', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Treinar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '10');
    await tester.pumpAndSettle();

    expect(find.textContaining('XP', findRichText: true), findsWidgets);

    await tester.tap(find.text('Salvar treino'));
    await tester.pumpAndSettle();

    expect(find.text('XP GANHO'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });
}
