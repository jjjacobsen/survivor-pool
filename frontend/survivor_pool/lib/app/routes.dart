import 'package:flutter/foundation.dart';

import 'package:survivor_pool/core/models/user.dart';
import 'package:survivor_pool/core/session/auth_storage.dart';

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
  static String? _token;

  static String? get token => _token;

  static Future<void> restore() async {
    final stored = await AuthStorage.loadSession();
    if (stored == null) {
      return;
    }
    _token = stored.token;
    currentUser.value = stored.user;
  }

  static Future<void> setSession(AppUser user, String token) async {
    _token = token;
    currentUser.value = user;
    await AuthStorage.saveSession(token, user);
  }

  static Future<void> updateToken(String token) async {
    if (token.isEmpty || token == _token) {
      return;
    }
    _token = token;
    final user = currentUser.value;
    if (user != null) {
      await AuthStorage.saveSession(token, user);
      return;
    }
    await AuthStorage.saveToken(token);
  }

  static Future<void> clear() async {
    _token = null;
    currentUser.value = null;
    await AuthStorage.clearSession();
  }

  static Future<void> updateUser(AppUser user) async {
    currentUser.value = user;
    final token = _token;
    if (token != null && token.isNotEmpty) {
      await AuthStorage.saveSession(token, user);
    }
  }
}
