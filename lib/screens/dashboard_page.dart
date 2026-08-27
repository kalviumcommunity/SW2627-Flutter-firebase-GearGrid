import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    _buildHeader(),
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
                    _buildQuickActions(),

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

            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.menu_rounded,
          size: 30,
          color: dark,
        ),

        const SizedBox(width: 12),

        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        const Text(
          'GEARGRID',
          style: TextStyle(
            color: dark,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),

        const Spacer(),

        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: dark,
              size: 28,
            ),
            Positioned(
              right: -2,
              top: -4,
              child: _buildBadge('3'),
            ),
          ],
        ),

        const SizedBox(width: 14),

        const CircleAvatar(
          radius: 21,
          backgroundColor: green,
          child: Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),

        const SizedBox(width: 8),

        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arjun',
              style: TextStyle(
                color: dark,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Admin',
              style: TextStyle(
                color: grey,
                fontSize: 11,
              ),
            ),
          ],
        ),

        const SizedBox(width: 2),

        const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: grey,
          size: 20,
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // GREETING
  // ------------------------------------------------------------

  Widget _buildGreeting() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Arjun 👋',
                style: TextStyle(
                  color: dark,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 6),

              Text(
                "Here's what's happening with your business today.",
                style: TextStyle(
                  color: grey,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7F8),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: dark,
              ),
              SizedBox(width: 6),
              Text(
                'May 24, 2024',
                style: TextStyle(
                  color: dark,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SECTION TITLE
  // ------------------------------------------------------------

  Widget _buildSectionTitle(
    String title, {
    String? action,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),

        const Spacer(),

        if (action != null)
          Text(
            action,
            style: const TextStyle(
              color: green,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  // OVERVIEW
  // ------------------------------------------------------------

  Widget _buildOverview() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.42,
      children: [
        _buildMetricCard(
          icon: Icons.calendar_month_rounded,
          value: '128',
          title: 'Total Bookings',
          change: '↑ 12%',
          iconColor: green,
          iconBackground: const Color(0xFFEAF7F1),
        ),

        _buildMetricCard(
          icon: Icons.assignment_rounded,
          value: '18',
          title: 'Pending Approvals',
          change: '↑ 8%',
          iconColor: const Color(0xFFF47A24),
          iconBackground: const Color(0xFFFFF0E6),
        ),

        _buildMetricCard(
          icon: Icons.pie_chart_rounded,
          value: '76%',
          title: 'Utilization',
          change: '↑ 5%',
          iconColor: const Color(0xFF6D45D8),
          iconBackground: const Color(0xFFF0EBFF),
        ),

        _buildMetricCard(
          icon: Icons.currency_rupee_rounded,
          value: '₹ 12.45 L',
          title: 'This Week Revenue',
          change: '↑ 15%',
          iconColor: green,
          iconBackground: const Color(0xFFEAF7F1),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String title,
    required String change,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: dark,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(
              color: dark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '$change vs last month',
            style: TextStyle(
              color: iconColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UPCOMING DISPATCHES
  // ------------------------------------------------------------

  Widget _buildDispatches() {
    final dispatches = [
      {
        'id': 'BK-2024-051',
        'event': 'Rohan & Priya Wedding',
        'date': 'May 24, 9:00 AM',
        'items': '15 Items',
        'status': 'Dispatched',
        'color': green,
      },
      {
        'id': 'BK-2024-052',
        'event': 'Corporate Annual Event',
        'date': 'May 25, 8:00 AM',
        'items': '22 Items',
        'status': 'Confirmed',
        'color': Color(0xFF2878E8),
      },
      {
        'id': 'BK-2024-053',
        'event': 'Sangeet Night',
        'date': 'May 25, 12:00 PM',
        'items': '18 Items',
        'status': 'Ready to Load',
        'color': Color(0xFFF47A24),
      },
      {
        'id': 'BK-2024-054',
        'event': 'Product Launch',
        'date': 'May 26, 9:00 AM',
        'items': '30 Items',
        'status': 'Scheduled',
        'color': grey,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        children: List.generate(
          dispatches.length,
          (index) {
            final item = dispatches[index];
            final Color color = item['color'] as Color;

            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                border: index == dispatches.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(
                          color: border,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: color,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['id'] as String,
                          style: const TextStyle(
                            color: dark,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          item['event'] as String,
                          style: const TextStyle(
                            color: dark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '▣ ${item['date']}   ▫ ${item['items']}',
                          style: const TextStyle(
                            color: grey,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  _buildStatusChip(
                    item['status'] as String,
                    color,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // QUICK ACTIONS
  // ------------------------------------------------------------

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'New Booking',
        'icon': Icons.calendar_month_outlined,
      },
      {
        'title': 'Check Availability',
        'icon': Icons.search_rounded,
      },
      {
        'title': 'Equipment',
        'icon': Icons.inventory_2_outlined,
      },
      {
        'title': 'Dispatch Board',
        'icon': Icons.local_shipping_outlined,
      },
    ];

    return Row(
      children: List.generate(
        actions.length,
        (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index == actions.length - 1 ? 0 : 7,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: border,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    actions[index]['icon'] as IconData,
                    color: green,
                    size: 25,
                  ),

                  const SizedBox(height: 7),

                  Text(
                    actions[index]['title'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // ALERTS
  // ------------------------------------------------------------

  Widget _buildAlerts() {
    final alerts = [
      {
        'title': '3 equipment items need repair',
        'icon': Icons.warning_amber_rounded,
        'color': Color(0xFFE53935),
        'background': Color(0xFFFFE9E9),
      },
      {
        'title': '2 bookings require your approval',
        'icon': Icons.warning_amber_rounded,
        'color': Color(0xFFF47A24),
        'background': Color(0xFFFFF0E0),
      },
      {
        'title': '4 items are due for return tomorrow',
        'icon': Icons.info_outline_rounded,
        'color': Color(0xFF2878E8),
        'background': Color(0xFFEAF2FF),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        children: List.generate(
          alerts.length,
          (index) {
            final item = alerts[index];

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 1,
              ),

              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item['background'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 21,
                ),
              ),

              title: Text(
                item['title'] as String,
                style: const TextStyle(
                  color: dark,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: grey,
              ),
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ------------------------------------------------------------

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        8,
        8,
        8,
        12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFECEFF1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            Icons.home_rounded,
            'Home',
            true,
          ),

          _buildNavItem(
            Icons.calendar_month_rounded,
            'Bookings',
            false,
          ),

          _buildNavItem(
            Icons.inventory_2_outlined,
            'Equipment',
            false,
          ),

          _buildNavItem(
            Icons.notifications_none_rounded,
            'Alerts',
            false,
            badge: '2',
          ),

          _buildNavItem(
            Icons.more_horiz_rounded,
            'More',
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String title,
    bool selected, {
    String? badge,
  }) {
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: selected ? green : grey,
                size: 24,
              ),

              if (badge != null)
                Positioned(
                  right: -8,
                  top: -7,
                  child: _buildBadge(badge),
                ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: TextStyle(
              color: selected ? green : grey,
              fontSize: 9.5,
              fontWeight: selected
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // NOTIFICATION BADGE
  // ------------------------------------------------------------

  Widget _buildBadge(String text) {
    return Container(
      width: 17,
      height: 17,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}