import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/client_theme.dart';

class SlotBanner extends StatelessWidget {
  const SlotBanner({
    required this.start,
    required this.end,
    required this.onChange,
    super.key,
  });
  
  final DateTime start, end;
  final VoidCallback onChange;

  String _formatDay(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5CC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCDE89A)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFD4EDAB),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF2E6B1A), size: 18),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR EVENT WINDOW',
                      style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF4A7A28),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatDay(start)} · ${_formatTime(start)} – ${_formatTime(end)}',
                    style: ClientTheme.body(color: ClientTheme.ink, size: 13, weight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: const Color(0xFF2E6B1A),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Change',
                    style: GoogleFonts.manrope(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                const Icon(Icons.edit_calendar_rounded, size: 13, color: Colors.white),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
