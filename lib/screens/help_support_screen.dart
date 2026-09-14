import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class _C {
  static const ink = Color(0xFF0C1710);
  static const surface = Color(0xFFF6F4EE);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF8A9489);
  static const border = Color(0xFFE5E0D5);

  static TextStyle head({double size = 28, Color color = ink, double letterSpacing = -0.5}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: letterSpacing);
  static TextStyle body({double size = 15, Color color = ink, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.manrope(fontSize: size, color: color, fontWeight: weight);
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.ink, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Help & Support', style: _C.head(size: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _C.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.support_agent_rounded, color: _C.white, size: 40),
                  const SizedBox(height: 16),
                  Text('How can we help?', style: _C.head(size: 24, color: _C.white)),
                  const SizedBox(height: 8),
                  Text('Our dispatch team is available 24/7 for active bookings.', style: _C.body(color: _C.muted)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildFaqItem(
              'When will my equipment arrive?',
              'Equipment is typically dispatched 12-24 hours prior to the event start time. You can track real-time status in the My Orders tab.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              'Can I extend a booking?',
              'Extensions are subject to availability. Please contact support at least 24 hours before your booking ends.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              'What if equipment is damaged?',
              'All equipment is tested before dispatch. If you notice any damage upon arrival, report it immediately through the order details page.',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    context,
                    title: 'Chat',
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContactCard(
                    context,
                    title: 'Call',
                    icon: Icons.phone_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: _C.body(weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(answer, style: _C.body(color: _C.muted)),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, {required String title, required IconData icon}) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title support connecting...')));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: _C.ink, size: 28),
            const SizedBox(height: 12),
            Text(title, style: _C.body(weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
