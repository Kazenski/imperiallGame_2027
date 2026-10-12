/// Título concedido ao jogador ao atingir um nível-marco.
class LevelTitle {
  const LevelTitle({
    required this.title,
    required this.minLevel,
    required this.description,
  });

  final String title;
  final int minLevel;
  final String description;

  Map<String, dynamic> toJson() => {
    'title': title,
    'min_level': minLevel,
    'description': description,
  };

  factory LevelTitle.fromJson(Map<String, dynamic> json) => LevelTitle(
    title: json['title'] as String,
    minLevel: json['min_level'] as int,
    description: json['description'] as String? ?? '',
  );
}

/// Status de progressão exibido na tela do personagem.
class LevelTitleProgress {
  const LevelTitleProgress({
    required this.current,
    required this.next,
    required this.levelsToNext,
  });

  final LevelTitle current;
  final LevelTitle? next;

  /// Quantos níveis faltam para o próximo título. `null` no título final.
  final int? levelsToNext;

  bool get isMaxTitle => next == null;
}
