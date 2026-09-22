import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/equipment.dart';
import '../services/firestore_repository.dart';
import '../theme/admin_theme.dart';
import '../widgets/booking_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/equipment_editor_dialog.dart';
import '../widgets/inventory_item_card.dart';
import 'profile_settings_screen.dart';
import 'help_support_screen.dart';

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
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: AdminTheme.ink, behavior: SnackBarBehavior.floating));
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
          backgroundColor: AdminTheme.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Dispatch Details', style: AdminTheme.head(size: 20)),
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
              child: Text('Cancel', style: AdminTheme.body(color: AdminTheme.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.ink, foregroundColor: AdminTheme.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  Future<void> _showEquipmentEditor({Equipment? equipment}) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return EquipmentEditorDialog(
          equipment: equipment,
          onSave: (savedEquipment) async {
            await _repository.saveEquipment(savedEquipment);
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
      _showAppMessage('Could not delete equipment: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.surface,
      floatingActionButton: _selectedTab == 2 ? FloatingActionButton(
        backgroundColor: AdminTheme.ink,
        foregroundColor: AdminTheme.white,
        elevation: 4,
        onPressed: () => _showEquipmentEditor(),
        child: const Icon(Icons.add),
      ) : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AdminTheme.white,
          border: Border(
            top: BorderSide(color: AdminTheme.border.withValues(alpha: 0.8), width: 1),
          ),
          boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, -4))],
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
                        Text('Admin Control', style: AdminTheme.head(size: 28)),
                        const SizedBox(height: 4),
                        Text(widget.user.displayName, style: AdminTheme.body(size: 15)),
                      ],
                    ),
                    PopupMenuButton<String>(
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: AdminTheme.white,
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
                              const Icon(Icons.person_rounded, size: 20, color: AdminTheme.ink),
                              const SizedBox(width: 12),
                              Text('Admin Profile', style: AdminTheme.body(color: AdminTheme.ink)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              const Icon(Icons.help_outline_rounded, size: 20, color: AdminTheme.ink),
                              const SizedBox(width: 12),
                              Text('Help & Support', style: AdminTheme.body(color: AdminTheme.ink)),
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
                              Text('Sign Out', style: AdminTheme.body(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: AdminTheme.ink,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4))],
                        ),
                        child: Center(
                          child: Text(
                            widget.user.displayName.isNotEmpty
                                ? widget.user.displayName[0].toUpperCase()
                                : 'A',
                            style: GoogleFonts.spaceGrotesk(
                                color: AdminTheme.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18),
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
                    style: AdminTheme.body(color: Colors.red),
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
        child: Text(title, style: AdminTheme.head(size: 22)),
      ),
    );
  }

  Widget _buildPendingApprovals() {
    final pending = _bookings.where((b) => b.status.canBeApproved).toList();
    if (pending.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyStateWidget(
          icon: Icons.check_circle_outline,
          message: 'You are all caught up!\nNo pending approvals.',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final booking = pending[index];
          return BookingCard(
            booking: booking,
            inventory: _inventory,
            actions: [
              TextButton(
                onPressed: () => _rejectBooking(booking),
                child: Text('Decline', style: AdminTheme.body(color: AdminTheme.muted)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.ink,
                  foregroundColor: AdminTheme.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _approveBooking(booking),
                child: Text('Approve', style: AdminTheme.body(color: AdminTheme.white)),
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
      return const SliverToBoxAdapter(
        child: EmptyStateWidget(
          icon: Icons.local_shipping_outlined,
          message: 'No active dispatches right now.',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final booking = active[index];
          final isApproved = booking.status == BookingStatus.approved;
          return BookingCard(
            booking: booking,
            inventory: _inventory,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApproved ? AdminTheme.accent : AdminTheme.ink,
                  foregroundColor: AdminTheme.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _advanceDispatch(booking),
                child: Text(
                  isApproved ? 'Mark Dispatched' : 'Mark Completed',
                  style: AdminTheme.body(color: AdminTheme.white),
                ),
              ),
            ],
          );
        },
        childCount: active.length,
      ),
    );
  }

  Widget _buildInventoryGrid() {
    if (_inventory.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyStateWidget(
          icon: Icons.inventory_2_outlined,
          message: 'Inventory is empty.\nAdd some equipment to get started.',
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
            return InventoryItemCard(
              item: item,
              onAdjustInventory: _adjustInventory,
              onEdit: (eq) => _showEquipmentEditor(equipment: eq),
              onRemove: _removeEquipment,
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
      return const SliverToBoxAdapter(
        child: EmptyStateWidget(
          icon: Icons.history_outlined,
          message: 'No completed or rejected orders yet.',
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
                    child: Center(child: CircularProgressIndicator(color: AdminTheme.ink)),
                  )
                : const SizedBox.shrink();
          }

          final booking = displayedHistory[index];
          final isCompleted = booking.status == BookingStatus.completed;

          return BookingCard(
            booking: booking,
            inventory: _inventory,
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted ? AdminTheme.success : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Rejected',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? AdminTheme.successText : Colors.red,
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
        splashColor: AdminTheme.ink.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: selected ? AdminTheme.ink : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: selected ? AdminTheme.ink : AdminTheme.muted),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  color: selected ? AdminTheme.ink : AdminTheme.muted,
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
