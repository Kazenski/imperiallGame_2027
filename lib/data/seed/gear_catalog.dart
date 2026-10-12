import '../../core/domain/attribute.dart';
import '../models/achievement.dart';
import '../models/gear_item.dart';

/// Catálogo de equipamentos. Cada item desbloqueado muda a aparência do avatar.
///
/// São poucos itens bem escolhidos: o visual é composto em camadas
/// (corpo + equipamento + aura), então 12 itens já geram muitas combinações.
const List<GearItem> gearCatalog = [
  // ---------------- Armas ----------------
  GearItem(
    key: 'wooden_sword',
    name: 'Espada de Treino',
    description: 'De madeira. Serve para aprender a segurar o peso.',
    slot: GearSlot.weapon,
    rarity: Rarity.common,
    requiredLevel: 1,
  ),
  GearItem(
    key: 'iron_blade',
    name: 'Lâmina de Ferro',
    description: 'Forjada para quem já sabe o que quer.',
    slot: GearSlot.weapon,
    rarity: Rarity.common,
    requiredLevel: 5,
  ),
  GearItem(
    key: 'rune_axe',
    name: 'Machado Rúnico',
    description: 'Cada runa conta uma série levantada.',
    slot: GearSlot.weapon,
    rarity: Rarity.rare,
    requiredLevel: 12,
    requiredAttribute: Attribute.strength,
    attributeThreshold: 300,
  ),
  GearItem(
    key: 'abyss_blade',
    name: 'Lâmina do Abismo',
    description: 'Dizem que ela pesa menos que a sua desculpa.',
    slot: GearSlot.weapon,
    rarity: Rarity.legendary,
    requiredLevel: 30,
    requiredAttribute: Attribute.strength,
    attributeThreshold: 1500,
  ),

  // ---------------- Armaduras ----------------
  GearItem(
    key: 'leather_vest',
    name: 'Peitoral de Couro',
    description: 'Leve, honesto, resistente.',
    slot: GearSlot.armor,
    rarity: Rarity.common,
    requiredLevel: 1,
  ),
  GearItem(
    key: 'chain_mail',
    name: 'Cota de Malha',
    description: 'Protege o corpo que você construiu.',
    slot: GearSlot.armor,
    rarity: Rarity.common,
    requiredLevel: 6,
  ),
  GearItem(
    key: 'plate_armor',
    name: 'Armadura de Placas',
    description: 'Só quem aguenta o volume veste isso.',
    slot: GearSlot.armor,
    rarity: Rarity.rare,
    requiredLevel: 15,
    requiredAttribute: Attribute.stamina,
    attributeThreshold: 400,
  ),
  GearItem(
    key: 'dragonscale',
    name: 'Malha de Dragão',
    description: 'Escamas que já viram mil invernos.',
    slot: GearSlot.armor,
    rarity: Rarity.legendary,
    requiredLevel: 35,
    requiredAttribute: Attribute.stamina,
    attributeThreshold: 2000,
  ),

  // ---------------- Botas ----------------
  GearItem(
    key: 'worn_boots',
    name: 'Botas Gastas',
    description: 'O solado conta o caminho percorrido.',
    slot: GearSlot.boots,
    rarity: Rarity.common,
    requiredLevel: 1,
  ),
  GearItem(
    key: 'trail_runners',
    name: 'Botas de Trilha',
    description: 'Feitas para quem não para no primeiro morro.',
    slot: GearSlot.boots,
    rarity: Rarity.common,
    requiredLevel: 4,
    requiredAttribute: Attribute.stamina,
    attributeThreshold: 150,
  ),
  GearItem(
    key: 'swift_boots',
    name: 'Botas Velozes',
    description: 'O chão passa rápido demais.',
    slot: GearSlot.boots,
    rarity: Rarity.rare,
    requiredLevel: 18,
    requiredAttribute: Attribute.stamina,
    attributeThreshold: 800,
  ),

  // ---------------- Relíquias ----------------
  GearItem(
    key: 'focus_stone',
    name: 'Pedra do Foco',
    description: 'Acalma a mente na hora do esforço.',
    slot: GearSlot.trinket,
    rarity: Rarity.common,
    requiredLevel: 8,
    requiredAttribute: Attribute.focus,
    attributeThreshold: 200,
  ),
  GearItem(
    key: 'discipline_sigil',
    name: 'Selo da Disciplina',
    description: 'Não é motivação. É rotina.',
    slot: GearSlot.trinket,
    rarity: Rarity.rare,
    requiredLevel: 10,
    requiredAttribute: Attribute.discipline,
    attributeThreshold: 250,
  ),
  GearItem(
    key: 'eternal_amulet',
    name: 'Amuleto do Eterno',
    description: 'Concedido a quem nunca desistiu.',
    slot: GearSlot.trinket,
    rarity: Rarity.legendary,
    requiredLevel: 40,
  ),
];

/// Busca um item pela chave.
GearItem? gearByKey(String key) {
  for (final item in gearCatalog) {
    if (item.key == key) return item;
  }
  return null;
}

/// Itens de um slot.
List<GearItem> gearBySlot(GearSlot slot) =>
    gearCatalog.where((item) => item.slot == slot).toList();
