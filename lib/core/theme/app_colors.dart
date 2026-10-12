import 'package:flutter/material.dart';

/// Paleta do jogo — fantasia sombria com dourado arcano.
///
/// Centralizar aqui garante identidade visual consistente em todas as telas.
class AppColors {
  const AppColors._();

  // Fundo e superfícies
  static const Color background = Color(0xFF0E0B1A);
  static const Color surface = Color(0xFF1A1530);
  static const Color surfaceRaised = Color(0xFF241C42);
  static const Color outline = Color(0xFF3A3059);

  // Marca
  static const Color gold = Color(0xFFE8B84B);
  static const Color goldDeep = Color(0xFFB8892B);
  static const Color arcane = Color(0xFF8B5CF6);
  static const Color arcaneDeep = Color(0xFF5B21B6);

  // Atributos
  static const Color strength = Color(0xFFEF4444);
  static const Color stamina = Color(0xFF34D399);
  static const Color focus = Color(0xFF60A5FA);
  static const Color discipline = Color(0xFFFBBF24);

  // Estados
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color legendary = Color(0xFFF97316);

  // Texto
  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textSecondary = Color(0xFFB5AED6);
  static const Color textMuted = Color(0xFF7C769B);

  // Gradientes
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient arcaneGradient = LinearGradient(
    colors: [arcane, arcaneDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF141029), background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
