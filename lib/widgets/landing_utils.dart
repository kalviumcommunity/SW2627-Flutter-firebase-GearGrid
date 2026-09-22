import 'package:flutter/material.dart';

class LandingUtils {
  static IconData catIcon(String cat) => switch (cat.toLowerCase()) {
        'sound' || 'audio' => Icons.speaker_group_rounded,
        'lighting' || 'lights' => Icons.lightbulb_outline_rounded,
        'visual' || 'visuals' || 'screen' || 'screens' => Icons.tv_rounded,
        'furniture' => Icons.weekend_outlined,
        'staging' || 'stage' => Icons.theater_comedy_rounded,
        'power' => Icons.bolt_rounded,
        _ => Icons.inventory_2_outlined,
      };

  static const List<(Color, Color)> catBgPalette = [
    (Color(0xFF1E3A5F), Color(0xFFD4E8FF)),
    (Color(0xFF3D2E0A), Color(0xFFFFF3CC)),
    (Color(0xFF0A3325), Color(0xFFD1F5E8)),
    (Color(0xFF3A1A2E), Color(0xFFFFE8E0)),
    (Color(0xFF1F1A40), Color(0xFFEFE8FF)),
    (Color(0xFF3D2000), Color(0xFFFFEDD5)),
  ];
}
