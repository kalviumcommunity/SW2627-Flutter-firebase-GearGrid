import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/landing_page.dart';
import 'screens/home_router.dart';
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
          // User is logged in
          if (user != null) {
            return const HomeRouter();
          }

          // User is not logged in
          return const LandingPage();
        },

        // Firebase authentication is loading
        loading: () {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF16845F),
              ),
            ),
          );
        },

        // Authentication error
        error: (error, stackTrace) {
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
        },
      ),
    );
  }
}