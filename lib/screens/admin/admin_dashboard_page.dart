import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../state/admin_providers.dart';
import 'pending_requests_page.dart';
import 'analytics_page.dart';
import '../shared/equipment_page.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  // ── Colors ────────────────────────────────────────────────────────
  static const Color green = Color(0xFF16845F);
  static const Color greenLight = Color(0xFFEAF7F1);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);
  static const Color surface = Color(0xFFF8FAFB);
  static const Color orange = Color(0xFFF47A24);
  static const Color blue = Color(0xFF2878E8);
  static const Color red = Color(0xFFE53935);
  static const Color purple = Color(0xFF6D45D8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingBookingsProvider);
    final dispatchedAsync = ref.watch(dispatchedBookingsProvider);
    final confirmedAsync = ref.watch(confirmedBookingsProvider);
    final allAsync = ref.watch(allBookingsProvider);

    final pendingCount = pendingAsync.value?.length ?? 0;
    final dispatchedCount = dispatchedAsync.value?.length ?? 0;

    // Upcoming = Confirmed + Dispatched  
    final upcomingBookings = [
      ...?confirmedAsync.value,
      ...?dispatchedAsync.value,
    ]..sort((a, b) => a.startDate.compareTo(b.startDate));

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref),
              const SizedBox(height: 4),
              _buildGreeting(ref),
              const SizedBox(height: 20),
              _buildKPIStrip(
                pendingCount: pendingCount,
                dispatchedCount: dispatchedCount,
                confirmedCount: confirmedAsync.value?.length ?? 0,
                allAsync: allAsync,
              ),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildPendingApprovals(context, pendingAsync),
              const SizedBox(height: 24),
              _buildUpcomingDispatches(upcomingBookings),
              const SizedBox(height: 24),
              _buildAlerts(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final initials =
        (user?.email?.isNotEmpty == true)
            ? user!.email![0].toUpperCase()
            : 'A';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Logo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16845F), Color(0xFF1DA875)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: green.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'GEARGRID',
                style: TextStyle(
                    color: dark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5),
              ),
              SizedBox(height: 1),
              Text(
                'Admin Panel',
                style: TextStyle(
                    color: green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3),
              ),
            ],
          ),

          const Spacer(),

          // Notifications
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: border),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(Icons.notifications_none_rounded,
                      color: dark, size: 22),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Profile + logout popup
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authServiceProvider).signOut();
              }
            },
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.email ?? 'Admin',
                      style: const TextStyle(
                          color: dark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      'Administrator',
                      style: TextStyle(color: grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        color: red, size: 18),
                    SizedBox(width: 8),
                    Text('Sign Out',
                        style: TextStyle(
                            color: red, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16845F), Color(0xFF1DA875)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Greeting ──────────────────────────────────────────────────────
  Widget _buildGreeting(WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting 👋',
            style: const TextStyle(
                color: dark,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.2),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 2),
            Text(
              user!.email!,
              style: const TextStyle(
                  color: grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: grey),
              const SizedBox(width: 5),
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(now),
                style: const TextStyle(
                    color: grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── KPI Strip ─────────────────────────────────────────────────────
  Widget _buildKPIStrip({
    required int pendingCount,
    required int dispatchedCount,
    required int confirmedCount,
    required AsyncValue<List<BookingModel>> allAsync,
  }) {
    final totalBookings = allAsync.value?.length ?? 0;
    final returnedCount = allAsync.value
            ?.where((b) => b.status == 'Returned')
            .length ??
        0;
    // Simple utilization: non-returned / total if any
    final utilization = totalBookings > 0
        ? '${((dispatchedCount / totalBookings) * 100).round()}%'
        : '0%';

    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildKPICard(
            icon: Icons.assignment_rounded,
            value: '$pendingCount',
            label: 'Pending\nApprovals',
            color: orange,
            bgColor: const Color(0xFFFFF0E6),
          ),
          const SizedBox(width: 10),
          _buildKPICard(
            icon: Icons.local_shipping_rounded,
            value: '$dispatchedCount',
            label: "Today's\nDispatches",
            color: blue,
            bgColor: const Color(0xFFEAF2FF),
          ),
          const SizedBox(width: 10),
          _buildKPICard(
            icon: Icons.pie_chart_rounded,
            value: utilization,
            label: 'Equipment\nUtilization',
            color: purple,
            bgColor: const Color(0xFFF0EBFF),
          ),
          const SizedBox(width: 10),
          _buildKPICard(
            icon: Icons.check_circle_outline_rounded,
            value: '$totalBookings',
            label: 'Total\nBookings',
            color: green,
            bgColor: greenLight,
          ),
          const SizedBox(width: 10),
          _buildKPICard(
            icon: Icons.assignment_return_rounded,
            value: '$returnedCount',
            label: 'Items\nReturned',
            color: grey,
            bgColor: const Color(0xFFF0F0F0),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 17),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                    color: dark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
                color: grey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.3),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'title': 'Pending\nRequests',
        'icon': Icons.assignment_turned_in_outlined,
        'color': orange,
        'bgColor': const Color(0xFFFFF0E6),
        'page': () => const PendingRequestsPage(),
      },
      {
        'title': 'Equipment\nCatalog',
        'icon': Icons.inventory_2_outlined,
        'color': green,
        'bgColor': greenLight,
        'page': () => const EquipmentPage(showBottomNav: false),
      },
      {
        'title': 'Dispatch\nBoard',
        'icon': Icons.local_shipping_outlined,
        'color': blue,
        'bgColor': const Color(0xFFEAF2FF),
        'page': () => const PendingRequestsPage(),
      },
      {
        'title': 'Analytics',
        'icon': Icons.bar_chart_rounded,
        'color': purple,
        'bgColor': const Color(0xFFF0EBFF),
        'page': () => const AnalyticsPage(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
                color: dark,
                fontSize: 17,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(actions.length, (index) {
              final action = actions[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            (action['page'] as Function())()),
                  ),
                  child: Container(
                    margin: EdgeInsets.only(
                        right: index == actions.length - 1 ? 0 : 8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: action['bgColor'] as Color,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(action['icon'] as IconData,
                              color: action['color'] as Color,
                              size: 21),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action['title'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                              color: dark,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Pending Approvals (live) ───────────────────────────────────────
  Widget _buildPendingApprovals(
    BuildContext context,
    AsyncValue<List<BookingModel>> pendingAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Pending Approvals',
                style: TextStyle(
                    color: dark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              pendingAsync.when(
                data: (list) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${list.length}',
                    style: const TextStyle(
                        color: orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PendingRequestsPage()),
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(
                      color: green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          pendingAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: green),
            )),
            error: (e, _) => _buildErrorCard(e.toString()),
            data: (bookings) {
              if (bookings.isEmpty) {
                return _buildAllClearCard();
              }
              final visible = bookings.take(3).toList();
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(visible.length, (i) {
                    final b = visible[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: i < visible.length - 1
                            ? const Border(
                                bottom: BorderSide(color: border))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E6),
                              borderRadius:
                                  BorderRadius.circular(13),
                            ),
                            child: const Icon(
                                Icons.assignment_rounded,
                                color: orange,
                                size: 21),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        b.id.length > 12
                                            ? 'BK-…${b.id.substring(b.id.length - 6)}'
                                            : b.id,
                                        style: const TextStyle(
                                            color: dark,
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w800),
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      b.timeAgo,
                                      style: const TextStyle(
                                          color: grey,
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  b.eventName,
                                  style: const TextStyle(
                                      color: dark,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildInfoTag(
                                      Icons.person_outline_rounded,
                                      b.clientEmail,
                                    ),
                                    const SizedBox(width: 10),
                                    _buildInfoTag(
                                      Icons.inventory_2_outlined,
                                      '${b.totalItems} items',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Upcoming Dispatches (live) ────────────────────────────────────
  Widget _buildUpcomingDispatches(List<BookingModel> bookings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Upcoming Dispatches',
                style: TextStyle(
                    color: dark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800),
              ),
              Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          if (bookings.isEmpty)
            _buildAllClearCard()
          else
            ...bookings.take(3).map((b) {
              Color color;
              switch (b.status) {
                case 'Confirmed':
                  color = blue;
                  break;
                case 'Dispatched':
                  color = green;
                  break;
                default:
                  color = orange;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(Icons.local_shipping_rounded,
                          color: color, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b.eventName,
                                  style: const TextStyle(
                                      color: dark,
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w800),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusChip(b.status, color),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              _buildInfoTag(
                                  Icons.access_time_rounded,
                                  b.dateRangeLabel),
                              const SizedBox(width: 12),
                              _buildInfoTag(
                                  Icons.inventory_2_outlined,
                                  '${b.totalItems} items'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: grey),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
                color: grey, fontSize: 9.5, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Alerts (static for now) ───────────────────────────────────────
  Widget _buildAlerts() {
    final alerts = [
      {
        'title': '3 equipment items need repair',
        'subtitle': 'Speakers, LED Panels, Fog Machine',
        'icon': Icons.build_circle_outlined,
        'color': red,
        'bgColor': const Color(0xFFFFE9E9),
      },
      {
        'title': '2 bookings overdue for return',
        'subtitle': 'Check the Dispatched bookings',
        'icon': Icons.warning_amber_rounded,
        'color': orange,
        'bgColor': const Color(0xFFFFF0E0),
      },
      {
        'title': 'Low stock: LED Par Lights',
        'subtitle': 'Only 2 units available',
        'icon': Icons.info_outline_rounded,
        'color': blue,
        'bgColor': const Color(0xFFEAF2FF),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alerts & Notifications',
            style: TextStyle(
                color: dark, fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...alerts.map((alert) {
            final color = alert['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: alert['bgColor'] as Color,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(alert['icon'] as IconData,
                        color: color, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['title'] as String,
                          style: const TextStyle(
                              color: dark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          alert['subtitle'] as String,
                          style: const TextStyle(
                              color: grey,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: grey.withValues(alpha: 0.6), size: 20),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  Widget _buildAllClearCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: const [
          Icon(Icons.check_circle_outline_rounded,
              color: green, size: 36),
          SizedBox(height: 10),
          Text('All caught up!',
              style: TextStyle(
                  color: dark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('No items here right now.',
              style: TextStyle(color: grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9E9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: red, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not load data. Check Firestore indexes.\n$error',
              style:
                  const TextStyle(color: red, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
