import 'package:flutter/foundation.dart';

import 'package:survivor_pool/core/models/user.dart';
import 'package:survivor_pool/core/session/auth_storage.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String resetPassword = '/reset-password';
  static const String forgotPassword = '/forgot-password';
  static const String poolSettings = '/settings';
  static const String poolAdvance = '/advance';
  static const String poolLeaderboard = '/leaderboard';
  static const String manageMembers = '/members';
  static const String contestantDetail = '/contestants/:contestantId';
}

class AppRouteNames {
  static const String login = 'login';
  static const String home = 'home';
  static const String profile = 'profile';
  static const String resetPassword = 'reset-password';
  static const String forgotPassword = 'forgot-password';
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
  static final Map<String, Object?> _cachedExtras = <String, Object?>{};
  static Future<void> Function()? _onUnauthorized;
  static bool _isForceLogoutInFlight = false;

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
    _cachedExtras.clear();
    await AuthStorage.clearSession();
  }

  static void registerUnauthorizedHandler(Future<void> Function() handler) {
    _onUnauthorized = handler;
  }

  static Future<void> forceLogout() async {
    if (_isForceLogoutInFlight) {
      return;
    }
    _isForceLogoutInFlight = true;
    try {
      await clear();
      final handler = _onUnauthorized;
      if (handler != null) {
        await handler();
      }
    } finally {
      _isForceLogoutInFlight = false;
    }
  }

  static Future<void> updateUser(AppUser user) async {
    currentUser.value = user;
    final token = _token;
    if (token != null && token.isNotEmpty) {
      await AuthStorage.saveSession(token, user);
    }
  }

  static void cacheRouteExtra(String routeName, Object extra) {
    _cachedExtras[routeName] = extra;
  }

  static Object? getRouteExtra(String routeName) => _cachedExtras[routeName];
}
