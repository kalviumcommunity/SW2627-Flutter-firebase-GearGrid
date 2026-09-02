import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/booking_draft_provider.dart';
import 'booking_summary_page.dart';

// Note: Re-using a simple mock model for UI building
class CatalogItem {
  final String id;
  final String name;
  final String category;
  final String brand;
  final int available;
  final String imagePath;

  CatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.available,
    required this.imagePath,
  });
}

class AvailabilityCatalogPage extends ConsumerStatefulWidget {
  const AvailabilityCatalogPage({super.key});

  @override
  ConsumerState<AvailabilityCatalogPage> createState() => _AvailabilityCatalogPageState();
}

class _AvailabilityCatalogPageState extends ConsumerState<AvailabilityCatalogPage> {
  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);

  int selectedCategory = 0;

  final List<String> categories = ['All', 'Sound', 'Lighting', 'Furniture'];

  final List<CatalogItem> equipment = [
    CatalogItem(
      id: 'AUD-001',
      name: 'JBL PA Speaker',
      category: 'Sound',
      brand: 'JBL',
      available: 7,
      imagePath: 'assets/equipment/jbl_pa_speaker.png',
    ),
    CatalogItem(
      id: 'LGT-002',
      name: 'Beam 230 Moving Head',
      category: 'Lighting',
      brand: 'Philips',
      available: 10,
      imagePath: 'assets/equipment/beam_230_moving_head.png',
    ),
    CatalogItem(
      id: 'AUD-003',
      name: 'Shure SM58 Microphone',
      category: 'Sound',
      brand: 'Shure',
      available: 1,
      imagePath: 'assets/equipment/shure_sm58_microphone.png',
    ),
    CatalogItem(
      id: 'STG-004',
      name: 'Aluminum Truss 12ft',
      category: 'Lighting',
      brand: 'Global Truss',
      available: 18,
      imagePath: 'assets/equipment/aluminum_truss_12ft.png',
    ),
    CatalogItem(
      id: 'FUR-005',
      name: 'Banquet Chair',
      category: 'Furniture',
      brand: 'GearGrid',
      available: 5,
      imagePath: 'assets/equipment/banquet_chair.png',
    ),
  ];

  List<CatalogItem> get filteredEquipment {
    if (selectedCategory == 0) return equipment;
    final category = categories[selectedCategory];
    return equipment.where((item) => item.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    final totalItemsSelected = draft.selectedItems.values.fold(0, (prev, amount) => prev + amount);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Equipment',
          style: TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchAndFilter(),
                    const SizedBox(height: 18),
                    _buildCategoryTabs(),
                    const SizedBox(height: 25),
                    _buildEquipmentList(),
                  ],
                ),
              ),
            ),
            
            if (totalItemsSelected > 0)
              _buildBottomCartBar(totalItemsSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: border),
            ),
            child: const Row(
              children: [
                SizedBox(width: 16),
                Icon(Icons.search_rounded, color: grey, size: 27),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search equipment...',
                    style: TextStyle(color: grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final selected = selectedCategory == index;
          return GestureDetector(
            onTap: () {
              setState(() => selectedCategory = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? green : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: selected ? green : border),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: selected ? Colors.white : dark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEquipmentList() {
    return Column(
      children: filteredEquipment.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildEquipmentCard(item),
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentCard(CatalogItem item) {
    final draft = ref.watch(bookingDraftProvider);
    final selectedQuantity = draft.selectedItems[item.id] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(13),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                item.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.inventory_2_outlined, color: green, size: 30),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: const TextStyle(color: grey, fontSize: 11),
                ),
                const SizedBox(height: 10),
                Text(
                  '${item.available} Available',
                  style: const TextStyle(
                    color: green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity Controls
          Row(
            children: [
              _buildIconButton(
                icon: Icons.remove,
                onTap: selectedQuantity > 0 
                  ? () => ref.read(bookingDraftProvider.notifier).updateItemQuantity(item.id, selectedQuantity - 1)
                  : null,
              ),
              SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    selectedQuantity.toString(),
                    style: const TextStyle(
                      color: dark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _buildIconButton(
                icon: Icons.add,
                onTap: selectedQuantity < item.available
                  ? () => ref.read(bookingDraftProvider.notifier).updateItemQuantity(item.id, selectedQuantity + 1)
                  : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, VoidCallback? onTap}) {
    final bool disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF5F7F8) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: disabled ? border : green.withOpacity(0.5)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: disabled ? const Color(0xFFB0B7C3) : green,
        ),
      ),
    );
  }

  Widget _buildBottomCartBar(int totalItemsSelected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: border),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Items',
                  style: TextStyle(color: grey, fontSize: 13),
                ),
                Text(
                  totalItemsSelected.toString(),
                  style: const TextStyle(
                    color: dark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingSummaryPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Review Booking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
