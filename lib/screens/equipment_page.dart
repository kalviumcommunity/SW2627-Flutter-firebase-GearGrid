import 'package:flutter/material.dart';
import 'add_equipment_page.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);

  int selectedCategory = 0;

  final List<String> categories = [
    'All',
    'Sound',
    'Lighting',
    'Furniture',
  ];

  // ============================================================
  // EQUIPMENT DATA
  // ============================================================

  final List<EquipmentItem> equipment = [
    EquipmentItem(
      name: 'JBL PA Speaker',
      id: 'AUD-001',
      category: 'Sound',
      brand: 'JBL',
      total: 10,
      damaged: 1,
      available: 7,
      status: 'Available',
      imagePath: 'assets/equipment/jbl_pa_speaker.png',
    ),
    EquipmentItem(
      name: 'Beam 230 Moving Head',
      id: 'LGT-002',
      category: 'Lighting',
      brand: 'Philips',
      total: 12,
      damaged: 2,
      available: 10,
      status: 'Available',
      imagePath: 'assets/equipment/beam_230_moving_head.png',
    ),
    EquipmentItem(
      name: 'Shure SM58 Microphone',
      id: 'AUD-003',
      category: 'Sound',
      brand: 'Shure',
      total: 15,
      damaged: 0,
      available: 1,
      status: 'In Use',
      imagePath: 'assets/equipment/shure_sm58_microphone.png',
    ),
    EquipmentItem(
      name: 'Aluminum Truss 12ft',
      id: 'STG-004',
      category: 'Lighting',
      brand: 'Global Truss',
      total: 20,
      damaged: 2,
      available: 18,
      status: 'Available',
      imagePath: 'assets/equipment/aluminum_truss_12ft.png',
    ),
    EquipmentItem(
      name: 'Banquet Chair',
      id: 'FUR-005',
      category: 'Furniture',
      brand: 'GearGrid',
      total: 25,
      damaged: 3,
      available: 5,
      status: 'Maintenance',
      imagePath: 'assets/equipment/banquet_chair.png',
    ),
    EquipmentItem(
      name: 'Round Banquet Table 5ft',
      id: 'FUR-006',
      category: 'Furniture',
      brand: 'GearGrid',
      total: 10,
      damaged: 0,
      available: 8,
      status: 'Available',
      imagePath: 'assets/equipment/round_banquet_table_5ft.png',
    ),
  ];

  // ============================================================
  // FILTERED EQUIPMENT
  // ============================================================

  List<EquipmentItem> get filteredEquipment {
    if (selectedCategory == 0) {
      return equipment;
    }

    final category = categories[selectedCategory];

    return equipment
        .where((item) => item.category == category)
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

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
                padding: const EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 26),

                    _buildPageTitle(),

                    const SizedBox(height: 24),

                    _buildSearchAndFilter(),

                    const SizedBox(height: 18),

                    _buildCategoryTabs(),

                    const SizedBox(height: 25),

                    _buildSortRow(),

                    const SizedBox(height: 14),

                    _buildEquipmentList(),
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.menu_rounded,
          size: 31,
          color: dark,
        ),

        const SizedBox(width: 13),

        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
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
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),

        const Spacer(),

        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: dark,
              size: 29,
            ),
            Positioned(
              right: -3,
              top: -5,
              child: _badge('3'),
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
              fontSize: 17,
              fontWeight: FontWeight.w800,
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

        const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: grey,
          size: 20,
        ),
      ],
    );
  }

  // ============================================================
  // PAGE TITLE + ADD EQUIPMENT
  // ============================================================

  Widget _buildPageTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Equipment',
                style: TextStyle(
                  color: dark,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 5),

              Text(
                'Manage and track your equipment inventory',
                style: TextStyle(
                  color: grey,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // ========================================================
        // ADD EQUIPMENT BUTTON
        // ========================================================

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AddEquipmentPage(),
              ),
            );
          },

          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),

                SizedBox(width: 5),

                Text(
                  'Add Equipment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH + FILTER
  // ============================================================

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: border,
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 16),

                Icon(
                  Icons.search_rounded,
                  color: grey,
                  size: 27,
                ),

                SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'Search equipment by name, brand or ID...',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        Container(
          height: 54,
          width: 125,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: border,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: dark,
                size: 21,
              ),

              SizedBox(width: 7),

              Text(
                'Filters',
                style: TextStyle(
                  color: dark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CATEGORY TABS
  // ============================================================

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 12);
        },
        itemBuilder: (context, index) {
          final bool selected =
              selectedCategory == index;

          IconData icon;

          switch (index) {
            case 0:
              icon = Icons.grid_view_rounded;
              break;

            case 1:
              icon = Icons.volume_up_outlined;
              break;

            case 2:
              icon = Icons.lightbulb_outline_rounded;
              break;

            default:
              icon = Icons.chair_outlined;
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = index;
              });
            },

            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 17,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? green
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? green
                      : border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? Colors.white
                        : green,
                    size: 22,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    categories[index],
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : dark,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
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

  // ============================================================
  // SORT ROW
  // ============================================================

  Widget _buildSortRow() {
    return Row(
      children: [
        const Text(
          'Total Items: 18',
          style: TextStyle(
            color: grey,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const Spacer(),

        const Text(
          'Sort by: ',
          style: TextStyle(
            color: dark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        const Text(
          'Name (A-Z)',
          style: TextStyle(
            color: dark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(width: 5),

        const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: grey,
          size: 20,
        ),
      ],
    );
  }

  // ============================================================
  // EQUIPMENT LIST
  // ============================================================

  Widget _buildEquipmentList() {
    return Column(
      children: filteredEquipment.map(
        (item) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: 14,
            ),
            child: _buildEquipmentCard(item),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // EQUIPMENT CARD
  // ============================================================

  Widget _buildEquipmentCard(
    EquipmentItem item,
  ) {
    final int usable =
        item.total - item.damaged;

    Color statusColor;
    Color statusBackground;

    if (item.status == 'Available') {
      statusColor = green;
      statusBackground =
          const Color(0xFFEAF7F1);
    } else if (item.status == 'In Use') {
      statusColor =
          const Color(0xFFF47A24);
      statusBackground =
          const Color(0xFFFFF0D9);
    } else {
      statusColor =
          const Color(0xFFE53935);
      statusBackground =
          const Color(0xFFFFE5E5);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          // Equipment image
          Container(
            width: 120,
            height: 125,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(13),
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: green,
                      size: 45,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 15),

          // Equipment information
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: dark,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.more_vert_rounded,
                      color: grey,
                      size: 22,
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  'ID: ${item.id}   •   ${item.category}   •   ${item.brand}',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: grey,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    _quantityColumn(
                      'Total',
                      item.total.toString(),
                      dark,
                    ),

                    const SizedBox(width: 28),

                    _quantityColumn(
                      'Damaged',
                      item.damaged.toString(),
                      const Color(0xFFE53935),
                    ),

                    const SizedBox(width: 28),

                    _quantityColumn(
                      'Usable',
                      usable.toString(),
                      green,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Availability
          Container(
            width: 105,
            padding:
                const EdgeInsets.only(
              left: 13,
            ),
            decoration:
                const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: border,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        statusBackground,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status,
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Available',
                  style: TextStyle(
                    color: grey,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  item.available.toString(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                Text(
                  '/ ${item.total} Total',
                  style: const TextStyle(
                    color: grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUANTITY COLUMN
  // ============================================================

  Widget _quantityColumn(
    String title,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: grey,
            fontSize: 10,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

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
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            Icons.home_outlined,
            'Home',
            false,
          ),

          _navItem(
            Icons.calendar_month_outlined,
            'Bookings',
            false,
          ),

          _navItem(
            Icons.inventory_2_rounded,
            'Equipment',
            true,
          ),

          _navItem(
            Icons.notifications_none_rounded,
            'Alerts',
            false,
            badge: '2',
          ),

          _navItem(
            Icons.more_horiz_rounded,
            'More',
            false,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAV ITEM
  // ============================================================

  Widget _navItem(
    IconData icon,
    String title,
    bool selected, {
    String? badge,
  }) {
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Stack(
            clipBehavior:
                Clip.none,
            children: [
              Icon(
                icon,
                color: selected
                    ? green
                    : grey,
                size: 24,
              ),

              if (badge != null)
                Positioned(
                  right: -8,
                  top: -7,
                  child: _badge(badge),
                ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: TextStyle(
              color: selected
                  ? green
                  : grey,
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

  // ============================================================
  // BADGE
  // ============================================================

  Widget _badge(String text) {
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
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }
}

// ================================================================
// EQUIPMENT MODEL
// ================================================================

class EquipmentItem {
  final String name;
  final String id;
  final String category;
  final String brand;

  final int total;
  final int damaged;
  final int available;

  final String status;

  final String imagePath;

  const EquipmentItem({
    required this.name,
    required this.id,
    required this.category,
    required this.brand,
    required this.total,
    required this.damaged,
    required this.available,
    required this.status,
    required this.imagePath,
  });
}