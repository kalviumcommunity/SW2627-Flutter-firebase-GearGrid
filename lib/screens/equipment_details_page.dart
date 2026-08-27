import 'package:flutter/material.dart';

class EquipmentDetailsPage extends StatelessWidget {
  const EquipmentDetailsPage({
    super.key,
    required this.name,
    required this.id,
    required this.category,
    required this.brand,
    required this.total,
    required this.damaged,
    required this.available,
    required this.status,
    this.imageUrl,
    this.imagePath,
  });

  // ============================================================
  // EQUIPMENT DATA
  // ============================================================

  final String name;
  final String id;
  final String category;
  final String brand;

  final int total;
  final int damaged;
  final int available;

  final String status;

  final String? imageUrl;
  final String? imagePath;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: dark,
            size: 27,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Equipment Details',
          style: TextStyle(
            color: dark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: dark,
              size: 26,
            ),
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),

                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  30,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    // ------------------------------------------------
                    // IMAGE
                    // ------------------------------------------------

                    _buildEquipmentImage(),

                    const SizedBox(height: 20),

                    // ------------------------------------------------
                    // NAME + STATUS
                    // ------------------------------------------------

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style:
                                    const TextStyle(
                                  color: dark,
                                  fontSize: 25,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),

                              const SizedBox(
                                height: 7,
                              ),

                              Text(
                                'ID: $id   •   $category   •   $brand',
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    const TextStyle(
                                  color: grey,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        _statusBadge(),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ------------------------------------------------
                    // QUANTITY CARD
                    // ------------------------------------------------

                    _buildQuantityCard(),

                    const SizedBox(height: 18),

                    // ------------------------------------------------
                    // DESCRIPTION
                    // ------------------------------------------------

                    _buildDescriptionCard(),

                    const SizedBox(height: 18),

                    // ------------------------------------------------
                    // EQUIPMENT INFORMATION
                    // ------------------------------------------------

                    _buildInformationCard(),

                    const SizedBox(height: 18),

                    // ------------------------------------------------
                    // TAGS
                    // ------------------------------------------------

                    _buildTagsCard(),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // ======================================================
            // BOTTOM BUTTONS
            // ======================================================

            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EQUIPMENT IMAGE
  // ============================================================

  Widget _buildEquipmentImage() {
    return Container(
      width: double.infinity,
      height: 230,

      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: border,
        ),
      ),

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(18),

        child: _imageWidget(),
      ),
    );
  }

  Widget _imageWidget() {
    // ------------------------------------------------------------
    // FIREBASE STORAGE IMAGE
    // ------------------------------------------------------------

    if (imageUrl != null &&
        imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.contain,

        errorBuilder:
            (context, error, stackTrace) {
          return _fallbackImage();
        },
      );
    }

    // ------------------------------------------------------------
    // LOCAL ASSET IMAGE
    // ------------------------------------------------------------

    if (imagePath != null &&
        imagePath!.isNotEmpty) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.contain,

        errorBuilder:
            (context, error, stackTrace) {
          return _fallbackImage();
        },
      );
    }

    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: green,
        size: 70,
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge() {
    Color statusColor;
    Color statusBackground;

    if (status.toLowerCase() ==
        'available') {
      statusColor = green;
      statusBackground =
          const Color(0xFFEAF7F1);
    } else if (status.toLowerCase() ==
        'maintenance') {
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
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: statusBackground,
        borderRadius:
            BorderRadius.circular(9),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Container(
            width: 7,
            height: 7,

            decoration:
                BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 6),

          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUANTITY CARD
  // ============================================================

  Widget _buildQuantityCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 10,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

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
        children: [
          Expanded(
            child: _quantityItem(
              icon:
                  Icons.category_outlined,
              title: 'Category',
              value: category,
              color: green,
            ),
          ),

          Container(
            width: 1,
            height: 55,
            color: border,
          ),

          Expanded(
            child: _quantityItem(
              icon:
                  Icons.inventory_2_outlined,
              title: 'Total Quantity',
              value: total.toString(),
              color: dark,
            ),
          ),

          Container(
            width: 1,
            height: 55,
            color: border,
          ),

          Expanded(
            child: _quantityItem(
              icon:
                  Icons.check_circle_outline,
              title: 'Available',
              value: available.toString(),
              color: green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: green,
          size: 21,
        ),

        const SizedBox(height: 7),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: grey,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: border,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Description',
            style: TextStyle(
              color: dark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 9),

          const Text(
            'No description has been added for this equipment yet.',
            style: TextStyle(
              color: grey,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: border,
        ),
      ),

      child: Column(
        children: [
          _informationRow(
            icon:
                Icons.badge_outlined,
            title: 'Equipment ID',
            value: id,
          ),

          _informationDivider(),

          _informationRow(
            icon:
                Icons.business_outlined,
            title: 'Brand',
            value: brand,
          ),

          _informationDivider(),

          _informationRow(
            icon:
                Icons.category_outlined,
            title: 'Category',
            value: category,
          ),

          _informationDivider(),

          _informationRow(
            icon:
                Icons.build_outlined,
            title: 'Damaged Quantity',
            value: damaged.toString(),
            valueColor:
                damaged > 0
                    ? const Color(0xFFE53935)
                    : green,
          ),
        ],
      ),
    );
  }

  Widget _informationRow({
    required IconData icon,
    required String title,
    required String value,
    Color valueColor = dark,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color:
                  const Color(0xFFF3F6F5),

              borderRadius:
                  BorderRadius.circular(11),
            ),

            child: Icon(
              icon,
              color: green,
              size: 22,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: grey,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _informationDivider() {
    return const Divider(
      height: 1,
      color: border,
    );
  }

  // ============================================================
  // TAGS
  // ============================================================

  Widget _buildTagsCard() {
    final List<String> tags =
        _getTags();

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: border,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Tags',
            style: TextStyle(
              color: dark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 9,
            runSpacing: 9,

            children: tags.map(
              (tag) {
                return Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      9,
                    ),

                    border:
                        Border.all(
                      color: green,
                    ),
                  ),

                  child: Text(
                    tag,
                    style:
                        const TextStyle(
                      color: green,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  List<String> _getTags() {
    switch (category.toLowerCase()) {
      case 'sound':
        return [
          'Sound',
          'Audio',
        ];

      case 'lighting':
        return [
          'Lighting',
          'Stage',
        ];

      case 'furniture':
        return [
          'Furniture',
          'Event',
        ];

      default:
        return [
          category,
        ];
    }
  }

  // ============================================================
  // BOTTOM BUTTONS
  // ============================================================

  Widget _buildBottomButtons(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16,
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
        children: [
          // ------------------------------------------------------
          // EDIT
          // ------------------------------------------------------

          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Edit equipment will be added next.',
                    ),
                  ),
                );
              },

              icon: const Icon(
                Icons.edit_outlined,
                size: 20,
              ),

              label: const Text(
                'Edit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              style:
                  OutlinedButton.styleFrom(
                foregroundColor: green,

                minimumSize:
                    const Size(
                  double.infinity,
                  52,
                ),

                side:
                    const BorderSide(
                  color: green,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ------------------------------------------------------
          // CHANGE QUANTITY
          // ------------------------------------------------------

          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showChangeQuantityDialog(
                  context,
                );
              },

              icon: const Icon(
                Icons.inventory_2_outlined,
                size: 20,
              ),

              label: const Text(
                'Change Quantity',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor:
                    Colors.white,
                elevation: 0,

                minimumSize:
                    const Size(
                  double.infinity,
                  52,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MORE OPTIONS
  // ============================================================

  void _showMoreOptions(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,

      backgroundColor:
          Colors.white,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                Container(
                  width: 40,
                  height: 4,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFD9DEE5,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                ListTile(
                  leading:
                      const Icon(
                    Icons.edit_outlined,
                    color: green,
                  ),

                  title:
                      const Text(
                    'Edit Equipment',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Edit equipment will be added next.',
                        ),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading:
                      const Icon(
                    Icons.delete_outline,
                    color:
                        Colors.red,
                  ),

                  title:
                      const Text(
                    'Delete Equipment',
                    style:
                        TextStyle(
                      color:
                          Colors.red,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _showDeleteMessage(
                      context,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CHANGE QUANTITY DIALOG
  // ============================================================

  void _showChangeQuantityDialog(
    BuildContext context,
  ) {
    final TextEditingController
        quantityController =
        TextEditingController(
      text: total.toString(),
    );

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor:
              Colors.white,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),

          title: const Text(
            'Change Quantity',
            style: TextStyle(
              color: dark,
              fontSize: 18,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          content: TextField(
            controller:
                quantityController,

            keyboardType:
                TextInputType.number,

            decoration:
                InputDecoration(
              labelText:
                  'Total Quantity',

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },

              child:
                  const Text(
                'Cancel',
                style:
                    TextStyle(
                  color: grey,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Quantity update will be connected to Firebase next.',
                    ),
                    backgroundColor:
                        green,
                  ),
                );
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    green,
              ),

              child:
                  const Text(
                'Save',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DELETE MESSAGE
  // ============================================================

  void _showDeleteMessage(
    BuildContext context,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Delete functionality will be connected next.',
        ),
      ),
    );
  }
}  