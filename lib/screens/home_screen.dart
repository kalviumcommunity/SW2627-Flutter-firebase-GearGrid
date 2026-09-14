import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/equipment.dart';
import '../services/firestore_repository.dart';
import 'profile_settings_screen.dart';
import 'help_support_screen.dart';

class _C {
  static const ink = Color(0xFF0C1710);
  static const surface = Color(0xFFF6F4EE);
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFF6B35);
  static const muted = Color(0xFF8A9489);
  static const border = Color(0xFFE5E0D5);

  static TextStyle brand({double size = 22, Color color = const Color(0xFF0C1710)}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.8);
  static TextStyle head({double size = 26, Color color = const Color(0xFF0C1710)}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: -1.0, height: 1.1);
  static TextStyle body({double size = 13, Color color = const Color(0xFF8A9489), FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color, height: 1.45);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreRepository _repository = FirestoreRepository();

  late List<Equipment> _inventory;
  late List<Booking> _bookings;
  StreamSubscription<List<Equipment>>? _equipmentSubscription;
  StreamSubscription<List<Booking>>? _bookingSubscription;

  String? _backendError;
  int _selectedTab = 0;

  int _historyLimit = 10;
  final ScrollController _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _inventory = [];
    _bookings = [];
    _startRealtimeData();
    _historyScrollController.addListener(() {
      if (_historyScrollController.position.pixels >=
          _historyScrollController.position.maxScrollExtent - 200) {
        setState(() {
          _historyLimit += 10;
        });
      }
    });
  }

  void _startRealtimeData() {
    _equipmentSubscription = _repository.watchEquipment().listen((inventory) {
      if (!mounted) return;
      setState(() {
        _inventory = inventory;
        _backendError = null;
      });
    }, onError: _recordBackendError);
    _bookingSubscription = _repository.watchBookings(user: widget.user).listen((
      bookings,
    ) {
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _backendError = null;
      });
    }, onError: _recordBackendError);
  }

  void _recordBackendError(Object error) {
    if (!mounted) return;
    setState(() => _backendError = error.toString());
  }

  @override
  void dispose() {
    _historyScrollController.dispose();
    _equipmentSubscription?.cancel();
    _bookingSubscription?.cancel();
    super.dispose();
  }

  void _showAppMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approveBooking(Booking booking) async {
    try {
      await _repository.approveBooking(booking.id);
      _showAppMessage('${booking.eventName} has been approved.');
    } on BookingConflictException catch (error) {
      _showAppMessage(error.message);
    } catch (error) {
      _showAppMessage('Could not approve this booking: $error');
    }
  }

  Future<void> _rejectBooking(Booking booking) async {
    try {
      await _repository.updateBookingStatus(booking.id, BookingStatus.rejected);
      _showAppMessage('${booking.eventName} was declined.');
    } catch (error) {
      _showAppMessage('Could not decline this booking: $error');
    }
  }

  Future<void> _advanceDispatch(Booking booking) async {
    final nextStatus = switch (booking.status) {
      BookingStatus.approved => BookingStatus.dispatched,
      BookingStatus.dispatched => BookingStatus.completed,
      _ => booking.status,
    };

    if (nextStatus == booking.status) return;

    if (nextStatus == BookingStatus.dispatched) {
      final driverCtrl = TextEditingController();
      final vehicleCtrl = TextEditingController();
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _C.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Dispatch Details', style: _C.head(size: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditorField('DRIVER NAME & PHONE', driverCtrl),
              const SizedBox(height: 12),
              _buildEditorField('VEHICLE DETAILS', vehicleCtrl),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: _C.body(color: _C.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.ink, foregroundColor: _C.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Dispatch'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
      
      try {
        final driverName = driverCtrl.text.trim();
        final vehicleDetails = vehicleCtrl.text.trim();
        final deliveryEta = DateTime.now().add(const Duration(hours: 2));

        final updatedBooking = booking.copyWith(
          status: nextStatus,
          driverName: driverName.isNotEmpty ? driverName : null,
          vehicleDetails: vehicleDetails.isNotEmpty ? vehicleDetails : null,
          deliveryEta: deliveryEta,
        );
        await _repository.updateBooking(updatedBooking);
        _showAppMessage('${booking.eventName} moved to dispatched.');
        return;
      } catch (error) {
        _showAppMessage('Could not update dispatch status: $error');
        return;
      }
    }

    try {
      await _repository.updateBookingStatus(booking.id, nextStatus);
      _showAppMessage('${booking.eventName} moved to ${nextStatus.name}.');
    } catch (error) {
      _showAppMessage('Could not update dispatch status: $error');
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
              color: _C.muted,
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber 
              ? TextInputType.numberWithOptions(decimal: isDecimal)
              : TextInputType.text,
          style: _C.body(color: _C.ink),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: _C.surface,
          ),
        ),
      ],
    );
  }

  Future<void> _showEquipmentEditor({Equipment? equipment}) async {
    final nameController = TextEditingController(text: equipment?.name ?? '');
    final categoryController = TextEditingController(text: equipment?.category ?? '');
    final descriptionController = TextEditingController(text: equipment?.description ?? '');
    final profileController = TextEditingController(text: equipment?.powerProfile ?? '');
    final unitsController = TextEditingController(text: '${equipment?.totalUnits ?? 8}');
    final priceController = TextEditingController(text: '${equipment?.pricePerUnit ?? 1500.0}');

    String? currentImageUrl = equipment?.imageUrl;
    bool isUploading = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: _C.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Text(equipment == null ? 'Add Equipment' : 'Edit Equipment', style: _C.head(size: 22)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Image Upload ────────────────────────────────────────────────
                    GestureDetector(
                      onTap: () async {
                        if (isUploading) return;
                        try {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setStateDialog(() => isUploading = true);
                            final bytes = await pickedFile.readAsBytes();
                            final ext = pickedFile.name.split('.').last;
                            final fileName = 'equipment_${DateTime.now().millisecondsSinceEpoch}.$ext';
                            final ref = FirebaseStorage.instance.ref().child('equipment_images').child(fileName);
                            final metadata = SettableMetadata(contentType: 'image/$ext');
                            final uploadTask = ref.putData(bytes, metadata);
                            final snapshot = await uploadTask;
                            final url = await snapshot.ref.getDownloadURL();
                            setStateDialog(() {
                              currentImageUrl = url;
                              isUploading = false;
                            });
                          }
                        } catch (e) {
                          setStateDialog(() => isUploading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                          }
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _C.border),
                          image: currentImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(currentImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: currentImageUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  isUploading 
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: _C.ink))
                                      : const Icon(Icons.add_photo_alternate_outlined, color: _C.muted, size: 32),
                                  const SizedBox(height: 8),
                                  Text(isUploading ? 'Uploading...' : 'Tap to upload image', style: _C.body()),
                                ],
                              )
                            : isUploading
                                ? Container(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    child: const Center(child: CircularProgressIndicator(color: _C.white)),
                                  )
                                : Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircleAvatar(
                                        backgroundColor: _C.ink.withValues(alpha: 0.7),
                                        radius: 14,
                                        child: const Icon(Icons.edit, size: 14, color: _C.white),
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                    _buildEditorField('EQUIPMENT NAME', nameController),
                    const SizedBox(height: 12),
                    _buildEditorField('CATEGORY', categoryController),
                    const SizedBox(height: 12),
                    _buildEditorField('TOTAL UNITS', unitsController, isNumber: true),
                    const SizedBox(height: 12),
                    _buildEditorField('PRICE PER UNIT (₹)', priceController, isNumber: true, isDecimal: true),
                    const SizedBox(height: 12),
                    _buildEditorField('POWER OR RIG PROFILE', profileController),
                    const SizedBox(height: 12),
                    _buildEditorField('DESCRIPTION', descriptionController, maxLines: 3),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: _C.body(color: _C.muted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _C.ink, foregroundColor: _C.white),
                  onPressed: isUploading ? null : () {
                    final name = nameController.text.trim();
                    final category = categoryController.text.trim();
                    final description = descriptionController.text.trim();
                    final profile = profileController.text.trim();
                    final units = int.tryParse(unitsController.text.trim());
                    final price = double.tryParse(priceController.text.trim()) ?? 0.0;

                    if (name.isEmpty || category.isEmpty || description.isEmpty || profile.isEmpty || units == null || units < 1) {
                      _showAppMessage('Enter complete equipment details with a valid unit count.');
                      return;
                    }

                    final savedEquipment = equipment == null
                        ? Equipment(
                            id: '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            category: category,
                            description: description,
                            powerProfile: profile,
                            totalUnits: units,
                            accent: const Color(0xFF52D1FF),
                            pricePerUnit: price,
                            imageUrl: currentImageUrl,
                          )
                        : equipment.copyWith(
                            name: name,
                            category: category,
                            description: description,
                            powerProfile: profile,
                            totalUnits: units,
                            pricePerUnit: price,
                            imageUrl: currentImageUrl,
                          );

                    _repository.saveEquipment(savedEquipment).then((_) {
                      if (context.mounted) Navigator.of(context).pop();
                    }).catchError((error) {
                      _showAppMessage('Could not save equipment: $error');
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _adjustInventory(Equipment equipment, int delta) async {
    final next = equipment.totalUnits + delta;
    if (next < 0) return;
    try {
      await _repository.saveEquipment(equipment.copyWith(totalUnits: next));
    } catch (error) {
      _showAppMessage('Could not update inventory: $error');
    }
  }

  Future<void> _removeEquipment(Equipment equipment) async {
    try {
      await _repository.deleteEquipment(equipment.id);
    } catch (error) {
      _showAppMessage('Could not update inventory: $error');
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '$hour:$min $suffix';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      floatingActionButton: _selectedTab == 2 ? FloatingActionButton(
        backgroundColor: _C.ink,
        foregroundColor: _C.white,
        onPressed: () => _showEquipmentEditor(),
        child: const Icon(Icons.add),
      ) : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _C.white,
          border: Border(
            top: BorderSide(color: _C.border.withValues(alpha: 0.8), width: 1),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          children: [
            _AdminNavItem(
              icon: Icons.assignment_turned_in_rounded,
              label: 'Approvals',
              selected: _selectedTab == 0,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 0);
              },
            ),
            _AdminNavItem(
              icon: Icons.local_shipping_rounded,
              label: 'Dispatch',
              selected: _selectedTab == 1,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 1);
              },
            ),
            _AdminNavItem(
              icon: Icons.inventory_2_rounded,
              label: 'Inventory',
              selected: _selectedTab == 2,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 2);
              },
            ),
            _AdminNavItem(
              icon: Icons.history_rounded,
              label: 'History',
              selected: _selectedTab == 3,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 3);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _selectedTab == 3 ? _historyScrollController : null,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Control', style: _C.head(size: 28)),
                        const SizedBox(height: 4),
                        Text(widget.user.displayName, style: _C.body(size: 15)),
                      ],
                    ),
                    PopupMenuButton<String>(
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: _C.white,
                      elevation: 12,
                      onSelected: (value) {
                        if (value == 'logout') {
                          FirebaseAuth.instance.signOut();
                        } else if (value == 'profile') {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()));
                        } else if (value == 'settings') {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 20, color: _C.ink),
                              const SizedBox(width: 12),
                              Text('Admin Profile', style: _C.body(color: _C.ink)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              const Icon(Icons.help_outline_rounded, size: 20, color: _C.ink),
                              const SizedBox(width: 12),
                              Text('Help & Support', style: _C.body(color: _C.ink)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                              const SizedBox(width: 12),
                              Text('Sign Out', style: _C.body(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: _C.ink,
                            borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text(
                            widget.user.displayName.isNotEmpty
                                ? widget.user.displayName[0].toUpperCase()
                                : 'A',
                            style: GoogleFonts.spaceGrotesk(
                                color: _C.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_backendError != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _backendError!,
                    style: _C.body(color: Colors.red),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            if (_selectedTab == 0) ...[
              _buildSectionHeader('Pending Approvals'),
              _buildPendingApprovals(),
            ] else if (_selectedTab == 1) ...[
              _buildSectionHeader('Active Dispatch'),
              _buildActiveDispatch(),
            ] else if (_selectedTab == 2) ...[
              _buildSectionHeader('Inventory Control'),
              _buildInventoryGrid(),
            ] else if (_selectedTab == 3) ...[
              _buildSectionHeader('Order History'),
              _buildHistory(),
            ],
            
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(title, style: _C.head(size: 22)),
      ),
    );
  }

  Widget _buildPendingApprovals() {
    final pending = _bookings.where((b) => b.status.canBeApproved).toList();
    if (pending.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('No pending approvals.', style: _C.body()),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final booking = pending[index];
          return _buildBookingCard(
            booking: booking,
            actions: [
              TextButton(
                onPressed: () => _rejectBooking(booking),
                child: Text('Decline', style: _C.body(color: _C.muted)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.ink,
                  foregroundColor: _C.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _approveBooking(booking),
                child: Text('Approve', style: _C.body(color: _C.white)),
              ),
            ],
          );
        },
        childCount: pending.length,
      ),
    );
  }

  Widget _buildActiveDispatch() {
    final active = _bookings.where((b) => b.status == BookingStatus.approved || b.status == BookingStatus.dispatched).toList();
    if (active.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('No active dispatch.', style: _C.body()),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final booking = active[index];
          final isApproved = booking.status == BookingStatus.approved;
          return _buildBookingCard(
            booking: booking,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApproved ? _C.accent : _C.ink,
                  foregroundColor: _C.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _advanceDispatch(booking),
                child: Text(
                  isApproved ? 'Mark Dispatched' : 'Mark Completed',
                  style: _C.body(color: _C.white),
                ),
              ),
            ],
          );
        },
        childCount: active.length,
      ),
    );
  }

  Widget _buildBookingCard({required Booking booking, required List<Widget> actions}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(booking.eventName, style: _C.brand(size: 18)),
              Text(_formatDate(booking.start), style: _C.body(color: _C.muted)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${booking.clientName} • ${booking.venue}', style: _C.body()),
          const SizedBox(height: 12),
          const Divider(color: _C.border),
          const SizedBox(height: 12),
          Text('Equipment', style: _C.body(size: 12, color: _C.muted)),
          const SizedBox(height: 8),
          ...booking.requestedUnits.entries.map((e) {
            final eq = _inventory.cast<Equipment?>().firstWhere((i) => i?.id == e.key, orElse: () => null);
            final name = eq?.name ?? e.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: _C.body(color: _C.ink)),
                  Text('x${e.value}', style: _C.body(color: _C.ink)),
                ],
              ),
            );
          }),
          if (booking.driverName != null || booking.vehicleDetails != null || booking.mapsLink != null) ...[
            const SizedBox(height: 16),
            const Divider(color: _C.border),
            const SizedBox(height: 12),
            Text('Dispatch Details', style: _C.body(size: 12, color: _C.muted)),
            const SizedBox(height: 8),
            if (booking.driverName != null) Text('Driver: ${booking.driverName}', style: _C.body(color: _C.ink)),
            if (booking.vehicleDetails != null) Text('Vehicle: ${booking.vehicleDetails}', style: _C.body(color: _C.ink)),
            if (booking.deliveryEta != null) Text('ETA: ${_formatTime(booking.deliveryEta!)}', style: _C.body(color: _C.ink)),
            if (booking.mapsLink != null) ...[
              const SizedBox(height: 4),
              Text('Maps: ${booking.mapsLink}', style: _C.body(color: _C.accent)),
            ]
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid() {
    if (_inventory.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('No inventory items found.', style: _C.body()),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          mainAxisExtent: 180,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _inventory[index];
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: _C.brand(size: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(item.category, style: _C.body(size: 12, color: _C.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: _C.muted),
                            onPressed: () => _adjustInventory(item, -1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Text('${item.totalUnits}', style: _C.head(size: 20)),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: _C.ink),
                            onPressed: () => _adjustInventory(item, 1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _showEquipmentEditor(equipment: item),
                            child: Text('Edit', style: _C.body(color: _C.ink)),
                          ),
                          TextButton(
                            onPressed: () => _removeEquipment(item),
                            child: Text('Remove', style: _C.body(color: Colors.red)),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            );
          },
          childCount: _inventory.length,
        ),
      ),
    );
  }

  Widget _buildHistory() {
    final allHistory = _bookings
        .where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.rejected)
        .toList()
        .reversed
        .toList();

    final displayedHistory = allHistory.take(_historyLimit).toList();

    if (displayedHistory.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('No order history found.', style: _C.body()),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == displayedHistory.length) {
            return _historyLimit < allHistory.length
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: _C.ink)),
                  )
                : const SizedBox.shrink();
          }

          final booking = displayedHistory[index];
          final isCompleted = booking.status == BookingStatus.completed;

          return _buildBookingCard(
            booking: booking,
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFFEAF5CC) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Rejected',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? const Color(0xFF4A7A28) : Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
        childCount: displayedHistory.length + (_historyLimit < allHistory.length ? 1 : 0),
      ),
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: selected ? _C.ink : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: selected ? _C.ink : _C.muted),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  color: selected ? _C.ink : _C.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── History ──────────────────────────────────────────────────────────────────

