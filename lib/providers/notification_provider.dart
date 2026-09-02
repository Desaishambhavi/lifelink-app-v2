import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/service_locator.dart';

/// Backs the notification centre and the unread badge.
class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _items = [];
  bool _loading = true;

  List<AppNotification> get items => _items;
  bool get loading => _loading;
  int get unreadCount => _items.where((n) => !n.read).length;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await Services.notifications.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> push(AppNotification notification) async {
    await Services.notifications.add(notification);
    await load();
  }

  Future<void> markAllRead() async {
    await Services.notifications.markAllRead();
    await load();
  }

  Future<void> clear() async {
    await Services.notifications.clear();
    await load();
  }
}
