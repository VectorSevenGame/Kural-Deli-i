import 'dart:io';

import 'package:envanter/app.dart';
import 'package:envanter/data/inventory_store.dart';
import 'package:envanter/data/photo_store_memory.dart';
import 'package:envanter/data/repositories/memory_inventory_repository.dart';
import 'package:envanter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'demo_data.dart';

/// Testlerde gerçek yazı tiplerini yükler.
///
/// Varsayılan test fontu (Ahem) bütün harfleri kutu olarak çizer; ekran
/// görüntüleri okunaksız çıkar. Bu yüzden uygulamanın fontunu ve Material
/// ikon fontunu elle yüklüyoruz.
Future<void> loadAppFonts() async {
  final loader = FontLoader('PlusJakartaSans');
  for (final weight in const [
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
  ]) {
    final file = File('assets/fonts/PlusJakartaSans-$weight.ttf');
    loader.addFont(
      Future.value(ByteData.sublistView(file.readAsBytesSync())),
    );
  }
  await loader.load();

  final iconFont = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? '/home/user/flutter'}'
    '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (iconFont.existsSync()) {
    await (FontLoader('MaterialIcons')
          ..addFont(
            Future.value(ByteData.sublistView(iconFont.readAsBytesSync())),
          ))
        .load();
  }
}

/// Demo veriyle dolu bir store üretir.
Future<InventoryStore> demoStore() async {
  final store = InventoryStore(
    MemoryInventoryRepository(rooms: demoRooms(), items: demoItems()),
    MemoryPhotoStore(),
  );
  await store.load();
  return store;
}

/// Alt menüdeki sekmeye tıklayıp o ekrana geçer.
///
/// Sekme ekranları kendi Scaffold'larını taşımaz; kabuğun içinde yaşarlar.
/// Bu yüzden testte de kabuk üzerinden açılırlar.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Uygulamayı telefon boyutunda, demo veriyle açar.
Future<InventoryStore> pumpApp(
  WidgetTester tester, {
  Widget? home,
  Size size = const Size(390, 844),
}) async {
  await initializeDateFormatting('tr_TR');
  tester.view
    ..devicePixelRatio = 2
    ..physicalSize = size * 2;
  addTearDown(tester.view.reset);

  final store = await demoStore();
  await tester.pumpWidget(
    ChangeNotifierProvider<InventoryStore>.value(
      value: store,
      child: home == null
          ? const EnvanterApp()
          : _wrap(home),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Widget _wrap(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
