import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';
import 'notification_model.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>(
  (ref) => ref.read(notificationsRepositoryProvider).fetchAll(),
);

final unreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.read(notificationsRepositoryProvider).unreadCount(),
);
