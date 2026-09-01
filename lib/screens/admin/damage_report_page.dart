import 'package:flutter/material.dart';

class DamageReportPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  final List<Map<String, dynamic>> equipmentItems;

  const DamageReportPage({
    super.key,
    required this.booking,
    required this.equipmentItems,
  });

  @override
  State<DamageReportPage> createState() => _DamageReportPageState();
}

class _DamageReportPageState extends State<DamageReportPage> {
  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);
  static const Color surface = Color(0xFFF8FAFB);
  static const Color red = Color(0xFFE53935);
  static const Color orange = Color(0xFFF47A24);

  late List<Map<String, dynamic>> returnItems;
  final TextEditingController globalNotesController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    returnItems = widget.equipmentItems.map((item) {
      return {
        ...item,
        'returned': item['quantity'] as int,
        'damaged': 0,
        'notes': '',
      };
    }).toList();
  }

  @override
  void dispose() {
    globalNotesController.dispose();
    super.dispose();
  }

  int get totalItems =>
      returnItems.fold(0, (sum, item) => sum + (item['quantity'] as int));

  int get totalReturned =>
      returnItems.fold(0, (sum, item) => sum + (item['returned'] as int));

  int get totalDamaged =>
      returnItems.fold(0, (sum, item) => sum + (item['damaged'] as int));

  bool get hasDamage => totalDamaged > 0;

  void _submit() async {
    setState(() => isSaving = true);
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
                  color: hasDamage
                      ? const Color(0xFFFFF0E6)
                      : const Color(0xFFEAF7F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  hasDamage
                      ? Icons.report_problem_rounded
                      : Icons.check_circle_rounded,
                  color: hasDamage ? orange : green,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasDamage
                    ? 'Return Processed with Damage'
                    : 'Return Processed Successfully',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: dark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasDamage
                    ? '$totalDamaged item(s) reported damaged.\nDamage report has been logged.'
                    : 'All $totalReturned items returned in good condition.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: grey,
                  fontSize: 13,
                  height: 1.4,
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
          'Process Return',
          style: TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.booking['id'] as String,
              style: const TextStyle(
                color: Color(0xFF2878E8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
                  _buildSummaryStrip(),
                  const SizedBox(height: 20),
                  const Text(
                    'Equipment Return Check',
                    style: TextStyle(
                      color: dark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Adjust quantities for items returned and log any damage.',
                    style: TextStyle(
                      color: grey,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    returnItems.length,
                    (index) => _buildItemCard(index),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'General Notes',
                    style: TextStyle(
                      color: dark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: TextField(
                      controller: globalNotesController,
                      maxLines: 3,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Any overall observations about the return...',
                        hintStyle: TextStyle(
                          color: grey.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildSubmitBar(),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY STRIP
  // ============================================================

  Widget _buildSummaryStrip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSummaryItem('Total Sent', '$totalItems', green),
          _buildSummaryDivider(),
          _buildSummaryItem('Returned', '$totalReturned', Color(0xFF2878E8)),
          _buildSummaryDivider(),
          _buildSummaryItem(
            'Damaged',
            '$totalDamaged',
            totalDamaged > 0 ? red : green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return Container(
      width: 1,
      height: 36,
      color: border,
    );
  }

  // ============================================================
  // ITEM CARD
  // ============================================================

  Widget _buildItemCard(int index) {
    final item = returnItems[index];
    final int sent = item['quantity'] as int;
    final int returned = item['returned'] as int;
    final int damaged = item['damaged'] as int;
    final bool itemHasDamage = damaged > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: itemHasDamage
              ? red.withValues(alpha: 0.3)
              : border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: itemHasDamage
                      ? const Color(0xFFFFE9E9)
                      : const Color(0xFFEAF7F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['category'] == 'Sound'
                      ? Icons.speaker_rounded
                      : item['category'] == 'Lighting'
                          ? Icons.lightbulb_outline_rounded
                          : Icons.chair_rounded,
                  color: itemHasDamage ? red : green,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['category']} • Sent: $sent',
                      style: const TextStyle(
                        color: grey,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Container(height: 1, color: border),
          const SizedBox(height: 14),

          // Returned stepper
          Row(
            children: [
              const SizedBox(
                width: 80,
                child: Text(
                  'Returned',
                  style: TextStyle(
                    color: grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildStepper(
                value: returned,
                max: sent,
                color: green,
                onChanged: (val) {
                  setState(() {
                    returnItems[index]['returned'] = val;
                    // Cap damage at returned count
                    if (returnItems[index]['damaged'] > val) {
                      returnItems[index]['damaged'] = val;
                    }
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Damaged stepper
          Row(
            children: [
              const SizedBox(
                width: 80,
                child: Text(
                  'Damaged',
                  style: TextStyle(
                    color: grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildStepper(
                value: damaged,
                max: returned,
                color: red,
                onChanged: (val) {
                  setState(() {
                    returnItems[index]['damaged'] = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepper({
    required int value,
    required int max,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: value > 0 ? () => onChanged(value - 1) : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value > 0
                  ? color.withValues(alpha: 0.12)
                  : const Color(0xFFF5F7F8),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.remove_rounded,
              size: 16,
              color: value > 0 ? color : grey,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: value > 0 ? color : dark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: value < max ? () => onChanged(value + 1) : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: value < max
                  ? color.withValues(alpha: 0.12)
                  : const Color(0xFFF5F7F8),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 16,
              color: value < max ? color : grey,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUBMIT BAR
  // ============================================================

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
              gradient: LinearGradient(
                colors: hasDamage
                    ? [const Color(0xFFF47A24), const Color(0xFFFF9A4D)]
                    : [const Color(0xFF16845F), const Color(0xFF1DA875)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (hasDamage ? orange : green)
                      .withValues(alpha: 0.3),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasDamage
                              ? Icons.report_problem_rounded
                              : Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasDamage
                              ? 'Submit with Damage Report'
                              : 'Mark as Returned',
                          style: const TextStyle(
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
