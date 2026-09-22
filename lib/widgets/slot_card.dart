import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/client_theme.dart';

class SlotCard extends StatelessWidget {
  const SlotCard({
    required this.start,
    required this.end,
    required this.onEdit,
    super.key,
  });
  
  final DateTime start;
  final DateTime end;
  final VoidCallback onEdit;

  String _fmtDay(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final s = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5CC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCDE89A)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: const Color(0xFFD4EDAB),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.calendar_month_rounded,
              color: Color(0xFF2E6B1A), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EVENT SLOT',
                  style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF4A7A28),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 3),
              Text(
                  '${_fmtDay(start)} · ${_fmtTime(start)} – ${_fmtTime(end)}',
                  style:
                      ClientTheme.body(color: ClientTheme.ink, size: 13, weight: FontWeight.w800)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Text('Change',
              style: ClientTheme.body(
                  color: const Color(0xFF2E6B1A),
                  size: 13,
                  weight: FontWeight.w800)),
        ),
      ]),
    );
  }
}
