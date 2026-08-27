import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddEquipmentPage extends StatefulWidget {
  const AddEquipmentPage({super.key});

  @override
  State<AddEquipmentPage> createState() =>
      _AddEquipmentPageState();
}

class _AddEquipmentPageState extends State<AddEquipmentPage> {
  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController idController =
      TextEditingController();

  final TextEditingController brandController =
      TextEditingController();

  final TextEditingController totalController =
      TextEditingController();

  final TextEditingController damagedController =
      TextEditingController(text: '0');

  String selectedCategory = 'Sound';

  File? selectedImage;

  bool isSaving = false;

  final ImagePicker imagePicker = ImagePicker();

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    brandController.dispose();
    totalController.dispose();
    damagedController.dispose();

    super.dispose();
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      setState(() {
        selectedImage = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select image: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // REMOVE IMAGE
  // ============================================================

  void _removeImage() {
    setState(() {
      selectedImage = null;
    });
  }

  // ============================================================
  // UPLOAD IMAGE TO FIREBASE STORAGE
  // ============================================================

  Future<String?> _uploadImage(String equipmentId) async {
    if (selectedImage == null) {
      return null;
    }

    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final Reference storageReference =
        FirebaseStorage.instance
            .ref()
            .child('equipment')
            .child(equipmentId)
            .child(fileName);

    final UploadTask uploadTask =
        storageReference.putFile(selectedImage!);

    final TaskSnapshot snapshot =
        await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  // ============================================================
  // SUBMIT FORM
  // ============================================================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int total =
        int.tryParse(
              totalController.text.trim(),
            ) ??
            0;

    final int damaged =
        int.tryParse(
              damagedController.text.trim(),
            ) ??
            0;

    if (damaged < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Damaged quantity cannot be negative.',
          ),
        ),
      );

      return;
    }

    if (damaged > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Damaged quantity cannot be greater than total quantity.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    String? uploadedImagePath;

    try {
      // --------------------------------------------------------
      // CREATE FIRESTORE DOCUMENT REFERENCE
      // --------------------------------------------------------

      final DocumentReference equipmentReference =
          FirebaseFirestore.instance
              .collection('equipment')
              .doc();

      final String firestoreId =
          equipmentReference.id;

      // --------------------------------------------------------
      // UPLOAD IMAGE
      // --------------------------------------------------------

      String? imageUrl;

      if (selectedImage != null) {
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}.jpg';

        final Reference storageReference =
            FirebaseStorage.instance
                .ref()
                .child('equipment')
                .child(firestoreId)
                .child(fileName);

        uploadedImagePath =
            storageReference.fullPath;

        final UploadTask uploadTask =
            storageReference.putFile(selectedImage!);

        final TaskSnapshot snapshot =
            await uploadTask;

        imageUrl =
            await snapshot.ref.getDownloadURL();
      }

      // --------------------------------------------------------
      // SAVE EQUIPMENT TO FIRESTORE
      // --------------------------------------------------------

      final Map<String, dynamic> equipmentData = {
        'name': nameController.text.trim(),

        'equipmentId':
            idController.text.trim(),

        'category':
            selectedCategory.toLowerCase(),

        'brand':
            brandController.text.trim(),

        'totalQuantity':
            total,

        'damagedQuantity':
            damaged,

        'availableQuantity':
            total - damaged,

        'imageUrl':
            imageUrl,

        'createdAt':
            FieldValue.serverTimestamp(),
      };

      await equipmentReference.set(
        equipmentData,
      );

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Equipment added successfully.',
          ),
          backgroundColor: green,
        ),
      );

      // true tells EquipmentPage that a new item was added.
      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      // --------------------------------------------------------
      // CLEAN UP IMAGE IF FIRESTORE FAILED
      // --------------------------------------------------------

      if (uploadedImagePath != null) {
        try {
          await FirebaseStorage.instance
              .ref(uploadedImagePath!)
              .delete();
        } catch (_) {
          // Ignore cleanup failure.
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add equipment: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: dark,
          ),
          onPressed: isSaving
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),

        title: const Text(
          'Add Equipment',
          style: TextStyle(
            color: dark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        centerTitle: false,
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),

                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    30,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Equipment Details',
                        style: TextStyle(
                          color: dark,
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Add a new equipment item to your inventory.',
                        style: TextStyle(
                          color: grey,
                          fontSize: 12.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      _label(
                        'Equipment Name',
                        required: true,
                      ),

                      _textField(
                        controller:
                            nameController,
                        hint:
                            'Enter equipment name',
                        icon:
                            Icons.inventory_2_outlined,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Equipment name is required';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      _label('Equipment ID'),

                      _textField(
                        controller:
                            idController,
                        hint:
                            'Example: AUD-007',
                        icon:
                            Icons.tag_rounded,
                      ),

                      const SizedBox(height: 20),

                      _label(
                        'Category',
                        required: true,
                      ),

                      _categoryDropdown(),

                      const SizedBox(height: 20),

                      _label('Brand'),

                      _textField(
                        controller:
                            brandController,
                        hint:
                            'Enter brand name',
                        icon:
                            Icons.business_outlined,
                      ),

                      const SizedBox(height: 20),

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _label(
                                  'Total Quantity',
                                  required: true,
                                ),

                                _textField(
                                  controller:
                                      totalController,
                                  hint: '0',
                                  icon:
                                      Icons.numbers_rounded,
                                  keyboardType:
                                      TextInputType
                                          .number,
                                  validator:
                                      (value) {
                                    final number =
                                        int.tryParse(
                                      value ?? '',
                                    );

                                    if (number ==
                                            null ||
                                        number <= 0) {
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
                                _label(
                                  'Damaged Quantity',
                                ),

                                _textField(
                                  controller:
                                      damagedController,
                                  hint: '0',
                                  icon:
                                      Icons.build_outlined,
                                  keyboardType:
                                      TextInputType
                                          .number,
                                  validator:
                                      (value) {
                                    final number =
                                        int.tryParse(
                                      value ?? '0',
                                    );

                                    if (number ==
                                            null ||
                                        number < 0) {
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

                      _label(
                        'Equipment Image',
                      ),

                      const SizedBox(height: 4),

                      GestureDetector(
                        onTap: isSaving
                            ? null
                            : _pickImage,

                        child: Container(
                          width:
                              double.infinity,
                          height: 145,

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFF8F9FA,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              15,
                            ),

                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xFFD9DEE5,
                              ),
                            ),
                          ),

                          child:
                              selectedImage ==
                                      null
                                  ? _imagePlaceholder()
                                  : _selectedImagePreview(),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // =================================================
              // BOTTOM BUTTONS
              // =================================================

              Container(
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
                      color: Color(
                        0xFFECEFF1,
                      ),
                    ),
                  ),
                ),

                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving
                            ? null
                            : () {
                                Navigator.pop(
                                  context,
                                );
                              },

                        style: OutlinedButton.styleFrom(
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

                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: green,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : _submitForm,

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              green,

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

                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                  strokeWidth:
                                      2.5,
                                ),
                              )
                            : const Text(
                                'Add Equipment',
                                style:
                                    TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
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

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color:
                const Color(0xFFEAF7F1),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons
                .add_photo_alternate_outlined,
            color: green,
            size: 27,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Add Equipment Image',
          style: TextStyle(
            color: dark,
            fontSize: 13,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'PNG or JPG',
          style: TextStyle(
            color: grey,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SELECTED IMAGE PREVIEW
  // ============================================================

  Widget _selectedImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius:
              BorderRadius.circular(15),
          child: Image.file(
            selectedImage!,
            width:
                double.infinity,
            height: 145,
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _removeImage,
            child: Container(
              width: 32,
              height: 32,
              decoration:
                  const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 19,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _label(
    String text, {
    bool required = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: RichText(
        text: TextSpan(
          text: text,

          style:
              const TextStyle(
            color: dark,
            fontSize: 12,
            fontWeight:
                FontWeight.w700,
          ),

          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style:
                    TextStyle(
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required
        TextEditingController
            controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    String? Function(String?)?
        validator,
  }) {
    return TextFormField(
      controller: controller,

      keyboardType:
          keyboardType,

      validator:
          validator,

      style:
          const TextStyle(
        color: dark,
        fontSize: 13,
        fontWeight:
            FontWeight.w500,
      ),

      decoration:
          InputDecoration(
        hintText: hint,

        hintStyle:
            const TextStyle(
          color: grey,
          fontSize: 12,
        ),

        prefixIcon:
            Icon(
          icon,
          color: grey,
          size: 21,
        ),

        filled: true,

        fillColor:
            Colors.white,

        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 14,
          vertical: 15,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            13,
          ),

          borderSide:
              const BorderSide(
            color: border,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            13,
          ),

          borderSide:
              const BorderSide(
            color: green,
            width: 1.5,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            13,
          ),

          borderSide:
              const BorderSide(
            color: Colors.red,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            13,
          ),

          borderSide:
              const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY DROPDOWN
  // ============================================================

  Widget _categoryDropdown() {
    return Container(
      height: 54,

      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 15,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          13,
        ),

        border:
            Border.all(
          color: border,
        ),
      ),

      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<String>(
          value:
              selectedCategory,

          isExpanded: true,

          icon:
              const Icon(
            Icons
                .keyboard_arrow_down_rounded,
            color: grey,
          ),

          items: const [
            DropdownMenuItem(
              value: 'Sound',
              child:
                  Text('Sound'),
            ),

            DropdownMenuItem(
              value: 'Lighting',
              child:
                  Text('Lighting'),
            ),

            DropdownMenuItem(
              value: 'Furniture',
              child:
                  Text('Furniture'),
            ),
          ],

          onChanged:
              isSaving
                  ? null
                  : (value) {
                      if (value !=
                          null) {
                        setState(() {
                          selectedCategory =
                              value;
                        });
                      }
                    },
        ),
      ),
    );
  }
}