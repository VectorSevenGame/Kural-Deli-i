import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/inventory_store.dart';
import '../../data/models/item.dart';
import '../../util/formatters.dart';
import '../widgets/item_photo.dart';

/// Eşya ekleme / düzenleme formu.
///
/// Şimdilik alanlar elle dolduruluyor; sonraki adımda fatura fotoğrafından
/// yapay zekâ ile doldurulup kullanıcıya onaylatılacak.
class ItemEditScreen extends StatefulWidget {
  const ItemEditScreen({super.key, this.item, this.initialRoomId});

  final Item? item;

  /// Yeni eşya hangi odaya eklenecek (ana ekrandaki seçili oda).
  final String? initialRoomId;

  @override
  State<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends State<ItemEditScreen> {
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _serial;
  late final TextEditingController _price;
  late final TextEditingController _seller;
  late final TextEditingController _note;

  late ItemCategory _category;
  String? _roomId;
  DateTime? _purchaseDate;
  int? _warrantyMonths;
  String? _photoPath;
  bool _saving = false;

  bool get _isNew => widget.item == null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _brand = TextEditingController(text: item?.brand ?? '');
    _model = TextEditingController(text: item?.model ?? '');
    _serial = TextEditingController(text: item?.serialNumber ?? '');
    _price = TextEditingController(
      text: item?.priceKurus == null
          ? ''
          : (item!.priceKurus! / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    _seller = TextEditingController(text: item?.seller ?? '');
    _note = TextEditingController(text: item?.note ?? '');
    _category = item?.category ?? ItemCategory.other;
    _roomId = item?.roomId ?? widget.initialRoomId;
    _purchaseDate = item?.purchaseDate;
    _warrantyMonths = item?.warrantyMonths ?? _category.defaultWarrantyMonths;
    _photoPath = item?.photoPath;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _brand,
      _model,
      _serial,
      _price,
      _seller,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InventoryStore>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Eşya ekle' : 'Düzenle'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(child: _PhotoPicker(path: _photoPath, onPick: _pickPhoto)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Eşya adı *'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Eşyaya bir ad ver'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ItemCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final category in ItemCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _category = value;
                  _warrantyMonths ??= value.defaultWarrantyMonths;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _roomId,
              decoration: const InputDecoration(labelText: 'Oda'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Odasız')),
                for (final room in store.rooms)
                  DropdownMenuItem(value: room.id, child: Text(room.name)),
              ],
              onChanged: (value) => setState(() => _roomId = value),
            ),
            const _SectionTitle('Künye'),
            TextFormField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Marka'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _serial,
              decoration: const InputDecoration(labelText: 'Seri numarası'),
            ),
            const _SectionTitle('Satın alma'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Alım tarihi'),
              subtitle: Text(formatDate(_purchaseDate)),
              trailing: _purchaseDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _purchaseDate = null),
                    ),
              onTap: _pickDate,
            ),
            TextFormField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Fiyat',
                suffixText: '₺',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return parsePrice(value) == null ? 'Geçerli bir tutar gir' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _seller,
              decoration: const InputDecoration(
                labelText: 'Nereden aldın?',
                hintText: 'Örn. Trendyol, MediaMarkt',
              ),
            ),
            const _SectionTitle('Garanti'),
            _WarrantyPicker(
              months: _warrantyMonths,
              onChanged: (value) => setState(() => _warrantyMonths = value),
            ),
            const _SectionTitle('Not'),
            TextFormField(
              controller: _note,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Servis telefonu, filtre ölçüsü, boya kodu…',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Fotoğraf çek'),
              onTap: () async {
                final file =
                    await picker.pickImage(source: ImageSource.camera);
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop(file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () async {
                final file =
                    await picker.pickImage(source: ImageSource.gallery);
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop(file);
                }
              },
            ),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;
    final saved = await context.read<InventoryStore>().savePhoto(picked);
    if (mounted) setState(() => _photoPath = saved);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final existing = widget.item;
    final item = Item(
      id: existing?.id ?? _uuid.v4(),
      name: _name.text.trim(),
      category: _category,
      roomId: _roomId,
      brand: _nullIfBlank(_brand.text),
      model: _nullIfBlank(_model.text),
      serialNumber: _nullIfBlank(_serial.text),
      purchaseDate: _purchaseDate,
      priceKurus: parsePrice(_price.text),
      seller: _nullIfBlank(_seller.text),
      warrantyMonths: _warrantyMonths,
      photoPath: _photoPath,
      note: _nullIfBlank(_note.text),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await context.read<InventoryStore>().saveItem(item);
    if (mounted) Navigator.of(context).pop();
  }

  static String? _nullIfBlank(String value) =>
      value.trim().isEmpty ? null : value.trim();
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.path, required this.onPick});

  final String? path;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Column(
        children: [
          ItemPhoto(
            path: path,
            size: 140,
            radius: 20,
            fallbackIcon: Icons.add_a_photo_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            path == null ? 'Fotoğraf ekle' : 'Fotoğrafı değiştir',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _WarrantyPicker extends StatelessWidget {
  const _WarrantyPicker({required this.months, required this.onChanged});

  final int? months;
  final ValueChanged<int?> onChanged;

  static const List<(String, int?)> _options = [
    ('Yok', null),
    ('1 yıl', 12),
    ('2 yıl', 24),
    ('3 yıl', 36),
    ('5 yıl', 60),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final (label, value) in _options)
          ChoiceChip(
            label: Text(label),
            selected: months == value,
            onSelected: (_) => onChanged(value),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
      child: Text(
        turkishUpper(text),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
