import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../theme/client_theme.dart';
import '../screens/profile_settings_screen.dart';
import '../screens/help_support_screen.dart';

class StorefrontTopBar extends StatelessWidget {
  const StorefrontTopBar({
    required this.user,
    required this.cartCount,
    required this.connectionIssue,
    required this.hPad,
    required this.onSignOut,
    this.onCartTap,
    super.key,
  });
  
  final AppUser user;
  final int cartCount;
  final String? connectionIssue;
  final double hPad;
  final VoidCallback? onCartTap;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final syncing = connectionIssue != null;
    return Container(
      color: ClientTheme.surface.withValues(alpha: 0.96),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 3,
            color: syncing ? const Color(0xFFFF9800) : const Color(0xFF43A047),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).top),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: ClientTheme.accent,
                        borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.graphic_eq_rounded, color: ClientTheme.ink, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('GearGrid', style: ClientTheme.brand()),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: syncing ? const Color(0xFFFF9800) : const Color(0xFF43A047),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: ClientTheme.white,
                        elevation: 12,
                        onSelected: (value) {
                          if (value == 'logout') {
                            onSignOut();
                          } else if (value == 'profile') {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()));
                          } else if (value == 'help') {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 20, color: ClientTheme.ink),
                                const SizedBox(width: 12),
                                Text('Profile Settings', style: ClientTheme.body(color: ClientTheme.ink)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'help',
                            child: Row(
                              children: [
                                const Icon(Icons.help_outline_rounded, size: 20, color: ClientTheme.ink),
                                const SizedBox(width: 12),
                                Text('Help & Support', style: ClientTheme.body(color: ClientTheme.ink)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                                const SizedBox(width: 12),
                                Text('Sign Out', style: ClientTheme.body(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              color: ClientTheme.ink,
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                            child: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.spaceGrotesk(
                                  color: ClientTheme.lime,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(
              height: 1,
              thickness: 1,
              color: ClientTheme.border.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight, maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(StickyHeaderDelegate old) =>
      maxHeight != old.maxHeight || minHeight != old.minHeight || child != old.child;
}
