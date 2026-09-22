import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/client_theme.dart';

class PaymentSuccessView extends StatelessWidget {
  const PaymentSuccessView({
    required this.total,
    required this.eventName,
    required this.bookingId,
    required this.onContinue,
    required this.scaleAnim,
    super.key,
  });
  
  final double total;
  final String eventName;
  final String bookingId;
  final VoidCallback onContinue;
  final Animation<double> scaleAnim;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientTheme.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              ScaleTransition(
                scale: scaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                      color: Color(0xFFC8F135),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Color(0xFF0C1710), size: 60),
                ),
              ),
              const SizedBox(height: 36),

              Text('Payment Successful!',
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),

              Text('Payment successful · ₹${total.round()}',
                  style: GoogleFonts.manrope(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('#$bookingId',
                    style: GoogleFonts.spaceMono(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),

              const Spacer(),

              GestureDetector(
                onTap: onContinue,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                      color: const Color(0xFFC8F135),
                      borderRadius: BorderRadius.circular(18)),
                  child: Center(
                    child: Text('View My Orders',
                        style: GoogleFonts.manrope(
                            color: ClientTheme.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Auto-redirecting in 3 seconds…',
                  style: ClientTheme.body(size: 11,
                      color: Colors.white30,
                      weight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
