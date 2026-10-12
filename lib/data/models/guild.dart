/// Membro de uma guilda, como aparece no ranking.
class GuildMember {
  const GuildMember({
    required this.id,
    required this.displayName,
    required this.level,
    required this.weeklyXp,
    this.isCurrentUser = false,
  });

  final String id;
  final String displayName;
  final int level;
  final int weeklyXp;
  final bool isCurrentUser;
}

/// Guilda: grupo com progresso coletivo.
class Guild {
  const Guild({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.memberLimit,
  });

  final String id;
  final String name;
  final String description;
  final List<GuildMember> members;
  final int memberLimit;

  int get memberCount => members.length;

  /// XP somado de todos os membros na semana.
  int get weeklyXp =>
      members.fold<int>(0, (sum, member) => sum + member.weeklyXp);

  /// Membros ordenados por XP semanal (melhor primeiro).
  List<GuildMember> get ranking {
    final sorted = [...members]
      ..sort((a, b) => b.weeklyXp.compareTo(a.weeklyXp));
    return sorted;
  }

  /// Posição 1-based do usuário atual. `null` se ele não estiver na guilda.
  int? get currentUserRank {
    final index = ranking.indexWhere((member) => member.isCurrentUser);
    return index < 0 ? null : index + 1;
  }

  GuildMember? get currentUser {
    final index = members.indexWhere((member) => member.isCurrentUser);
    return index < 0 ? null : members[index];
  }
}
