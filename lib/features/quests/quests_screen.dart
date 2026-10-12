import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/quest.dart';
import '../../shared/widgets/async_game_view.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/quest_tile.dart';

/// Tela de missões, dividida por período (diária, semanal, épica).
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  static const _tabs = [
    (QuestPeriod.daily, 'Diárias'),
    (QuestPeriod.weekly, 'Semanais'),
    (QuestPeriod.epic, 'Épicas'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Missões'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Diárias'),
              Tab(text: 'Semanais'),
              Tab(text: 'Épicas'),
            ],
          ),
        ),
        body: AsyncGameView(
          builder: (context, state) => TabBarView(
            children: [
              for (final (period, _) in _tabs)
                _QuestList(quests: state.questsOf(period)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestList extends StatelessWidget {
  const _QuestList({required this.quests});

  final List<QuestStatus> quests;

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return const EmptyState(
        icon: Icons.flag_outlined,
        title: 'Sem missões aqui',
        message: 'Nada pendente neste período. Aproveite o descanso.',
      );
    }

    final completed = quests.where((q) => q.completed).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.huge,
      ),
      children: [
        Text(
          '$completed de ${quests.length} concluídas',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final status in quests)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: QuestTile(status: status),
          ),
      ],
    );
  }
}
