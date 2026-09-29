import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/inventory_store.dart';
import 'notification_service.dart';

/// Hatırlatıcıların açık/kapalı durumunu tutar ve envanter değiştikçe
/// bildirimleri yeniden kurar.
///
/// Envanter katmanı bildirimlerden habersizdir; bağlantıyı burası kurar.
class ReminderController extends ChangeNotifier {
  ReminderController({
    required NotificationService notifications,
    required InventoryStore inventory,
    required SharedPreferences preferences,
  })  : _notifications = notifications,
        _inventory = inventory,
        _preferences = preferences {
    _enabled = _preferences.getBool(_enabledKey) ?? false;
    _inventory.addListener(_onInventoryChanged);
  }

  static const String _enabledKey = 'reminders.enabled';

  /// Envanterde art arda değişiklik olduğunda (toplu silme gibi) bildirimleri
  /// her seferinde yeniden kurmamak için kısa bir bekleme.
  static const Duration _debounce = Duration(milliseconds: 400);

  final NotificationService _notifications;
  final InventoryStore _inventory;
  final SharedPreferences _preferences;

  bool _enabled = false;
  int _scheduled = 0;
  Timer? _pending;

  bool get enabled => _enabled;

  /// İşletim sisteminde kurulu bildirim sayısı.
  int get scheduledCount => _scheduled;

  /// Uygulama açılışında çağrılır: izin hâlâ duruyorsa planı tazeler.
  Future<void> start() async {
    if (!_enabled) return;
    if (!await _notifications.hasPermission()) {
      // Kullanıcı izni sistem ayarlarından kapatmış olabilir.
      await _setEnabled(false);
      return;
    }
    await _sync();
  }

  /// Ayarlardaki anahtar. Açarken izin ister; izin verilmezse kapalı kalır.
  ///
  /// İzin reddedilirse `false` döner, arayüz kullanıcıyı bilgilendirir.
  Future<bool> setEnabled(bool value) async {
    if (!value) {
      await _notifications.cancelAll();
      await _setEnabled(false);
      _scheduled = 0;
      notifyListeners();
      return true;
    }

    final granted = await _notifications.requestPermission();
    if (!granted) {
      await _setEnabled(false);
      notifyListeners();
      return false;
    }

    await _setEnabled(true);
    await _sync();
    return true;
  }

  Future<void> _setEnabled(bool value) async {
    _enabled = value;
    await _preferences.setBool(_enabledKey, value);
  }

  void _onInventoryChanged() {
    if (!_enabled) return;
    _pending?.cancel();
    _pending = Timer(_debounce, () => unawaited(_sync()));
  }

  Future<void> _sync() async {
    await _notifications.sync(_inventory.items);
    _scheduled = await _notifications.scheduledCount();
    notifyListeners();
  }

  @override
  void dispose() {
    _pending?.cancel();
    _inventory.removeListener(_onInventoryChanged);
    super.dispose();
  }
}
