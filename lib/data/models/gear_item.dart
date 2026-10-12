import '../../core/domain/attribute.dart';
import 'achievement.dart' show Rarity;
import 'player.dart';

/// Slot de equipamento do avatar.
enum GearSlot {
  weapon('Arma'),
  armor('Armadura'),
  boots('Botas'),
  trinket('Relíquia');

  const GearSlot(this.label);

  final String label;
}

/// Item desbloqueável. Equipar muda a aparência do personagem.
class GearItem {
  const GearItem({
    required this.key,
    required this.name,
    required this.description,
    required this.slot,
    required this.rarity,
    required this.requiredLevel,
    this.requiredAttribute,
    this.attributeThreshold = 0,
  });

  final String key;
  final String name;
  final String description;
  final GearSlot slot;
  final Rarity rarity;

  /// Nível mínimo para desbloquear.
  final int requiredLevel;

  /// Atributo exigido (opcional).
  final Attribute? requiredAttribute;

  /// Pontos mínimos no atributo exigido.
  final int attributeThreshold;

  /// O jogador atende aos requisitos deste item?
  bool isUnlockedFor(Player player) {
    if (player.unlockedGear.contains(key)) return true;
    if (player.level < requiredLevel) return false;
    final attribute = requiredAttribute;
    if (attribute != null && player.xpOf(attribute) < attributeThreshold) {
      return false;
    }
    return true;
  }

  /// Progresso 0..1 rumo ao desbloqueio (para a UI mostrar o que falta).
  double progressFor(Player player) {
    if (isUnlockedFor(player)) return 1;

    final levelPart = requiredLevel <= 0
        ? 1.0
        : (player.level / requiredLevel).clamp(0.0, 1.0);

    final attribute = requiredAttribute;
    if (attribute == null || attributeThreshold <= 0) return levelPart;

    final attributePart = (player.xpOf(attribute) / attributeThreshold).clamp(
      0.0,
      1.0,
    );

    return (levelPart < attributePart ? levelPart : attributePart);
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'description': description,
    'slot': slot.name,
    'rarity': rarity.name,
    'required_level': requiredLevel,
    'required_attribute': requiredAttribute?.name,
    'attribute_threshold': attributeThreshold,
  };
}
