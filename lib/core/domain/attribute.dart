/// Atributos do personagem.
///
/// Domínio puro (sem Flutter) para poder ser usado por regras de negócio e testes.
/// A aparência (cor/ícone) vive em `core/theme/attribute_visuals.dart`.
enum Attribute {
  strength('Força'),
  stamina('Vigor'),
  focus('Foco'),
  discipline('Disciplina');

  const Attribute(this.label);

  /// Nome exibido ao jogador.
  final String label;

  static Attribute fromName(String name) => Attribute.values.firstWhere(
    (a) => a.name == name,
    orElse: () => Attribute.discipline,
  );
}
