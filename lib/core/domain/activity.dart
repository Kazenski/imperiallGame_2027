import 'attribute.dart';

/// Intensidade percebida do esforço.
enum Intensity {
  light('Leve'),
  moderate('Moderada'),
  intense('Intensa');

  const Intensity(this.label);

  final String label;

  static Intensity fromName(String name) => Intensity.values.firstWhere(
    (i) => i.name == name,
    orElse: () => Intensity.moderate,
  );
}

/// Tipo de atividade registrada. Cada uma alimenta um atributo primário.
enum ActivityKind {
  strength('Musculação', 'séries', Attribute.strength),
  cardio('Cardio', 'km', Attribute.stamina),
  mobility('Mobilidade', 'minutos', Attribute.focus),
  recovery('Recuperação', 'minutos', Attribute.focus),
  steps('Passos', 'mil passos', Attribute.discipline),
  nutrition('Alimentação', 'refeições', Attribute.discipline);

  const ActivityKind(this.label, this.unitLabel, this.primaryAttribute);

  /// Nome exibido.
  final String label;

  /// Unidade que o usuário digita (séries, km, minutos...).
  final String unitLabel;

  /// Atributo que recebe o XP desta atividade.
  final Attribute primaryAttribute;

  static ActivityKind fromName(String name) => ActivityKind.values.firstWhere(
    (k) => k.name == name,
    orElse: () => ActivityKind.strength,
  );
}
