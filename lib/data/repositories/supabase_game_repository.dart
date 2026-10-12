import '../models/game_state.dart';
import 'game_repository.dart';

/// Implementação real, via Supabase.
///
/// **Ainda não implementada** — é o ponto de troca documentado em
/// `docs/ARCHITECTURE.md`. O plano (v0.2.0):
///
/// * `load()`  -> `select` em `profiles`, `players`, `activities`, `quest_progress`
/// * `save()`  -> RPC `award_xp(...)` + upserts (nunca `update` direto de XP)
/// * RLS garante que o usuário só enxerga o próprio dado
///
/// Até lá, o app usa `DemoGameRepository` (ver `AppConfig.useDemoData`).
class SupabaseGameRepository implements GameRepository {
  SupabaseGameRepository();

  static const String notImplementedMessage =
      'SupabaseGameRepository ainda não implementado (planejado para a v0.2.0). '
      'O app está rodando em modo demonstração.';

  @override
  Future<GameState> load() =>
      Future.error(UnimplementedError(notImplementedMessage));

  @override
  Future<GameState> save(GameState state) =>
      Future.error(UnimplementedError(notImplementedMessage));

  @override
  Future<void> reset() =>
      Future.error(UnimplementedError(notImplementedMessage));
}
