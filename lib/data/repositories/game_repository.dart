import '../models/game_state.dart';

/// Contrato de acesso aos dados do jogo.
///
/// A UI e os serviços **nunca** falam com o backend diretamente: falam com esta
/// interface. Trocar `DemoGameRepository` por `SupabaseGameRepository` é uma
/// linha em `providers/game_providers.dart`.
abstract interface class GameRepository {
  /// Carrega o estado completo do jogador atual.
  Future<GameState> load();

  /// Persiste o estado completo.
  Future<GameState> save(GameState state);

  /// Zera o progresso (útil em desenvolvimento e no modo demo).
  Future<void> reset();
}
