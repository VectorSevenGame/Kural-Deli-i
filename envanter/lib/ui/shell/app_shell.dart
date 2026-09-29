import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../item/item_edit_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../warranty/warranty_screen.dart';

/// Alt menülü ana kabuk: Odalar · Arama · Ekle · Garanti · Ayarlar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const List<Widget> _tabs = [
    HomeScreen(),
    SearchScreen(),
    WarrantyScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: Padding(
        // Alt menünün "Ekle" yazısına yer bırakacak kadar yukarı al.
        padding: const EdgeInsets.only(bottom: 18),
        child: SizedBox(
          width: 62,
          height: 62,
          child: FloatingActionButton(
            onPressed: _openEditor,
            tooltip: 'Eşya ekle',
            child: const Icon(Icons.photo_camera_outlined, size: 26),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        index: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
    );
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ItemEditScreen()),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const List<({IconData icon, IconData active, String label})> _items = [
    (icon: Icons.home_outlined, active: Icons.home, label: 'Odalar'),
    (icon: Icons.search, active: Icons.search, label: 'Arama'),
    (
      icon: Icons.shield_outlined,
      active: Icons.shield,
      label: 'Garanti',
    ),
    (
      icon: Icons.settings_outlined,
      active: Icons.settings,
      label: 'Ayarlar',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BottomAppBar(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          _tab(context, 0, scheme),
          _tab(context, 1, scheme),
          // Ortadaki FAB'in yeri; altında etiketi duruyor.
          SizedBox(
            width: 76,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Ekle',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ),
          _tab(context, 2, scheme),
          _tab(context, 3, scheme),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, int slot, ColorScheme scheme) {
    final item = _items[slot];
    final selected = index == slot;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Expanded(
      child: InkResponse(
        onTap: () => onChanged(slot),
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? item.active : item.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
