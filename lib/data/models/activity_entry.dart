import '../../core/domain/activity.dart';

/// Registro de um treino/atividade concluído — a prova do esforço real.
class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.intensity,
    required this.xpAwarded,
    required this.performedAt,
    this.note,
  });

  final String id;
  final ActivityKind kind;

  /// Quantidade na unidade da atividade (séries, km, minutos, mil passos...).
  final double amount;

  final Intensity intensity;

  /// XP efetivamente concedido (já com multiplicadores).
  final int xpAwarded;

  final DateTime performedAt;
  final String? note;

  /// Descrição curta, ex.: "12,0 km".
  String get amountLabel {
    final value = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(1).replaceAll('.', ',');
    return '$value ${kind.unitLabel}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'amount': amount,
    'intensity': intensity.name,
    'xp_awarded': xpAwarded,
    'performed_at': performedAt.toIso8601String(),
    'note': note,
  };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
    id: json['id'] as String,
    kind: ActivityKind.fromName(json['kind'] as String? ?? 'strength'),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    intensity: Intensity.fromName(json['intensity'] as String? ?? 'moderate'),
    xpAwarded: (json['xp_awarded'] as num?)?.toInt() ?? 0,
    performedAt:
        DateTime.tryParse(json['performed_at'] as String? ?? '') ??
        DateTime.now(),
    note: json['note'] as String?,
  );
}
