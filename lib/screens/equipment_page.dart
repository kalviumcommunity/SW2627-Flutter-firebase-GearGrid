import 'package:cloud_firestore/cloud_firestore.dart';
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

  final TextEditingController searchController =
      TextEditingController();

  final List<String> categories = [
    'All',
    'Sound',
    'Lighting',
    'Furniture',
  ];

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTER EQUIPMENT
  // ============================================================

  List<EquipmentItem> _filterEquipment(
    List<EquipmentItem> equipment,
  ) {
    List<EquipmentItem> result = equipment;

    // CATEGORY FILTER
    if (selectedCategory != 0) {
      final selected =
          categories[selectedCategory].toLowerCase();

      result = result.where((item) {
        return item.category.toLowerCase() == selected;
      }).toList();
    }

    // SEARCH FILTER
    final search =
        searchController.text.trim().toLowerCase();

    if (search.isNotEmpty) {
      result = result.where((item) {
        return item.name
                .toLowerCase()
                .contains(search) ||
            item.brand
                .toLowerCase()
                .contains(search) ||
            item.id
                .toLowerCase()
                .contains(search);
      }).toList();
    }

    return result;
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('equipment')
                    .orderBy(
                      'createdAt',
                      descending: true,
                    )
                    .snapshots(),

                builder: (
                  context,
                  snapshot,
                ) {
                  // ------------------------------------------------
                  // LOADING
                  // ------------------------------------------------

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: green,
                      ),
                    );
                  }

                  // ------------------------------------------------
                  // ERROR
                  // ------------------------------------------------

                  if (snapshot.hasError) {
                    return _buildErrorState(
                      snapshot.error.toString(),
                    );
                  }

                  // ------------------------------------------------
                  // FIRESTORE DATA
                  // ------------------------------------------------

                  final List<EquipmentItem> equipment =
                      snapshot.data?.docs
                              .map(
                                (doc) =>
                                    EquipmentItem.fromFirestore(
                                  doc,
                                ),
                              )
                              .toList() ??
                          [];

                  final filteredEquipment =
                      _filterEquipment(
                    equipment,
                  );

                  return SingleChildScrollView(
                    physics:
                        const BouncingScrollPhysics(),

                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      20,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),

                        const SizedBox(height: 26),

                        _buildPageTitle(),

                        const SizedBox(height: 24),

                        _buildSearchAndFilter(),

                        const SizedBox(height: 18),

                        _buildCategoryTabs(),

                        const SizedBox(height: 25),

                        _buildSortRow(
                          equipment.length,
                        ),

                        const SizedBox(height: 14),

                        if (filteredEquipment.isEmpty)
                          _buildEmptyState()
                        else
                          _buildEquipmentList(
                            filteredEquipment,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.red,
              size: 50,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load equipment',
              style: TextStyle(
                color: dark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Please check your Firebase connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 60,
        horizontal: 20,
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F1),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: green,
              size: 38,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'No equipment found',
            style: TextStyle(
              color: dark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            searchController.text.isNotEmpty
                ? 'Try a different search.'
                : 'Add your first equipment item.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: grey,
              fontSize: 13,
            ),
          ),
        ],
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
            borderRadius:
                BorderRadius.circular(11),
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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

        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AddEquipmentPage(),
              ),
            );

            // No manual refresh required.
            //
            // StreamBuilder is listening to Firestore,
            // so the new equipment appears automatically.
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: green,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize:
                  MainAxisSize.min,
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
                    fontWeight:
                        FontWeight.w800,
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
              borderRadius:
                  BorderRadius.circular(13),
              border: Border.all(
                color: border,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),

                const Icon(
                  Icons.search_rounded,
                  color: grey,
                  size: 27,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: TextField(
                    controller:
                        searchController,
                    decoration:
                        const InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          'Search equipment by name, brand or ID...',
                      hintStyle:
                          TextStyle(
                        color: grey,
                        fontSize: 12,
                      ),
                    ),
                    style:
                        const TextStyle(
                      color: dark,
                      fontSize: 12,
                    ),
                  ),
                ),

                if (searchController
                    .text
                    .isNotEmpty)
                  IconButton(
                    onPressed: () {
                      searchController.clear();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: grey,
                      size: 19,
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
            borderRadius:
                BorderRadius.circular(13),
            border: Border.all(
              color: border,
            ),
          ),
          child: const Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
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
                  fontWeight:
                      FontWeight.w700,
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
        scrollDirection:
            Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder:
            (_, __) {
          return const SizedBox(
            width: 12,
          );
        },
        itemBuilder:
            (context, index) {
          final bool selected =
              selectedCategory ==
                  index;

          IconData icon;

          switch (index) {
            case 0:
              icon =
                  Icons.grid_view_rounded;
              break;

            case 1:
              icon =
                  Icons.volume_up_outlined;
              break;

            case 2:
              icon =
                  Icons.lightbulb_outline_rounded;
              break;

            default:
              icon =
                  Icons.chair_outlined;
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory =
                    index;
              });
            },
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 17,
              ),
              decoration:
                  BoxDecoration(
                color: selected
                    ? green
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
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

                  const SizedBox(
                    width: 8,
                  ),

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

  Widget _buildSortRow(
    int totalItems,
  ) {
    return Row(
      children: [
        Text(
          'Total Items: $totalItems',
          style: const TextStyle(
            color: grey,
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const Spacer(),

        const Text(
          'Sort by: ',
          style: TextStyle(
            color: dark,
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
          ),
        ),

        const Text(
          'Name (A-Z)',
          style: TextStyle(
            color: dark,
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
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

  Widget _buildEquipmentList(
    List<EquipmentItem> equipment,
  ) {
    return Column(
      children: equipment.map(
        (item) {
          return Padding(
            padding:
                const EdgeInsets.only(
              bottom: 14,
            ),
            child:
                _buildEquipmentCard(
              item,
            ),
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
        (item.total - item.damaged)
            .clamp(0, item.total);

    Color statusColor;
    Color statusBackground;

    if (usable > 0) {
      statusColor = green;
      statusBackground =
          const Color(0xFFEAF7F1);
    } else if (item.damaged > 0) {
      statusColor =
          const Color(0xFFE53935);
      statusBackground =
          const Color(0xFFFFE5E5);
    } else {
      statusColor =
          const Color(0xFFF47A24);
      statusBackground =
          const Color(0xFFFFF0D9);
    }

    return Container(
      padding:
          const EdgeInsets.all(14),
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
          // ======================================================
          // EQUIPMENT IMAGE
          // ======================================================

          Container(
            width: 120,
            height: 125,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF8F9FA),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(13),
              child: item.imageUrl != null &&
                      item.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _assetFallback(
                          item,
                        );
                      },
                    )
                  : _assetFallback(
                      item,
                    ),
            ),
          ),

          const SizedBox(width: 15),

          // ======================================================
          // EQUIPMENT INFORMATION
          // ======================================================

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
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color: dark,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons
                          .more_vert_rounded,
                      color: grey,
                      size: 22,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 7,
                ),

                Text(
                  'ID: ${item.id}   •   ${item.category}   •   ${item.brand}',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: grey,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                Row(
                  children: [
                    _quantityColumn(
                      'Total',
                      item.total
                          .toString(),
                      dark,
                    ),

                    const SizedBox(
                      width: 28,
                    ),

                    _quantityColumn(
                      'Damaged',
                      item.damaged
                          .toString(),
                      const Color(
                        0xFFE53935,
                      ),
                    ),

                    const SizedBox(
                      width: 28,
                    ),

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

          // ======================================================
          // AVAILABILITY
          // ======================================================

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
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        statusBackground,
                    borderRadius:
                        BorderRadius
                            .circular(
                      8,
                    ),
                  ),
                  child: Text(
                    item.status,
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          statusColor,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                const Text(
                  'Available',
                  style: TextStyle(
                    color: grey,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  item.available
                      .toString(),
                  style: TextStyle(
                    color:
                        statusColor,
                    fontSize: 24,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                Text(
                  '/ ${item.total} Total',
                  style:
                      const TextStyle(
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
  // ASSET IMAGE FALLBACK
  // ============================================================

  Widget _assetFallback(
    EquipmentItem item,
  ) {
    if (item.imagePath == null ||
        item.imagePath!.isEmpty) {
      return const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: green,
          size: 45,
        ),
      );
    }

    return Image.asset(
      item.imagePath!,
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
      padding:
          const EdgeInsets.fromLTRB(
        8,
        8,
        8,
        12,
      ),
      decoration:
          const BoxDecoration(
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
                  child: _badge(
                    badge,
                  ),
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

  Widget _badge(
    String text,
  ) {
    return Container(
      width: 17,
      height: 17,
      alignment:
          Alignment.center,
      decoration:
          const BoxDecoration(
        color:
            Color(0xFFE53935),
        shape:
            BoxShape.circle,
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          color:
              Colors.white,
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

  final String? imagePath;
  final String? imageUrl;

  const EquipmentItem({
    required this.name,
    required this.id,
    required this.category,
    required this.brand,
    required this.total,
    required this.damaged,
    required this.available,
    required this.status,
    this.imagePath,
    this.imageUrl,
  });

  // ============================================================
  // FIRESTORE → EQUIPMENT MODEL
  // ============================================================

  factory EquipmentItem.fromFirestore(
    DocumentSnapshot document,
  ) {
    final data =
        document.data()
            as Map<String, dynamic>? ??
        {};

    final int total =
        _toInt(data['totalQuantity']);

    final int damaged =
        _toInt(data['damagedQuantity']);

    final int available =
        _toInt(
          data['availableQuantity'],
        ).clamp(0, total);

    final String name =
        (data['name'] ?? 'Unnamed Equipment')
            .toString();

    final String category =
        _formatCategory(
      data['category'],
    );

    final String status =
        _getStatus(
      data,
      available,
      damaged,
    );

    return EquipmentItem(
      name: name,
      id: (data['equipmentId'] ??
              document.id)
          .toString(),
      category: category,
      brand:
          (data['brand'] ?? 'Unknown')
              .toString(),
      total: total,
      damaged: damaged,
      available: available,
      status: status,
      imageUrl:
          data['imageUrl']?.toString(),
    );
  }

  // ============================================================
  // INTEGER CONVERSION
  // ============================================================

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // CATEGORY FORMAT
  // ============================================================

  static String _formatCategory(
    dynamic value,
  ) {
    final category =
        value?.toString() ?? '';

    if (category.isEmpty) {
      return 'Unknown';
    }

    return category[0].toUpperCase() +
        category.substring(1).toLowerCase();
  }

  // ============================================================
  // STATUS
  // ============================================================

  static String _getStatus(
    Map<String, dynamic> data,
    int available,
    int damaged,
  ) {
    final savedStatus =
        data['status']?.toString();

    if (savedStatus != null &&
        savedStatus.isNotEmpty) {
      return savedStatus;
    }

    if (available <= 0 &&
        damaged > 0) {
      return 'Maintenance';
    }

    if (available <= 0) {
      return 'In Use';
    }

    return 'Available';
  }
}