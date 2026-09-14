import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.ink, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Profile Settings', style: _C.head(size: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _C.ink,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user?.displayName?.isNotEmpty == true
                        ? user!.displayName![0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.spaceGrotesk(
                        color: _C.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.border),
              ),
              child: Column(
                children: [
                  _buildRow('Name', user?.displayName ?? 'Not set'),
                  const Divider(height: 32, color: _C.border),
                  _buildRow('Email', user?.email ?? 'Not set'),
                  const Divider(height: 32, color: _C.border),
                  _buildRow('Role', 'Client User'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildActionCard(
              title: 'Change Password',
              icon: Icons.lock_outline_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent (simulation).')));
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              title: 'Notification Preferences',
              icon: Icons.notifications_none_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences coming soon.')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _C.body(color: _C.muted)),
        Text(value, style: _C.body(weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildActionCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: _C.ink, size: 24),
            const SizedBox(width: 16),
            Text(title, style: _C.body(weight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: _C.muted, size: 16),
          ],
        ),
      ),
    );
  }
}
