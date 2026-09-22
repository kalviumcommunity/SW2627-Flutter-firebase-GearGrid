import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.icon,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdminTheme.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 24, offset: Offset(0, 8)),
                ],
              ),
              child: Icon(icon, size: 48, color: AdminTheme.muted.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AdminTheme.body(size: 16),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
