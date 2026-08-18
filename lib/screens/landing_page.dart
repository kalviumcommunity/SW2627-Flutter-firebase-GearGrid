import 'package:flutter/material.dart';
import 'register_page.dart';
import 'login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // ============================================================
  // COLORS — OPTION 2
  // ============================================================

  static const Color green = Color(0xFF249B73);
  static const Color greenDark = Color(0xFF197A5A);
  static const Color greenLight = Color(0xFFE8F7F0);
  static const Color greenSoft = Color(0xFFF2FBF7);

  static const Color navy = Color(0xFF10233F);
  static const Color text = Color(0xFF172033);
  static const Color textLight = Color(0xFF64748B);

  static const Color background = Color(0xFFF9FCFB);
  static const Color white = Colors.white;
  static const Color border = Color(0xFFE5ECE9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              _buildHero(context),
              _buildCategories(),
              _buildWhyChoose(),
              _buildBottomWave(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 10),
      child: Row(
        children: [
          // Logo
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: green.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _GearGridLogoPainter(),
            ),
          ),

          const SizedBox(width: 10),

          // Brand
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'GEARGRID',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: navy,
                  height: 1,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Event Equipment Rental',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: textLight,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Menu
          Material(
            color: white,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black12,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                _showMenu(context);
              },
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.menu_rounded,
                  color: navy,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DEDA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                _menuItem(
                  icon: Icons.login_rounded,
                  title: 'Login',
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                ),
                _menuItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Equipment',
                ),
                _menuItem(
                  icon: Icons.event_note_outlined,
                  title: 'My Bookings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: greenLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: greenDark,
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: navy,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 15,
        color: textLight,
      ),
      onTap: onTap ?? () {},
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Make Every',
            style: TextStyle(
              fontSize: 40,
              height: 1.02,
              fontWeight: FontWeight.w900,
              color: navy,
              letterSpacing: -1.4,
            ),
          ),

          const Text(
            'Event',
            style: TextStyle(
              fontSize: 40,
              height: 1.02,
              fontWeight: FontWeight.w900,
              color: navy,
              letterSpacing: -1.4,
            ),
          ),

          const Text(
            'Memorable',
            style: TextStyle(
              fontSize: 40,
              height: 1.02,
              fontWeight: FontWeight.w900,
              color: greenDark,
              letterSpacing: -1.4,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Rent quality sound, lighting and furniture '
            'equipment for any type of event.',
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: text,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 23),

          // Get Started
          _primaryButton(
            text: 'Get Started',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegisterPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // Hero equipment visual
          _buildHeroEquipmentVisual(),
        ],
      ),
    );
  }

  // ============================================================
  // HERO EQUIPMENT VISUAL
  // ============================================================

  Widget _buildHeroEquipmentVisual() {
    return SizedBox(
      height: 205,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Soft background
          Positioned(
            left: 12,
            right: 8,
            bottom: 8,
            child: Container(
              height: 155,
              decoration: BoxDecoration(
                color: greenSoft,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

          // Decorative leaves
          Positioned(
            left: 4,
            bottom: 50,
            child: Icon(
              Icons.spa_rounded,
              color: green.withValues(alpha: 0.20),
              size: 70,
            ),
          ),

          Positioned(
            right: 4,
            bottom: 58,
            child: Icon(
              Icons.local_florist_rounded,
              color: green.withValues(alpha: 0.18),
              size: 65,
            ),
          ),

          // Equipment cases
          Positioned(
            left: 52,
            bottom: 18,
            child: _equipmentCase(
              width: 82,
              height: 62,
            ),
          ),

          Positioned(
            left: 79,
            bottom: 69,
            child: _equipmentCase(
              width: 64,
              height: 47,
            ),
          ),

          // Spotlight
          Positioned(
            right: 48,
            bottom: 45,
            child: Transform.rotate(
              angle: -0.13,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: const Color(0xFF202B2A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 53,
                      height: 53,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0C1716),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: green.withValues(alpha: 0.55),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDDF7E9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stand
          Positioned(
            right: 67,
            bottom: 3,
            child: Container(
              width: 5,
              height: 52,
              color: const Color(0xFF343D3C),
            ),
          ),

          // Small decorative flower
          Positioned(
            right: 12,
            bottom: 10,
            child: Icon(
              Icons.local_florist,
              color: green.withValues(alpha: 0.65),
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _equipmentCase({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF262D2D),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFF596362),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: width * 0.78,
            height: 3,
            color: const Color(0xFF858D8B),
          ),
          const Spacer(),
          Container(
            width: width * 0.72,
            height: 1,
            color: const Color(0xFF555D5B),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What do you need?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: navy,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _categoryCard(
                  icon: Icons.speaker_rounded,
                  title: 'Sound',
                  subtitle: 'Equipment',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _categoryCard(
                  icon: Icons.wb_incandescent_rounded,
                  title: 'Lighting',
                  subtitle: 'Equipment',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _categoryCard(
                  icon: Icons.chair_rounded,
                  title: 'Furniture',
                  subtitle: '& Decor',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      height: 144,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 58,
            decoration: BoxDecoration(
              color: greenSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: greenDark,
              size: 32,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: greenDark,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: greenDark,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WHY CHOOSE GEARGRID
  // ============================================================

  Widget _buildWhyChoose() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why Choose GearGrid?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: navy,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 18),

          _featureItem(
            icon: Icons.bolt_rounded,
            title: 'Easy Booking',
            description: 'Simple process, quick booking, no hassle.',
          ),

          _divider(),

          _featureItem(
            icon: Icons.calendar_month_rounded,
            title: 'Real-time Availability',
            description: 'Live availability so you never miss out.',
          ),

          _divider(),

          _featureItem(
            icon: Icons.verified_user_rounded,
            title: 'Reliable Equipment',
            description: 'Clean, safe and reliable equipment always.',
          ),
        ],
      ),
    );
  }

  Widget _featureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: greenSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: green.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              icon,
              color: green,
              size: 25,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 68,
        top: 10,
        bottom: 10,
      ),
      child: Container(
        height: 1,
        color: border,
      ),
    );
  }

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget _primaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: green,
      borderRadius: BorderRadius.circular(28),
      elevation: 3,
      shadowColor: green.withValues(alpha: 0.25),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 21,
            vertical: 13,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                icon,
                color: white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM GREEN WAVE
  // ============================================================

  Widget _buildBottomWave() {
    return SizedBox(
      height: 105,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GreenWavePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// GEARGRID LOGO
// ================================================================

class _GearGridLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    path.moveTo(
      size.width * 0.50,
      size.height * 0.15,
    );
    path.lineTo(
      size.width * 0.78,
      size.height * 0.30,
    );
    path.lineTo(
      size.width * 0.78,
      size.height * 0.67,
    );
    path.lineTo(
      size.width * 0.50,
      size.height * 0.84,
    );
    path.lineTo(
      size.width * 0.22,
      size.height * 0.67,
    );
    path.lineTo(
      size.width * 0.22,
      size.height * 0.30,
    );
    path.close();

    canvas.drawPath(path, paint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final innerPath = Path();

    innerPath.moveTo(
      size.width * 0.50,
      size.height * 0.32,
    );
    innerPath.lineTo(
      size.width * 0.63,
      size.height * 0.39,
    );
    innerPath.lineTo(
      size.width * 0.63,
      size.height * 0.58,
    );
    innerPath.lineTo(
      size.width * 0.50,
      size.height * 0.66,
    );
    innerPath.lineTo(
      size.width * 0.37,
      size.height * 0.58,
    );
    innerPath.lineTo(
      size.width * 0.37,
      size.height * 0.39,
    );
    innerPath.close();

    canvas.drawPath(
      innerPath,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ================================================================
// GREEN WAVE PAINTER
// ================================================================

class _GreenWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8EBD5)
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(
      0,
      size.height * 0.48,
    );

    path.cubicTo(
      size.width * 0.20,
      size.height * 0.72,
      size.width * 0.38,
      size.height * 0.72,
      size.width * 0.58,
      size.height * 0.48,
    );

    path.cubicTo(
      size.width * 0.76,
      size.height * 0.26,
      size.width * 0.88,
      size.height * 0.42,
      size.width,
      size.height * 0.18,
    );

    path.lineTo(
      size.width,
      size.height,
    );

    path.lineTo(
      0,
      size.height,
    );

    path.close();

    canvas.drawPath(
      path,
      paint,
    );

    final secondPaint = Paint()
      ..color = const Color(0xFF72D5AE)
      ..style = PaintingStyle.fill;

    final secondPath = Path();

    secondPath.moveTo(
      0,
      size.height * 0.70,
    );

    secondPath.cubicTo(
      size.width * 0.25,
      size.height * 0.48,
      size.width * 0.42,
      size.height * 0.88,
      size.width * 0.65,
      size.height * 0.57,
    );

    secondPath.cubicTo(
      size.width * 0.80,
      size.height * 0.38,
      size.width * 0.91,
      size.height * 0.60,
      size.width,
      size.height * 0.40,
    );

    secondPath.lineTo(
      size.width,
      size.height,
    );

    secondPath.lineTo(
      0,
      size.height,
    );

    secondPath.close();

    canvas.drawPath(
      secondPath,
      secondPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}