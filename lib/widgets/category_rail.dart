import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/client_theme.dart';

class CategoryRail extends StatelessWidget {
  const CategoryRail({
    required this.categories,
    required this.selected,
    required this.onSelect,
    super.key,
  });
  
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  IconData _categoryIcon(String category) => switch (category.toLowerCase()) {
        'sound' || 'voice' || 'audio' => Icons.speaker_group_rounded,
        'lighting' || 'lights' => Icons.lightbulb_outline_rounded,
        'visual' || 'visuals' || 'screen' => Icons.tv_rounded,
        'furniture' => Icons.weekend_outlined,
        'staging' || 'stage' => Icons.theater_comedy_rounded,
        'power' => Icons.bolt_rounded,
        _ => Icons.category_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? ClientTheme.ink : ClientTheme.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isSelected ? ClientTheme.ink : ClientTheme.border, width: 1.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: ClientTheme.ink.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat != 'All') ...[
                    Icon(_categoryIcon(cat),
                        size: 14,
                        color: isSelected ? ClientTheme.lime : ClientTheme.muted),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat,
                    style: GoogleFonts.manrope(
                      color: isSelected ? Colors.white : ClientTheme.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
