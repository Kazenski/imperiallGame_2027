import '../models/game_state.dart';
import '../seed/mock_data.dart';
import 'game_repository.dart';

/// Repositório em memória, usado no **modo demonstração**.
///
/// Não persiste entre execuções — é intencional: abre o app e já tem o que mostrar,
/// sem precisar de backend, conta ou chave.
class DemoGameRepository implements GameRepository {
  DemoGameRepository(this._state);

  factory DemoGameRepository.seeded({DateTime? now}) =>
      DemoGameRepository(buildDemoGameState(now: now));

  GameState _state;

  /// Latência artificial, para a UI exercitar estados de carregamento.
  Duration simulatedLatency = const Duration(milliseconds: 350);

  @override
  Future<GameState> load() async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }
    return _state;
  }

  @override
  Future<GameState> save(GameState state) async {
    _state = state;
    return _state;
  }

  @override
  Future<void> reset() async {
    _state = buildDemoGameState();
  }
}
