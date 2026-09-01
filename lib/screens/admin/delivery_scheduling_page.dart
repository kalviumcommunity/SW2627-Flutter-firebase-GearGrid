import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeliverySchedulingPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const DeliverySchedulingPage({
    super.key,
    required this.booking,
  });

  @override
  State<DeliverySchedulingPage> createState() =>
      _DeliverySchedulingPageState();
}

class _DeliverySchedulingPageState extends State<DeliverySchedulingPage> {
  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);
  static const Color surface = Color(0xFFF8FAFB);
  static const Color blue = Color(0xFF2878E8);

  final TextEditingController driverController = TextEditingController();
  final TextEditingController vehicleController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime? deliveryDate;
  TimeOfDay? deliveryTime;
  DateTime? pickupDate;
  TimeOfDay? pickupTime;

  bool isSaving = false;

  @override
  void dispose() {
    driverController.dispose();
    vehicleController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isDelivery) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: dark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDelivery) {
          deliveryDate = picked;
        } else {
          pickupDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(bool isDelivery) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: dark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDelivery) {
          deliveryTime = picked;
        } else {
          pickupTime = picked;
        }
      });
    }
  }

  void _submit() async {
    if (driverController.text.isEmpty ||
        vehicleController.text.isEmpty ||
        deliveryDate == null ||
        deliveryTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    // Simulate save
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => isSaving = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: green,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delivery Scheduled!',
                style: TextStyle(
                  color: dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Driver ${driverController.text} has been assigned.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule Delivery',
          style: TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking reference
                  _buildBookingRef(booking),
                  const SizedBox(height: 20),

                  // Driver & Vehicle
                  _buildSectionTitle('Assignment'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: driverController,
                    label: 'Driver Name *',
                    icon: Icons.person_outline_rounded,
                    hint: 'e.g., Raju Kumar',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: vehicleController,
                    label: 'Vehicle / Truck ID *',
                    icon: Icons.local_shipping_outlined,
                    hint: 'e.g., MH-04-AB-1234',
                  ),

                  const SizedBox(height: 24),

                  // Delivery schedule
                  _buildSectionTitle('Delivery Schedule'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimePicker(
                          label: 'Delivery Date *',
                          value: deliveryDate != null
                              ? DateFormat('MMM d, yyyy')
                                  .format(deliveryDate!)
                              : null,
                          icon: Icons.calendar_today_rounded,
                          onTap: () => _selectDate(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimePicker(
                          label: 'Time *',
                          value: deliveryTime?.format(context),
                          icon: Icons.access_time_rounded,
                          onTap: () => _selectTime(true),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Pickup schedule
                  _buildSectionTitle('Pickup Schedule (Optional)'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimePicker(
                          label: 'Pickup Date',
                          value: pickupDate != null
                              ? DateFormat('MMM d, yyyy')
                                  .format(pickupDate!)
                              : null,
                          icon: Icons.calendar_today_rounded,
                          onTap: () => _selectDate(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimePicker(
                          label: 'Time',
                          value: pickupTime?.format(context),
                          icon: Icons.access_time_rounded,
                          onTap: () => _selectTime(false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Notes
                  _buildSectionTitle('Notes'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: notesController,
                    label: 'Additional Notes',
                    icon: Icons.notes_rounded,
                    hint: 'Special instructions, venue access details...',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),

          // Submit button
          _buildSubmitBar(),
        ],
      ),
    );
  }

  Widget _buildBookingRef(Map<String, dynamic> booking) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: blue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: blue,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['id'] as String,
                  style: const TextStyle(
                    color: dark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking['event']} • ${booking['items']} items',
                  style: const TextStyle(
                    color: grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: dark,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          color: dark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: grey.withValues(alpha: 0.5),
            fontSize: 12,
          ),
          prefixIcon: Icon(icon, color: green, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: grey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, color: green, size: 17),
                const SizedBox(width: 8),
                Text(
                  value ?? 'Select',
                  style: TextStyle(
                    color: value != null ? dark : grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: isSaving ? null : _submit,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2878E8), Color(0xFF4A93F5)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: blue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Confirm Schedule',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
