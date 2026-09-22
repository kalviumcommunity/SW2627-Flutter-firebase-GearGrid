import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  static const ink = Color(0xFF0C1710);
  static const surface = Color(0xFFF6F4EE);
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFF6B35);
  static const muted = Color(0xFF8A9489);
  static const border = Color(0xFFE5E0D5);
  
  static const success = Color(0xFFEAF5CC);
  static const successText = Color(0xFF4A7A28);

  static TextStyle brand({double size = 22, Color color = ink}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.8);
      
  static TextStyle head({double size = 26, Color color = ink}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: -1.0, height: 1.1);
      
  static TextStyle body({double size = 13, Color color = muted, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color, height: 1.45);
}
