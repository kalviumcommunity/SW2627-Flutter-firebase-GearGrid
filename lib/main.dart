import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/auth/landing_page.dart';
import 'screens/client/dashboard_page.dart';
import 'screens/admin/admin_shell.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: GearGridApp(),
    ),
  );
}

class GearGridApp extends ConsumerWidget {
  const GearGridApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Firebase authentication state
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GearGrid',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16845F),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: Colors.white,
      ),

  home: authState.when(
        data: (user) {
          if (user != null) {
            return const RoleRouter();
          }
          return const LandingPage();
        },
        loading: () => const _LoadingScreen(),
        error: (error, stackTrace) => _ErrorScreen(error: error.toString()),
      ),
    );
  }
}

final userRoleProvider = FutureProvider<String>((ref) async {
  // Watch the auth state so this recalculates when a user logs in or out
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    return 'unauthenticated';
  }
  
  final authService = ref.read(authServiceProvider);
  return await authService.getUserRole();
});

class RoleRouter extends ConsumerWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        if (role == 'admin' || role == 'staff') {
          return const AdminShell();
        } else {
          return const DashboardPage();
        }
      },
      loading: () => const _LoadingScreen(),
      error: (error, stack) => _ErrorScreen(error: error.toString()),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF16845F),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101B2D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}