import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import '../shared/equipment_page.dart';
import 'booking/booking_list_page.dart';
import 'booking/date_selection_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,

      // LEFT SIDE DRAWER
      drawer: _buildDrawer(context, ref),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header needs a Scaffold descendant context
                    Builder(
                      builder: (context) => _buildHeader(context, ref),
                    ),

                    const SizedBox(height: 24),

                    _buildGreeting(),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Overview'),

                    const SizedBox(height: 12),

                    _buildOverview(),

                    const SizedBox(height: 28),

                    _buildSectionTitle(
                      'Upcoming Dispatches',
                      action: 'View all',
                    ),

                    const SizedBox(height: 12),

                    _buildDispatches(),

                    const SizedBox(height: 28),

                    _buildSectionTitle('Quick Actions'),

                    const SizedBox(height: 12),

                    _buildQuickActions(context),

                    const SizedBox(height: 28),

                    _buildSectionTitle(
                      'Alerts & Notifications',
                      action: 'View all',
                    ),

                    const SizedBox(height: 12),

                    _buildAlerts(),
                  ],
                ),
              ),
            ),

            // BOTTOM NAVIGATION
            //
            // Builder is important because the More button
            // uses Scaffold.of(context).openDrawer().
            Builder(
              builder: (context) => _buildBottomNavigation(context),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: const BoxDecoration(
                color: green,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GEARGRID',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Equipment Management',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // DASHBOARD
            ListTile(
              leading: const Icon(
                Icons.home_rounded,
                color: green,
              ),
              title: const Text(
                'Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            // BOOKINGS
            ListTile(
              leading: const Icon(
                Icons.calendar_month_outlined,
                color: dark,
              ),
              title: const Text('Bookings'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingListPage(),
                  ),
                );
              },
            ),

            // EQUIPMENT
            ListTile(
              leading: const Icon(
                Icons.inventory_2_outlined,
                color: dark,
              ),
              title: const Text('Equipment'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EquipmentPage(),
                  ),
                );
              },
            ),

            // ALERTS
            ListTile(
              leading: const Icon(
                Icons.notifications_none_rounded,
                color: dark,
              ),
              title: const Text('Alerts'),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AlertsPage(),
                  ),
                );
              },
            ),

            // PROFILE
            ListTile(
              leading: const Icon(
                Icons.person_outline_rounded,
                color: dark,
              ),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const Spacer(),

            const Divider(
              height: 1,
              color: border,
            ),

            // LOGOUT
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                  (route) => false,
                );
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // HAMBURGER
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Scaffold.of(context).openDrawer();
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_rounded,
              color: dark,
              size: 24,
            ),
          ),
        ),

        const SizedBox(width: 14),

        // LOGO
        const Expanded(
          child: Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: green,
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'GEARGRID',
                style: TextStyle(
                  color: dark,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        // NOTIFICATIONS
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AlertsPage(),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: dark,
                size: 27,
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 17,
                height: 17,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        // PROFILE MENU
        PopupMenuButton<String>(
          icon: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Text(
              'A',
              style: TextStyle(
                color: green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          onSelected: (value) async {
            if (value == 'logout') {
              await ref.read(authServiceProvider).signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
                (route) => false,
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arjun',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 12,
                      color: grey,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hi, Arjun 👋',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Here's what's happening with your business today.",
          style: TextStyle(
            fontSize: 14,
            color: grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: grey,
            ),
            const SizedBox(width: 6),
            const Text(
              'May 24, 2024',
              style: TextStyle(
                fontSize: 13,
                color: grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title, {
    String? action,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: dark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: const TextStyle(
                color: green,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // OVERVIEW
  // ============================================================

  Widget _buildOverview() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _buildOverviewCard(
          title: 'Total Bookings',
          value: '128',
          change: '↑ 12%',
          icon: Icons.calendar_month_outlined,
        ),
        _buildOverviewCard(
          title: 'Pending Approvals',
          value: '18',
          change: '↑ 8%',
          icon: Icons.pending_actions_outlined,
        ),
        _buildOverviewCard(
          title: 'Utilization',
          value: '76%',
          change: '↑ 5%',
          icon: Icons.bar_chart_rounded,
        ),
        _buildOverviewCard(
          title: 'This Week Revenue',
          value: '₹ 12.45 L',
          change: '↑ 15%',
          icon: Icons.currency_rupee_rounded,
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: green,
                  size: 19,
                ),
              ),
              const Spacer(),
              Text(
                change,
                style: const TextStyle(
                  color: green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: dark,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPCOMING DISPATCHES
  // ============================================================

  Widget _buildDispatches() {
    final dispatches = [
      {
        'id': 'BK-2024-051',
        'title': 'Rohan & Priya Wedding',
        'date': 'May 24 • 9 AM',
        'items': '15 Items',
        'status': 'Dispatched',
      },
      {
        'id': 'BK-2024-052',
        'title': 'Corporate Annual Event',
        'date': 'May 25 • 8 AM',
        'items': '22 Items',
        'status': 'Confirmed',
      },
      {
        'id': 'BK-2024-053',
        'title': 'Sangeet Night',
        'date': 'May 25 • 12 PM',
        'items': '18 Items',
        'status': 'Ready to Load',
      },
      {
        'id': 'BK-2024-054',
        'title': 'Product Launch',
        'date': 'May 26 • 9 AM',
        'items': '30 Items',
        'status': 'Scheduled',
      },
    ];

    return Column(
      children: dispatches.map((dispatch) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dispatch['id']!,
                      style: const TextStyle(
                        color: green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dispatch['title']!,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${dispatch['date']} • ${dispatch['items']}',
                      style: const TextStyle(
                        color: grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(
                dispatch['status']!,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: green,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.add_circle_outline_rounded,
            title: 'New Booking',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DateSelectionPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.search_rounded,
            title: 'Check Availability',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EquipmentPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.local_shipping_outlined,
            title: 'Dispatch Board',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Dispatch Board is not available yet.',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: green,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: dark,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ALERTS
  // ============================================================

  Widget _buildAlerts() {
    return Column(
      children: [
        _buildAlertItem(
          icon: Icons.build_outlined,
          title: 'Equipment needs repair',
          subtitle: '3 equipment items need repair',
          iconColor: Colors.orange,
        ),
        const SizedBox(height: 10),
        _buildAlertItem(
          icon: Icons.pending_actions_outlined,
          title: 'Booking approvals',
          subtitle: '2 bookings require your approval',
          iconColor: Colors.blue,
        ),
        const SizedBox(height: 10),
        _buildAlertItem(
          icon: Icons.assignment_return_outlined,
          title: 'Equipment returns',
          subtitle: '4 items are due for return tomorrow',
          iconColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: grey,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: border,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              // HOME
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: true,
                  onTap: () {
                    // Already on Dashboard.
                  },
                ),
              ),

              // BOOKINGS
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Bookings',
                  selected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BookingListPage(),
                      ),
                    );
                  },
                ),
              ),

              // EQUIPMENT
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Equipment',
                  selected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EquipmentPage(),
                      ),
                    );
                  },
                ),
              ),

              // ALERTS
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Alerts',
                  selected: false,
                  badge: '2',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AlertsPage(),
                      ),
                    );
                  },
                ),
              ),

              // MORE
              Expanded(
                child: _buildBottomNavItem(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  selected: false,
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 25,
                  color: selected ? green : grey,
                ),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? green : grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ALERTS PAGE
// ============================================================

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Alerts',
          style: TextStyle(
            color: dark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: dark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _alert(
            icon: Icons.build_outlined,
            title: 'Equipment needs repair',
            subtitle: '3 equipment items need repair.',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _alert(
            icon: Icons.pending_actions_outlined,
            title: 'Booking approvals',
            subtitle: '2 bookings require your approval.',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _alert(
            icon: Icons.assignment_return_outlined,
            title: 'Equipment returns',
            subtitle: '4 items are due for return tomorrow.',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _alert({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}