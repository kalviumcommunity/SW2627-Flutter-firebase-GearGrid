import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Edit Equipment Page — pre-fills all fields from an existing Firestore document.
/// Call with the Firestore document ID so we can update the right doc.
class EditEquipmentPage extends StatefulWidget {
  final String firestoreDocId; // actual Firestore doc ID
  final String name;
  final String equipmentId;
  final String category;
  final String brand;
  final int total;
  final int damaged;
  final String? imageUrl;

  const EditEquipmentPage({
    super.key,
    required this.firestoreDocId,
    required this.name,
    required this.equipmentId,
    required this.category,
    required this.brand,
    required this.total,
    required this.damaged,
    this.imageUrl,
  });

  @override
  State<EditEquipmentPage> createState() => _EditEquipmentPageState();
}

class _EditEquipmentPageState extends State<EditEquipmentPage> {
  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);
  static const Color red = Color(0xFFE53935);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController idController;
  late final TextEditingController brandController;
  late final TextEditingController totalController;
  late final TextEditingController damagedController;

  late String selectedCategory;

  /// New image picked by user (bytes)
  Uint8List? _imageBytes;
  String? _imageName;

  /// Whether we cleared the existing image
  bool _imageRemoved = false;

  bool isSaving = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    idController = TextEditingController(text: widget.equipmentId);
    brandController = TextEditingController(text: widget.brand);
    totalController =
        TextEditingController(text: widget.total.toString());
    damagedController =
        TextEditingController(text: widget.damaged.toString());
    selectedCategory = _normaliseCategory(widget.category);
  }

  String _normaliseCategory(String raw) {
    const valid = ['Sound', 'Lighting', 'Furniture'];
    final cap =
        raw.isEmpty ? '' : raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    return valid.contains(cap) ? cap : 'Sound';
  }

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    brandController.dispose();
    totalController.dispose();
    damagedController.dispose();
    super.dispose();
  }

  // ── Pick image ────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = image.name;
        _imageRemoved = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to pick image: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
      _imageRemoved = true;
    });
  }

  // ── Upload helper (web-safe, with timeout) ────────────────────────
  Future<String?> _uploadNewImage(String docId) async {
    if (_imageBytes == null) return null;
    try {
      final String ext =
          (_imageName?.split('.').last.toLowerCase()) ?? 'jpg';
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$ext';

      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('equipment')
          .child(docId)
          .child(fileName);

      final UploadTask task = ref.putData(
        _imageBytes!,
        SettableMetadata(contentType: 'image/$ext'),
      );

      final TaskSnapshot snap =
          await task.timeout(const Duration(seconds: 30));
      return await snap.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image upload skipped during edit: $e');
      return null; // save without new image
    }
  }

  // ── Save ──────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final int total = int.tryParse(totalController.text.trim()) ?? 0;
    final int damaged = int.tryParse(damagedController.text.trim()) ?? 0;

    if (damaged < 0) {
      _snack('Damaged quantity cannot be negative.');
      return;
    }
    if (damaged > total) {
      _snack('Damaged cannot be greater than total.');
      return;
    }

    setState(() => isSaving = true);

    try {
      // Determine final imageUrl
      String? finalImageUrl = widget.imageUrl; // start from existing

      if (_imageBytes != null) {
        // User picked a new image — try to upload
        final uploaded = await _uploadNewImage(widget.firestoreDocId);
        if (uploaded != null) finalImageUrl = uploaded;
        // if upload timed out, keep old imageUrl
      } else if (_imageRemoved) {
        finalImageUrl = null; // user explicitly removed it
      }

      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(widget.firestoreDocId)
          .update({
        'name': nameController.text.trim(),
        'equipmentId': idController.text.trim(),
        'category': selectedCategory.toLowerCase(),
        'brand': brandController.text.trim(),
        'totalQuantity': total,
        'damagedQuantity': damaged,
        'availableQuantity': total - damaged,
        'imageUrl': finalImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment updated successfully.'),
          backgroundColor: green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to update: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  // ── UI ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: dark),
          onPressed: isSaving ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Equipment',
          style: TextStyle(
              color: dark, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Scrollable form ──────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Equipment Details',
                        style: TextStyle(
                            color: dark,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Update the details of this equipment item.',
                        style: TextStyle(color: grey, fontSize: 12.5),
                      ),
                      const SizedBox(height: 28),

                      // Name
                      _label('Equipment Name', required: true),
                      _textField(
                        controller: nameController,
                        hint: 'Enter equipment name',
                        icon: Icons.inventory_2_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Equipment name is required'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Equipment ID
                      _label('Equipment ID'),
                      _textField(
                        controller: idController,
                        hint: 'Example: AUD-007',
                        icon: Icons.tag_rounded,
                      ),
                      const SizedBox(height: 20),

                      // Category
                      _label('Category', required: true),
                      _categoryDropdown(),
                      const SizedBox(height: 20),

                      // Brand
                      _label('Brand'),
                      _textField(
                        controller: brandController,
                        hint: 'Enter brand name',
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Quantity row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _label('Total Quantity',
                                    required: true),
                                _textField(
                                  controller: totalController,
                                  hint: '0',
                                  icon: Icons.numbers_rounded,
                                  keyboardType:
                                      TextInputType.number,
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n <= 0) {
                                      return 'Enter quantity';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _label('Damaged Quantity'),
                                _textField(
                                  controller: damagedController,
                                  hint: '0',
                                  icon: Icons.build_outlined,
                                  keyboardType:
                                      TextInputType.number,
                                  validator: (v) {
                                    final n =
                                        int.tryParse(v ?? '0');
                                    if (n == null || n < 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Image
                      _label('Equipment Image'),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: isSaving ? null : _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: const Color(0xFFD9DEE5)),
                          ),
                          child: _buildImagePreview(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_hasImage)
                        TextButton.icon(
                          onPressed: isSaving ? null : _removeImage,
                          icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: red,
                              size: 18),
                          label: const Text('Remove image',
                              style: TextStyle(color: red)),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── Bottom buttons ───────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: Color(0xFFECEFF1))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize:
                              const Size(double.infinity, 52),
                          side: const BorderSide(color: green),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(13)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: green,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize:
                              const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(13)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5),
                              )
                            : const Text('Save Changes',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasImage =>
      _imageBytes != null ||
      (!_imageRemoved &&
          widget.imageUrl != null &&
          widget.imageUrl!.isNotEmpty);

  // ── Image preview ─────────────────────────────────────────────────
  Widget _buildImagePreview() {
    // New image picked
    if (_imageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.memory(_imageBytes!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _removeImage,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    // Existing network image
    if (!_imageRemoved &&
        widget.imageUrl != null &&
        widget.imageUrl!.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              widget.imageUrl!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Change',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // No image
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: green, size: 27),
        ),
        const SizedBox(height: 10),
        const Text('Tap to add image',
            style: TextStyle(
                color: dark,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('PNG or JPG',
            style: TextStyle(color: grey, fontSize: 10.5)),
      ],
    );
  }

  // ── Form helpers ──────────────────────────────────────────────────
  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(text,
              style: const TextStyle(
                  color: dark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          if (required) ...[
            const SizedBox(width: 4),
            const Text('*',
                style: TextStyle(color: red, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: dark, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: grey, fontSize: 13),
        prefixIcon: Icon(icon, color: grey, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: red),
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    const categories = ['Sound', 'Lighting', 'Furniture'];
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      onChanged: (v) => setState(() => selectedCategory = v!),
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      decoration: InputDecoration(
        prefixIcon:
            const Icon(Icons.category_outlined, color: grey, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: green, width: 1.5),
        ),
      ),
    );
  }
}
