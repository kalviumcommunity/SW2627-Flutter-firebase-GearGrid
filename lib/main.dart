import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/landing_page.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: flutterfire configure must be run to generate firebase_options.dart
  // and pass DefaultFirebaseOptions.currentPlatform here.
  // For now, we initialize without options, which requires the google-services.json to be present.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
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
    // Watch the authentication state
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GearGrid',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: authState.when(
        data: (user) {
          if (user != null) {
            // User is logged in, routing to a simple placeholder dashboard for now
            // since we don't have role-based routing set up yet.
            // Ideally, we'd check the user role here and route accordingly.
            return const DashboardScreen();
          }
          return const LandingPage();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _userRole = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await ref.read(authServiceProvider).getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GearGrid Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Role: $_userRole',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            if (_userRole == 'admin')
              const Text('Admin Controls Enabled', style: TextStyle(color: Colors.green)),
            if (_userRole == 'warehouse')
              const Text('Warehouse View', style: TextStyle(color: Colors.blue)),
            if (_userRole == 'staff')
              const Text('Staff Tools Enabled', style: TextStyle(color: Colors.orange)),
          ],
        ),
      ),
    );
  }
}