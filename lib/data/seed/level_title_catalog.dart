import '../models/level_title.dart';

/// Marcos de título por nível. Ver `docs/GAME_DESIGN.md`.
const List<LevelTitle> levelTitles = [
  LevelTitle(
    title: 'Novato',
    minLevel: 1,
    description: 'Todo império começa com um passo.',
  ),
  LevelTitle(
    title: 'Aprendiz',
    minLevel: 5,
    description: 'A disciplina já deixou marcas.',
  ),
  LevelTitle(
    title: 'Combatente',
    minLevel: 10,
    description: 'Seu corpo responde ao que você pede.',
  ),
  LevelTitle(
    title: 'Veterano',
    minLevel: 20,
    description: 'Poucos chegam até aqui.',
  ),
  LevelTitle(
    title: 'Campeão',
    minLevel: 35,
    description: 'Você inspira quem está começando.',
  ),
  LevelTitle(
    title: 'Lenda',
    minLevel: 50,
    description: 'Seu nome é contado nas guildas.',
  ),
];

/// Título correspondente ao nível informado (o de maior `minLevel` elegível).
LevelTitle titleForLevel(int level) {
  var result = levelTitles.first;
  for (final candidate in levelTitles) {
    if (level >= candidate.minLevel) result = candidate;
  }
  return result;
}

/// Progresso do título atual rumo ao próximo.
LevelTitleProgress titleProgressForLevel(int level) {
  final current = titleForLevel(level);
  final index = levelTitles.indexWhere((t) => t.minLevel == current.minLevel);
  final isLast = index < 0 || index >= levelTitles.length - 1;

  if (isLast) {
    return LevelTitleProgress(current: current, next: null, levelsToNext: null);
  }

  final next = levelTitles[index + 1];
  return LevelTitleProgress(
    current: current,
    next: next,
    levelsToNext: next.minLevel - level,
  );
}
