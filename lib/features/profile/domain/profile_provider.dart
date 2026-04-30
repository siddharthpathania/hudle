import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import 'profile_model.dart';

final myProfileProvider = FutureProvider.autoDispose<UserProfile>(
  (ref) => ref.read(profileRepositoryProvider).fetchMe(),
);
