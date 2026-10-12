import 'package:flutter/material.dart';

import '../../core/domain/activity.dart';
import '../../core/domain/attribute.dart';
import '../../core/theme/app_colors.dart';

/// Aparência dos atributos e atividades (separado do domínio puro).
extension AttributeVisuals on Attribute {
  Color get color => switch (this) {
    Attribute.strength => AppColors.strength,
    Attribute.stamina => AppColors.stamina,
    Attribute.focus => AppColors.focus,
    Attribute.discipline => AppColors.discipline,
  };

  IconData get icon => switch (this) {
    Attribute.strength => Icons.fitness_center,
    Attribute.stamina => Icons.directions_run,
    Attribute.focus => Icons.self_improvement,
    Attribute.discipline => Icons.verified_user_outlined,
  };

  String get shortLabel => switch (this) {
    Attribute.strength => 'FOR',
    Attribute.stamina => 'VIG',
    Attribute.focus => 'FOC',
    Attribute.discipline => 'DIS',
  };
}

/// Aparência das atividades.
extension ActivityVisuals on ActivityKind {
  Color get color => primaryAttribute.color;

  IconData get icon => switch (this) {
    ActivityKind.strength => Icons.fitness_center,
    ActivityKind.cardio => Icons.directions_run,
    ActivityKind.mobility => Icons.self_improvement,
    ActivityKind.recovery => Icons.spa_outlined,
    ActivityKind.steps => Icons.directions_walk,
    ActivityKind.nutrition => Icons.restaurant_outlined,
  };
}

/// Aparência da intensidade.
extension IntensityVisuals on Intensity {
  IconData get icon => switch (this) {
    Intensity.light => Icons.speed,
    Intensity.moderate => Icons.bolt,
    Intensity.intense => Icons.local_fire_department,
  };
}
