import 'package:flutter/material.dart';
import '../theme/client_theme.dart';

class CartAppBar extends StatelessWidget {
  const CartAppBar({required this.itemCount, super.key});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ClientTheme.surface,
          border: Border(
            bottom: BorderSide(color: ClientTheme.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
              color: ClientTheme.ink,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Cart', style: ClientTheme.head(size: 22, color: ClientTheme.ink)),
                  Text('$itemCount item${itemCount == 1 ? '' : 's'} selected',
                      style: ClientTheme.body(size: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
