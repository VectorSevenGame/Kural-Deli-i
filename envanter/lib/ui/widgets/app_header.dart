import 'package:flutter/material.dart';

/// Tasarımdaki üst şerit: logo + "Yuvam" + alt başlık, sağda aksiyonlar.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.subtitle, this.actions});

  final String subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.home_rounded, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Yuvam',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                  height: 1.1,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          ...?actions,
        ],
      ),
    );
  }
}
