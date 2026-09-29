import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/item.dart';
import '../domain/reminder.dart';

/// Garanti ve bakım hatırlatıcılarını işletim sistemine kurar.
///
/// Sunucu yok: bütün bildirimler cihazda zamanlanır. Uygulama hiç açılmasa
/// bile işletim sistemi uyarıyı gösterir.
abstract interface class NotificationService {
  /// Kanalları ve saat dilimini hazırlar. Uygulama açılışında bir kez.
  Future<void> init();

  /// Kullanıcıdan bildirim izni ister. İzin verildiyse `true`.
  Future<bool> requestPermission();

  /// İzin şu an verilmiş mi?
  Future<bool> hasPermission();

  /// Mevcut tüm hatırlatıcıları iptal edip [items] için yeniden kurar.
  Future<void> sync(Iterable<Item> items);

  /// Kurulu bildirim sayısı (ayarlar ekranında gösterilir).
  Future<int> scheduledCount();

  Future<void> cancelAll();
}

/// Bildirim göstermeyen uygulama: testler, web önizlemesi ve izin
/// verilmemiş durumlar için.
class NoopNotificationService implements NotificationService {
  int _count = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<void> sync(Iterable<Item> items) async {
    _count = ReminderPlanner.plan(items, now: DateTime.now()).length;
  }

  @override
  Future<int> scheduledCount() async => _count;

  @override
  Future<void> cancelAll() async => _count = 0;
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const String _channelId = 'warranty_reminders';
  static const String _channelName = 'Garanti ve bakım hatırlatıcıları';
  static const String _channelDescription =
      'Garanti bitmeden ve bakım zamanı gelmeden önce uyarır.';

  @override
  Future<void> init() async {
    if (_ready) return;

    tz_data.initializeTimeZones();
    // Cihazın saat dilimi: bildirimler kullanıcının yerel 10:00'unda çıkmalı,
    // UTC 10:00'da değil.
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object catch (error) {
      // Saat dilimi okunamazsa UTC'de kal: bildirim saati kayar ama
      // uygulama çökmez.
      debugPrint('Saat dilimi okunamadı, UTC kullanılıyor: $error');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // İzni açılışta değil, kullanıcı bildirimi açtığında isteyeceğiz.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.defaultImportance,
          ),
        );

    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }

    return false;
  }

  @override
  Future<bool> hasPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    // iOS'ta ayrı bir sorgu yok; izin isteği zaten verilmişse tekrar sormaz.
    return true;
  }

  @override
  Future<void> sync(Iterable<Item> items) async {
    await init();
    if (!await hasPermission()) return;

    await cancelAll();

    final plan = ReminderPlanner.plan(items, now: DateTime.now());
    for (final reminder in plan) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Kasıtlı olarak "inexact": garanti uyarısının dakikası önemli değil.
        // Tam zamanlı alarm, Android'de ayrı bir izin ve Play Store'da
        // gerekçe ister; buna değmez.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.itemId,
      );
    }
  }

  @override
  Future<int> scheduledCount() async {
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  @override
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
