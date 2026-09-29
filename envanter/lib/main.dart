import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/database.dart';
import 'data/inventory_store.dart';
import 'data/photo_store.dart';
import 'data/repositories/inventory_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  final database = await AppDatabase.open();
  final photos = await PhotoStore.create();
  final store = InventoryStore(InventoryRepository(database), photos);
  await store.load();

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const EnvanterApp(),
    ),
  );
}
