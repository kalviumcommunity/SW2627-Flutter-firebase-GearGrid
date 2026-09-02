import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/auth_provider.dart';
import 'dashboard_page.dart';
import 'admin/admin_dashboard_page.dart';
import 'dispatch/warehouse_dashboard_page.dart';

class HomeRouter extends ConsumerWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        if (role == 'admin' || role == 'staff') {
          return const AdminDashboardPage();
        } else if (role == 'warehouse') {
          return const WarehouseDashboardPage();
        } else {
          return const DashboardPage(); // Client dashboard
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, s) => Scaffold(
        body: Center(
          child: Text('Error loading role: $e'),
        ),
      ),
    );
  }
}
