import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/activity.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/attribute_visuals.dart';
import '../../core/utils/formatters.dart';
import '../../providers/game_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/async_game_view.dart';
import '../../shared/widgets/section_header.dart';

/// Tela "Treinar": registra uma atividade real e converte em XP.
class LogActivityScreen extends ConsumerStatefulWidget {
  const LogActivityScreen({super.key});

  @override
  ConsumerState<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends ConsumerState<LogActivityScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  ActivityKind _kind = ActivityKind.strength;
  Intensity _intensity = Intensity.moderate;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  Future<void> _submit() async {
    if (_amount <= 0 || _saving) return;
    setState(() => _saving = true);

    try {
      final result = await ref
          .read(gameControllerProvider.notifier)
          .registerActivity(
            kind: _kind,
            amount: _amount,
            intensity: _intensity,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );

      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aguarde o carregamento dos dados.')),
        );
        return;
      }

      _amountController.clear();
      _noteController.clear();
      context.push(AppRoutes.reward, extra: result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AsyncGameView(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.huge,
          ),
          children: [
            Text(
              'Registrar treino',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text(
              'O esforço vira XP. Sem enrolação.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),

            const SectionHeader(title: 'O que você fez?'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final kind in ActivityKind.values)
                  ChoiceChip(
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                    avatar: Icon(kind.icon, size: 18, color: kind.color),
                    label: Text(kind.label),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            SectionHeader(
              title: 'Quanto?',
              subtitle: 'Unidade: ${_kind.unitLabel}',
            ),
            TextField(
              controller: _amountController,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                hintText: '0',
                suffixText: _kind.unitLabel,
                prefixIcon: Icon(_kind.icon),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            const SectionHeader(title: 'Como foi o esforço?'),
            SegmentedButton<Intensity>(
              segments: [
                for (final intensity in Intensity.values)
                  ButtonSegment(
                    value: intensity,
                    icon: Icon(intensity.icon, size: 18),
                    label: Text(intensity.label),
                  ),
              ],
              selected: {_intensity},
              onSelectionChanged: (selection) =>
                  setState(() => _intensity = selection.first),
            ),
            const SizedBox(height: AppSpacing.xl),

            const SectionHeader(
              title: 'Anotação',
              subtitle: 'Opcional — ajuda a lembrar do treino',
            ),
            TextField(
              controller: _noteController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ex.: peito e trás, senti firme',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _XpPreviewCard(kind: _kind, amount: _amount, intensity: _intensity),
            const SizedBox(height: AppSpacing.lg),

            FilledButton.icon(
              onPressed: _amount > 0 && !_saving ? _submit : null,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Salvando…' : 'Salvar treino'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mostra, em tempo real, quanto XP a atividade vai render — sem salvar nada.
class _XpPreviewCard extends ConsumerWidget {
  const _XpPreviewCard({
    required this.kind,
    required this.amount,
    required this.intensity,
  });

  final ActivityKind kind;
  final double amount;
  final Intensity intensity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    if (state == null || amount <= 0) {
      return AppCard(
        child: Row(
          children: const [
            Icon(Icons.bolt, color: AppColors.textMuted),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Informe uma quantidade para ver o XP.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    final engine = ref.watch(progressionEngineProvider);
    final award = engine.previewAward(
      state: state,
      kind: kind,
      amount: amount,
      intensity: intensity,
    );

    return AppCard(
      borderColor: AppColors.gold.withValues(alpha: 0.6),
      gradient: LinearGradient(
        colors: [AppColors.gold.withValues(alpha: 0.12), AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.gold),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Você vai ganhar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '+${Formatters.xp(award.totalXp)} XP',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          _Line(
            label: 'Base (${Formatters.decimal1(amount)} ${kind.unitLabel})',
            value: Formatters.xp(award.baseXp.round()),
          ),
          _Line(
            label: 'Intensidade ${intensity.label}',
            value: '×${Formatters.decimal1(award.intensityMultiplier)}',
          ),
          _Line(
            label: 'Sequência (${state.player.streakCurrent} dias)',
            value: '×${Formatters.decimal1(award.streakMultiplier)}',
          ),
          _Line(
            label: 'Guilda',
            value: '×${Formatters.decimal1(award.guildMultiplier)}',
          ),
          if (state.player.isActiveToday) ...[
            const SizedBox(height: AppSpacing.md),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 15, color: AppColors.warning),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Você já treinou hoje — a sequência não aumenta de novo.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
