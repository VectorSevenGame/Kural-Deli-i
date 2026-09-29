import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database.dart';
import 'data/inventory_store.dart';
import 'data/photo_store.dart';
import 'data/repositories/inventory_repository.dart';
import 'services/notification_service.dart';
import 'services/reminder_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  final database = await AppDatabase.open();
  final photos = await PhotoStore.create();
  final preferences = await SharedPreferences.getInstance();

  final store = InventoryStore(InventoryRepository(database), photos);
  await store.load();

  final notifications = LocalNotificationService();
  await notifications.init();

  final reminders = ReminderController(
    notifications: notifications,
    inventory: store,
    preferences: preferences,
  );
  // Açılışta bekletmiyoruz: ilk kare bildirim planını beklemesin.
  unawaited(reminders.start());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<InventoryStore>.value(value: store),
        ChangeNotifierProvider<ReminderController>.value(value: reminders),
      ],
      child: const EnvanterApp(),
    ),
  );
}
