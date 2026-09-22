import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/equipment.dart';
import '../theme/admin_theme.dart';

class EquipmentEditorDialog extends StatefulWidget {
  const EquipmentEditorDialog({
    this.equipment,
    required this.onSave,
    super.key,
  });

  final Equipment? equipment;
  final Future<void> Function(Equipment) onSave;

  @override
  State<EquipmentEditorDialog> createState() => _EquipmentEditorDialogState();
}

class _EquipmentEditorDialogState extends State<EquipmentEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _profileController;
  late final TextEditingController _unitsController;
  late final TextEditingController _priceController;

  String? _currentImageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment?.name ?? '');
    _categoryController = TextEditingController(text: widget.equipment?.category ?? '');
    _descriptionController = TextEditingController(text: widget.equipment?.description ?? '');
    _profileController = TextEditingController(text: widget.equipment?.powerProfile ?? '');
    _unitsController = TextEditingController(text: '${widget.equipment?.totalUnits ?? 8}');
    _priceController = TextEditingController(text: '${widget.equipment?.pricePerUnit ?? 1500.0}');
    _currentImageUrl = widget.equipment?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _profileController.dispose();
    _unitsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploading) return;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _isUploading = true);
        final bytes = await pickedFile.readAsBytes();
        final ext = pickedFile.name.split('.').last;
        final fileName = 'equipment_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final ref = FirebaseStorage.instance.ref().child('equipment_images').child(fileName);
        final metadata = SettableMetadata(contentType: 'image/$ext');
        final uploadTask = ref.putData(bytes, metadata);
        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        if (!mounted) return;
        setState(() {
          _currentImageUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();
    final profile = _profileController.text.trim();
    final units = int.tryParse(_unitsController.text.trim());
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    if (name.isEmpty || category.isEmpty || description.isEmpty || profile.isEmpty || units == null || units < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter complete equipment details with a valid unit count.')));
      return;
    }

    final savedEquipment = widget.equipment == null
        ? Equipment(
            id: '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            category: category,
            description: description,
            powerProfile: profile,
            totalUnits: units,
            accent: const Color(0xFF52D1FF),
            pricePerUnit: price,
            imageUrl: _currentImageUrl,
          )
        : widget.equipment!.copyWith(
            name: name,
            category: category,
            description: description,
            powerProfile: profile,
            totalUnits: units,
            pricePerUnit: price,
            imageUrl: _currentImageUrl,
          );

    setState(() => _isSaving = true);
    try {
      await widget.onSave(savedEquipment);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save equipment: $error')));
      }
    }
  }

  Widget _buildEditorField(String label, TextEditingController controller, {bool isNumber = false, bool isDecimal = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AdminTheme.muted,
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber 
              ? TextInputType.numberWithOptions(decimal: isDecimal)
              : TextInputType.text,
          style: AdminTheme.body(color: AdminTheme.ink),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AdminTheme.surface,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AdminTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(widget.equipment == null ? 'Add Equipment' : 'Edit Equipment', style: AdminTheme.head(size: 22)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: Container(
                height: 120,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AdminTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminTheme.border),
                  image: _currentImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_currentImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _currentImageUrl == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isUploading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.ink))
                              : const Icon(Icons.add_photo_alternate_outlined, color: AdminTheme.muted, size: 32),
                          const SizedBox(height: 8),
                          Text(_isUploading ? 'Uploading...' : 'Tap to upload image', style: AdminTheme.body()),
                        ],
                      )
                    : _isUploading
                        ? Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: const Center(child: CircularProgressIndicator(color: AdminTheme.white)),
                          )
                        : Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                backgroundColor: AdminTheme.ink.withValues(alpha: 0.7),
                                radius: 14,
                                child: const Icon(Icons.edit, size: 14, color: AdminTheme.white),
                              ),
                            ),
                          ),
              ),
            ),
            _buildEditorField('EQUIPMENT NAME', _nameController),
            const SizedBox(height: 12),
            _buildEditorField('CATEGORY', _categoryController),
            const SizedBox(height: 12),
            _buildEditorField('TOTAL UNITS', _unitsController, isNumber: true),
            const SizedBox(height: 12),
            _buildEditorField('PRICE PER UNIT (₹)', _priceController, isNumber: true, isDecimal: true),
            const SizedBox(height: 12),
            _buildEditorField('POWER OR RIG PROFILE', _profileController),
            const SizedBox(height: 12),
            _buildEditorField('DESCRIPTION', _descriptionController, maxLines: 3),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: AdminTheme.body(color: AdminTheme.muted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.ink,
            foregroundColor: AdminTheme.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: (_isUploading || _isSaving) ? null : _save,
          child: _isSaving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
