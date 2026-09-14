import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class _C {
  static const ink = Color(0xFF0C1710);
  static const surface = Color(0xFFF6F4EE);
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFF6B35);
  static const muted = Color(0xFF8A9489);
  static const border = Color(0xFFE5E0D5);

  static TextStyle head({double size = 28, Color color = ink, double letterSpacing = -0.5}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: letterSpacing);
  static TextStyle body({double size = 15, Color color = ink, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.manrope(fontSize: size, color: color, fontWeight: weight);
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.onCancel});
  final VoidCallback? onCancel;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegistering = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _nameController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        (_isRegistering && displayName.isEmpty)) {
      setState(() => _error = 'Complete every field to continue.');
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      if (_isRegistering) {
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await cred.user?.updateDisplayName(displayName);
      } else {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _parseError(e.code));
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseError(String code) {
    return switch (code) {
      'user-not-found' => 'Account not found. Consider creating one.',
      'wrong-password' => 'Incorrect password. Try again.',
      'invalid-credential' => 'Incorrect credentials. Try again.',
      'email-already-in-use' => 'Email already registered. Sign in instead.',
      'weak-password' => 'Password is too weak.',
      'invalid-email' => 'Please enter a valid email.',
      'network-request-failed' =>
        'We cannot reach the internet right now. Check your connection.',
      'too-many-requests' =>
        'Too many attempts made. Please wait a few minutes.',
      _ => 'We could not complete your request. Please try again.',
    };
  }

  Widget _buildField(String label, TextEditingController controller, {bool isPassword = false, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: _C.body(),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _C.body(color: _C.muted, size: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _C.accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.graphic_eq_rounded, color: _C.white, size: 32),
                        ),
                      ),
                      if (widget.onCancel != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: _C.muted),
                          onPressed: widget.onCancel,
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isRegistering ? 'Create Account' : 'Welcome Back',
                    style: _C.head(size: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegistering
                        ? 'Join GearGrid to start planning and booking equipment for your next event.'
                        : 'Sign in to access your dispatch control room or manage bookings.',
                    style: _C.body(color: _C.muted),
                  ),
                  const SizedBox(height: 32),
                  if (_isRegistering) ...[
                    _buildField('Your name or company', _nameController),
                    const SizedBox(height: 16),
                  ],
                  _buildField('Email address', _emailController, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildField('Password', _passwordController, isPassword: true),
                  
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: _C.body(color: Colors.red.shade700, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.ink,
                        foregroundColor: _C.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : () {
                        HapticFeedback.lightImpact();
                        _submit();
                      },
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _C.white),
                            )
                          : Text(
                              _isRegistering ? 'Create Account' : 'Sign In',
                              style: _C.body(color: _C.white, weight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: _C.ink,
                        textStyle: _C.body(weight: FontWeight.w600),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isRegistering = !_isRegistering;
                                _error = null;
                              });
                            },
                      child: Text(
                        _isRegistering
                            ? 'I already have an account'
                            : 'Create a new account',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
