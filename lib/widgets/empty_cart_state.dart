import 'package:flutter/material.dart';
import '../theme/client_theme.dart';

class EmptyCartState extends StatelessWidget {
  const EmptyCartState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 56, color: ClientTheme.muted),
            const SizedBox(height: 16),
            Text('Cart is empty',
                style: ClientTheme.head(size: 18, color: ClientTheme.muted)),
            const SizedBox(height: 8),
            Text('Go back and add equipment to your event.',
                style: ClientTheme.body(size: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
