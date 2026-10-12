import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/domain/activity.dart';
import '../core/utils/xp_calculator.dart';
import '../data/models/achievement.dart';
import '../data/models/activity_entry.dart';
import '../data/models/game_state.dart';
import '../data/models/gear_item.dart';
import '../data/models/guild.dart';
import '../data/models/level_title.dart';
import '../data/models/player.dart';
import '../data/models/quest.dart';
import '../data/repositories/demo_game_repository.dart';
import '../data/repositories/game_repository.dart';
import '../data/repositories/supabase_game_repository.dart';
import '../data/seed/achievement_catalog.dart';
import '../data/seed/gear_catalog.dart';
import '../data/seed/level_title_catalog.dart';
import '../services/progression_engine.dart';
import 'auth_providers.dart';

/// Escolhe o backend conforme a configuração de ambiente.
///
/// Em modo demo (padrão), usa dados mockados. Com credenciais Supabase
/// configuradas, usa a implementação real (autenticada).
///
/// Este provider **não** é `autoDispose`: o repositório em memória precisa
/// sobreviver enquanto o app estiver aberto, senão o progresso do demo se perde
/// a cada reconstrução.
///
/// Ele observa o usuário atual: ao trocar de conta, um repositório novo é
/// criado (cache de sincronização limpo).
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  ref.watch(currentUserIdProvider);
  if (AppConfig.useDemoData) {
    return DemoGameRepository.seeded();
  }
  return SupabaseGameRepository();
});

/// Motor de progressão (puro). Injetado para facilitar testes.
final progressionEngineProvider = Provider<ProgressionEngine>(
  (ref) => const ProgressionEngine(),
);

/// Retorno de equipar/desequipar, para a UI reagir com uma mensagem.
class EquipFeedback {
  const EquipFeedback({required this.success, required this.message});

  final bool success;
  final String message;
}

/// Dono do estado do jogo. Toda mutação passa por aqui.
///
/// `AsyncNotifierProvider` **não** é autoDispose por padrão no Riverpod 3,
/// então o estado em memória é preservado enquanto o app viver.
class GameController extends AsyncNotifier<GameState> {
  @override
  Future<GameState> build() {
    // Recarrega tudo quando o usuário autenticado muda (login/logout/troca).
    ref.watch(currentUserIdProvider);
    return ref.read(gameRepositoryProvider).load();
  }

  ProgressionEngine get _engine => ref.read(progressionEngineProvider);

  /// Registra uma atividade e devolve o que o jogador ganhou.
  ///
  /// Retorna `null` se o estado ainda não carregou.
  Future<WorkoutResult?> registerActivity({
    required ActivityKind kind,
    required double amount,
    required Intensity intensity,
    String? note,
  }) async {
    final current = state.value;
    if (current == null) return null;

    final outcome = _engine.apply(
      state: current,
      kind: kind,
      amount: amount,
      intensity: intensity,
      note: note,
    );

    state = AsyncData(outcome.state);
    await ref.read(gameRepositoryProvider).save(outcome.state);
    return outcome.result;
  }

  /// Prévia do XP de uma atividade, sem mutar nada.
  XpAward? previewAward({
    required ActivityKind kind,
    required double amount,
    required Intensity intensity,
  }) {
    final current = state.value;
    if (current == null) return null;
    return _engine.previewAward(
      state: current,
      kind: kind,
      amount: amount,
      intensity: intensity,
    );
  }

  /// Equipa um item desbloqueado (substitui o item do mesmo slot).
  Future<EquipFeedback> equip(String gearKey) async {
    final current = state.value;
    if (current == null) {
      return const EquipFeedback(
        success: false,
        message: 'Estado ainda carregando.',
      );
    }

    final item = gearByKey(gearKey);
    if (item == null) {
      return const EquipFeedback(success: false, message: 'Item inexistente.');
    }

    if (!item.isUnlockedFor(current.player)) {
      return EquipFeedback(
        success: false,
        message: '${item.name} ainda está bloqueado.',
      );
    }

    final equipped = <String>[
      ...current.player.equippedGear.where((key) {
        final other = gearByKey(key);
        return other == null || other.slot != item.slot;
      }),
      gearKey,
    ];

    final updated = current.copyWith(
      player: current.player.copyWith(equippedGear: equipped),
    );

    state = AsyncData(updated);
    await ref.read(gameRepositoryProvider).save(updated);

    return EquipFeedback(success: true, message: '${item.name} equipado.');
  }

  /// Desequipa o item do slot informado.
  Future<void> unequip(GearSlot slot) async {
    final current = state.value;
    if (current == null) return;

    final equipped = current.player.equippedGear.where((key) {
      final item = gearByKey(key);
      return item == null || item.slot != slot;
    }).toList();

    final updated = current.copyWith(
      player: current.player.copyWith(equippedGear: equipped),
    );

    state = AsyncData(updated);
    await ref.read(gameRepositoryProvider).save(updated);
  }

  /// Recalcula as missões do dia/semana quando o período vira.
  Future<void> refreshQuestPeriod() async {
    final current = state.value;
    if (current == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = current.questPeriodStart;

    if (today == start) return;

    final isNewWeek = today.difference(start).inDays >= 7;

    final reset = current.quests.map((status) {
      final period = status.quest.period;
      final shouldReset =
          period == QuestPeriod.daily ||
          (period == QuestPeriod.weekly && isNewWeek);

      if (!shouldReset) return status;
      return QuestStatus(quest: status.quest, progress: 0, completed: false);
    }).toList();

    final updated = current.copyWith(quests: reset, questPeriodStart: today);
    state = AsyncData(updated);
    await ref.read(gameRepositoryProvider).save(updated);
  }

  /// Volta o app ao estado inicial de demonstração.
  Future<void> resetProgress() async {
    state = const AsyncLoading<GameState>();
    final repository = ref.read(gameRepositoryProvider);
    await repository.reset();
    state = AsyncData(await repository.load());
  }
}

final gameControllerProvider = AsyncNotifierProvider<GameController, GameState>(
  GameController.new,
);

/// Estado atual, sem a camada assíncrona.
final gameStateProvider = Provider<GameState?>(
  (ref) => ref.watch(gameControllerProvider).value,
);

/// Jogador atual (null enquanto carrega).
final playerProvider = Provider<Player?>(
  (ref) => ref.watch(gameStateProvider)?.player,
);

/// Título de nível atual e progresso rumo ao próximo.
final levelTitleProgressProvider = Provider<LevelTitleProgress?>((ref) {
  final player = ref.watch(playerProvider);
  return player == null ? null : titleProgressForLevel(player.level);
});

/// Equipamentos equipados, prontos para desenhar o avatar.
final equippedGearProvider = Provider<List<GearItem>>((ref) {
  final player = ref.watch(playerProvider);
  if (player == null) return const [];

  return player.equippedGear.map(gearByKey).whereType<GearItem>().toList();
});

/// Progresso de XP para a barra do cabeçalho.
final xpProgressProvider = Provider<XpProgress>((ref) {
  final player = ref.watch(playerProvider);
  return XpCalculator.progress(player?.totalXp ?? 0);
});

/// Missões de um período específico.
final questsByPeriodProvider = Provider.family<List<QuestStatus>, QuestPeriod>((
  ref,
  period,
) {
  final state = ref.watch(gameStateProvider);
  return state?.questsOf(period) ?? const [];
});

/// Atividades recentes (mais novas primeiro).
final recentActivitiesProvider = Provider<List<ActivityEntry>>((ref) {
  final state = ref.watch(gameStateProvider);
  return state?.recentActivities ?? const [];
});

/// Guilda atual (null se o jogador não estiver em uma).
final guildProvider = Provider<Guild?>(
  (ref) => ref.watch(gameStateProvider)?.guild,
);

/// Conquistas do catálogo, marcando as já desbloqueadas.
class AchievementView {
  const AchievementView({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;
}

final achievementsProvider = Provider<List<AchievementView>>((ref) {
  final state = ref.watch(gameStateProvider);
  final unlocked = state?.unlockedAchievements ?? const <String>{};
  return [
    for (final achievement in achievementCatalog)
      AchievementView(
        achievement: achievement,
        unlocked: unlocked.contains(achievement.key),
      ),
  ];
});
