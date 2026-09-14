import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/app_role.dart';
import 'models/app_user.dart';
import 'screens/auth_screen.dart';
import 'screens/client_storefront_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'services/firestore_repository.dart';
import 'theme/app_theme.dart';

class GearGridApp extends StatelessWidget {
  const GearGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GearGrid',
      theme: AppTheme.theme,
      home: const _FirebaseBootstrap(),
    );
  }
}

class _FirebaseBootstrap extends StatefulWidget {
  const _FirebaseBootstrap();

  @override
  State<_FirebaseBootstrap> createState() => _FirebaseBootstrapState();
}

class _FirebaseBootstrapState extends State<_FirebaseBootstrap> {
  late final Future<FirebaseApp> _firebaseInitialization;

  @override
  void initState() {
    super.initState();
    _firebaseInitialization = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _firebaseInitialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SetupError(error: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const _AuthGate();
      },
    );
  }
}

/// Drives the full authentication and routing flow.
/// - Unauthenticated: LandingScreen → (on CTA tap) AuthScreen
/// - Authenticated client: ClientStorefrontScreen (premium new UI)
/// - Authenticated admin: HomeScreen (dispatch dashboard)
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _showingAuth = false;

  void _goToAuth() => setState(() => _showingAuth = true);

  @override
  Widget build(BuildContext context) {
    final repository = FirestoreRepository();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // ── Not signed in ─────────────────────────────────────────────────
        if (!authSnapshot.hasData) {
          if (!_showingAuth) {
            return LandingScreen(onStart: _goToAuth);
          }
          return AuthScreen(onCancel: () => setState(() => _showingAuth = false));
        }

        // ── Signed in — resolve profile ───────────────────────────────────
        if (_showingAuth) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => setState(() => _showingAuth = false));
        }

        final firebaseUser = authSnapshot.data!;
        return FutureBuilder<void>(
          future: repository.ensureUserProfile(firebaseUser),
          builder: (context, profileSetup) {
            if (profileSetup.hasError) {
              return _SetupError(error: profileSetup.error.toString());
            }
            if (profileSetup.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return StreamBuilder<AppUser?>(
              stream: repository.watchUser(firebaseUser.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return _SetupError(error: userSnapshot.error.toString());
                }
                if (!userSnapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final user = userSnapshot.data!;

                // ── Route by role ─────────────────────────────────────────
                if (user.role == AppRole.admin) {
                  return HomeScreen(user: user);
                }
                // Client → premium Swiggy-style storefront
                return ClientStorefrontScreen(user: user);
              },
            );
          },
        );
      },
    );
  }
}

class _SetupError extends StatelessWidget {
  const _SetupError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'GearGrid could not connect to Firebase yet.\n\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
