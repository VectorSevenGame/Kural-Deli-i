import 'package:flutter/material.dart';

import '../../data/models/item.dart';
import '../../domain/warranty.dart';
import '../../util/formatters.dart';

/// Esyanin garanti durumunu tek bakista gosteren rozet.
class WarrantyBadge extends StatelessWidget {
  const WarrantyBadge({super.key, required this.item, this.now});

  final Item item;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = item.warrantyStatus(now: now);
    final days = item.warrantyDaysRemaining(now: now);

    final (Color background, Color foreground, IconData icon) = switch (status) {
      WarrantyStatus.active => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          Icons.verified_user_outlined,
        ),
      WarrantyStatus.expiringSoon => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          Icons.schedule,
        ),
      WarrantyStatus.expired => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.gpp_bad_outlined,
        ),
      WarrantyStatus.unknown => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.help_outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            warrantyLabel(status, days),
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
