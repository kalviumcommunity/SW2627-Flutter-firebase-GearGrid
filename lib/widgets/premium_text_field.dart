import 'package:flutter/material.dart';
import '../theme/client_theme.dart';

class PremiumTextField extends StatelessWidget {
  const PremiumTextField({
    required this.ctrl,
    required this.label,
    required this.icon,
    super.key,
  });
  
  final TextEditingController ctrl;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: ClientTheme.body(color: ClientTheme.ink, size: 14, weight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ClientTheme.body(size: 13),
        prefixIcon: Icon(icon, size: 18, color: ClientTheme.muted),
        filled: true,
        fillColor: ClientTheme.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ClientTheme.border, width: 1.0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
