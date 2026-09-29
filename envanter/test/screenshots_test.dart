import 'package:envanter/data/inventory_store.dart';
import 'package:envanter/ui/item/item_detail_screen.dart';
import 'package:envanter/ui/item/item_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/harness.dart';

/// Her ekranı demo veriyle çizip PNG'ye basar.
///
/// `flutter test --update-goldens test/screenshots_test.dart` çalıştırıldığında
/// `test/goldens/` altına gerçek ekran görüntüleri düşer. Tasarımı Unity/cihaz
/// olmadan gözle kontrol etmenin yolu budur.
void main() {
  setUpAll(loadAppFonts);

  Future<void> shoot(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('01 ana ekran', (tester) async {
    await pumpApp(tester);
    await shoot(tester, '01_ana_ekran');
  });

  testWidgets('02 garanti takvimi', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Garanti');
    await shoot(tester, '02_garanti');
  });

  testWidgets('03 esya detayi', (tester) async {
    await pumpApp(tester, home: const ItemDetailScreen(itemId: 'i1'));
    await shoot(tester, '03_esya_detayi');
  });

  testWidgets('04 esya ekleme', (tester) async {
    await pumpApp(tester, home: const ItemEditScreen());
    await shoot(tester, '04_esya_ekleme');
  });

  testWidgets('05 arama', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Arama');
    await tester.enterText(find.byType(TextField), 'si');
    await tester.pumpAndSettle();
    await shoot(tester, '05_arama');
  });

  testWidgets('06 ayarlar', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Ayarlar');
    await shoot(tester, '06_ayarlar');
  });

  testWidgets('07 bos durum', (tester) async {
    await pumpApp(tester);
    final store = Provider.of<InventoryStore>(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );
    for (final item in [...store.items]) {
      await store.deleteItem(item.id);
    }
    await tester.pumpAndSettle();
    await shoot(tester, '07_bos_durum');
  });
}
