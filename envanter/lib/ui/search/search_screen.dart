import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/inventory_store.dart';
import '../../data/models/item.dart';
import '../item/item_detail_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/item_card.dart';

/// Eşya arama: ad, marka, model, seri no, satıcı ve not içinde.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Item> _results = const [];
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(String query) async {
    final store = context.read<InventoryStore>();
    final results = await store.search(query);
    if (mounted) {
      setState(() {
        _query = query;
        _results = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = context.watch<InventoryStore>();

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(subtitle: 'Eşya ara'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _controller,
                autocorrect: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Marka, model, seri no, mağaza…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _run('');
                          },
                        ),
                ),
                onChanged: _run,
              ),
            ),
            Expanded(
              child: _query.trim().isEmpty
                  ? _Hint(total: store.items.length)
                  : _results.isEmpty
                      ? _Hint.noResult(query: _query)
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 110),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            return ItemCard(
                              item: item,
                              roomName: store.rooms
                                  .where((r) => r.id == item.roomId)
                                  .map((r) => r.name)
                                  .firstOrNull,
                              onTap: () => Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ItemDetailScreen(itemId: item.id),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.total}) : query = null;

  const _Hint.noResult({required this.query}) : total = null;

  final int? total;
  final String? query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final noResult = query != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noResult ? Icons.search_off : Icons.manage_search,
              size: 52,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              noResult
                  ? '"$query" için sonuç yok'
                  : 'Aradığın eşyayı yaz',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              noResult
                  ? 'Farklı bir kelime dene: marka, model ya da mağaza adı.'
                  : '$total eşya arasında ad, marka, model, seri numarası, '
                      'mağaza ve notlarda arar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
