import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/inventory_store.dart';
import '../../data/models/room.dart';
import '../widgets/app_header.dart';
import '../widgets/warranty_pill.dart';

/// Ayarlar: oda yönetimi ve uygulama bilgisi.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = context.watch<InventoryStore>();

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            const AppHeader(subtitle: 'Ayarlar'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Ayarlar',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 28),
                  ),
                  SectionHeader(
                    'Odalar',
                    trailing: TextButton.icon(
                      onPressed: () => _addRoom(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ekle'),
                    ),
                  ),
                  Card(
                    child: Column(
                      children: [
                        for (final Room room in store.rooms)
                          ListTile(
                            leading: Icon(
                              Icons.meeting_room_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                            title: Text(room.name),
                            subtitle: Text(
                              '${store.itemsInRoom(room.id).length} eşya',
                            ),
                            trailing: PopupMenuButton<String>(
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'rename',
                                  child: Text('Yeniden adlandır'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Sil'),
                                ),
                              ],
                              onSelected: (value) => value == 'rename'
                                  ? _renameRoom(context, room)
                                  : _deleteRoom(context, room),
                            ),
                          ),
                        if (store.rooms.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Henüz oda yok.'),
                          ),
                      ],
                    ),
                  ),
                  const SectionHeader('Veri'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, color: scheme.secondary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Verilerin telefonunda',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hesap yok, sunucu yok. Eşyaların, '
                                  'faturaların ve fotoğrafların yalnızca bu '
                                  'cihazda duruyor.',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.45,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SectionHeader('Hakkında'),
                  Card(
                    child: Column(
                      children: [
                        const ListTile(
                          title: Text('Sürüm'),
                          trailing: Text('0.2.0 · geliştirme'),
                        ),
                        ListTile(
                          title: const Text('Toplam eşya'),
                          trailing: Text('${store.items.length}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addRoom(BuildContext context) async {
    final store = context.read<InventoryStore>();
    final name = await _promptName(context, title: 'Oda ekle');
    if (name != null && name.isNotEmpty) await store.addRoom(name);
  }

  Future<void> _renameRoom(BuildContext context, Room room) async {
    final store = context.read<InventoryStore>();
    final name = await _promptName(
      context,
      title: 'Odayı yeniden adlandır',
      initial: room.name,
    );
    if (name != null && name.isNotEmpty) await store.renameRoom(room, name);
  }

  Future<void> _deleteRoom(BuildContext context, Room room) async {
    final store = context.read<InventoryStore>();
    final count = store.itemsInRoom(room.id).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('"${room.name}" silinsin mi?'),
        content: Text(
          count == 0
              ? 'Bu oda boş, güvenle silinebilir.'
              : 'Odadaki $count eşya silinmez, "Odasız" olarak kalır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await store.deleteRoom(room.id);
  }

  Future<String?> _promptName(
    BuildContext context, {
    required String title,
    String? initial,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Örn. Çocuk Odası'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result?.trim();
  }
}
