import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/announcements_repository.dart';
import 'announcement_model.dart';

final groupAnnouncementsProvider = FutureProvider.family
    .autoDispose<List<Announcement>, String>(
  (ref, groupId) =>
      ref.read(announcementsRepositoryProvider).fetchGroupFeed(groupId),
);

final pendingAnnouncementsProvider = FutureProvider.family
    .autoDispose<List<Announcement>, String>(
  (ref, groupId) =>
      ref.read(announcementsRepositoryProvider).fetchPendingForGroup(groupId),
);

final announcementDetailProvider =
    FutureProvider.autoDispose.family<Announcement, String>(
  (ref, id) => ref.read(announcementsRepositoryProvider).fetchOne(id),
);
