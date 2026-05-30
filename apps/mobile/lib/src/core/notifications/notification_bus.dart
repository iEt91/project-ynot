import 'package:flutter/foundation.dart';

import 'notification_event.dart';

abstract class NotificationDispatcher {
  Future<void> dispatch(NotificationEvent event);
}

class InMemoryNotificationBus extends ChangeNotifier implements NotificationDispatcher {
  final List<NotificationEvent> _events = [];

  List<NotificationEvent> get events => List.unmodifiable(_events);

  @override
  Future<void> dispatch(NotificationEvent event) async {
    _events.insert(0, event);
    notifyListeners();
  }
}
