import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../theme/admin_theme.dart';

class InventoryItemCard extends StatelessWidget {
  const InventoryItemCard({
    required this.item,
    required this.onAdjustInventory,
    required this.onEdit,
    required this.onRemove,
    super.key,
  });

  final Equipment item;
  final void Function(Equipment, int) onAdjustInventory;
  final void Function(Equipment) onEdit;
  final void Function(Equipment) onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.white,
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
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AdminTheme.brand(size: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(item.category, style: AdminTheme.body(size: 12, color: AdminTheme.muted)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AdminTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18, color: AdminTheme.muted),
                      onPressed: () => onAdjustInventory(item, -1),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('${item.totalUnits}', style: AdminTheme.head(size: 16)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18, color: AdminTheme.ink),
                      onPressed: () => onAdjustInventory(item, 1),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: AdminTheme.white,
                icon: const Icon(Icons.more_vert, color: AdminTheme.muted),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit(item);
                  } else if (value == 'remove') {
                    onRemove(item);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18, color: AdminTheme.ink),
                        const SizedBox(width: 12),
                        Text('Edit', style: AdminTheme.body(color: AdminTheme.ink)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        const SizedBox(width: 12),
                        Text('Remove', style: AdminTheme.body(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
