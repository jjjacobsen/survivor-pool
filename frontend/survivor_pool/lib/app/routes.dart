import 'package:flutter/foundation.dart';

import 'package:survivor_pool/core/models/user.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String poolSettings = '/pools/:poolId/settings';
  static const String poolAdvance = '/pools/:poolId/advance';
  static const String poolLeaderboard = '/pools/:poolId/leaderboard';
  static const String manageMembers = '/pools/:poolId/members';
  static const String contestantDetail =
      '/pools/:poolId/contestants/:contestantId';
}

class AppRouteNames {
  static const String login = 'login';
  static const String home = 'home';
  static const String profile = 'profile';
  static const String poolSettings = 'pool-settings';
  static const String poolAdvance = 'pool-advance';
  static const String poolLeaderboard = 'pool-leaderboard';
  static const String manageMembers = 'manage-members';
  static const String contestantDetail = 'contestant-detail';
}

class AppSession {
  AppSession._();
  static final ValueNotifier<AppUser?> currentUser = ValueNotifier<AppUser?>(
    null,
  );
}
