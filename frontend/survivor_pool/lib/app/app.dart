import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:survivor_pool/app/routes.dart';
import 'package:survivor_pool/core/models/contestant.dart';
import 'package:survivor_pool/core/models/pool.dart';
import 'package:survivor_pool/core/models/user.dart';
import 'package:survivor_pool/features/auth/presentation/forgot_password_page.dart';
import 'package:survivor_pool/features/auth/presentation/login_page.dart';
import 'package:survivor_pool/features/picks/presentation/pages/contestant_detail_page.dart';
import 'package:survivor_pool/features/pools/presentation/home_page.dart';
import 'package:survivor_pool/features/pools/presentation/pages/manage_pool_members_page.dart';
import 'package:survivor_pool/features/pools/presentation/pages/pool_advance_page.dart';
import 'package:survivor_pool/features/pools/presentation/pages/pool_leaderboard_page.dart';
import 'package:survivor_pool/features/pools/presentation/pages/pool_settings_page.dart';
import 'package:survivor_pool/features/profile/presentation/pages/profile_page.dart';
import 'package:survivor_pool/features/profile/presentation/pages/reset_password_page.dart';

class SurvivorPoolApp extends StatelessWidget {
  const SurvivorPoolApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.login),
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRouteNames.home,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is AppUser) {
            AppSession.currentUser.value = extra;
            return HomePage(user: extra);
          }
          final stored = AppSession.currentUser.value;
          if (stored != null) {
            return HomePage(user: stored);
          }
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: AppRouteNames.profile,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is AppUser) {
            AppSession.currentUser.value = extra;
            return ProfilePage(user: extra);
          }
          final stored = AppSession.currentUser.value;
          if (stored != null) {
            return ProfilePage(user: stored);
          }
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: AppRouteNames.resetPassword,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is AppUser) {
            AppSession.currentUser.value = extra;
            return ResetPasswordPage(user: extra);
          }
          final stored = AppSession.currentUser.value;
          if (stored != null) {
            return ResetPasswordPage(user: stored);
          }
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRoutes.poolSettings,
        name: AppRouteNames.poolSettings,
        builder: (context, state) {
          final extra =
              state.extra ??
              AppSession.getRouteExtra(AppRouteNames.poolSettings);
          if (extra is ({PoolOption pool, String ownerId})) {
            AppSession.cacheRouteExtra(AppRouteNames.poolSettings, extra);
            return PoolSettingsPage(pool: extra.pool, ownerId: extra.ownerId);
          }
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRoutes.poolAdvance,
        name: AppRouteNames.poolAdvance,
        builder: (context, state) {
          final extra =
              state.extra ??
              AppSession.getRouteExtra(AppRouteNames.poolAdvance);
          if (extra is ({PoolOption pool, String userId})) {
            AppSession.cacheRouteExtra(AppRouteNames.poolAdvance, extra);
            return PoolAdvancePage(pool: extra.pool, userId: extra.userId);
          }
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRoutes.poolLeaderboard,
        name: AppRouteNames.poolLeaderboard,
        builder: (context, state) {
          final extra =
              state.extra ??
              AppSession.getRouteExtra(AppRouteNames.poolLeaderboard);
          if (extra is ({PoolOption pool, String userId})) {
            AppSession.cacheRouteExtra(AppRouteNames.poolLeaderboard, extra);
            return PoolLeaderboardPage(pool: extra.pool, userId: extra.userId);
          }
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRoutes.manageMembers,
        name: AppRouteNames.manageMembers,
        builder: (context, state) {
          final extra =
              state.extra ??
              AppSession.getRouteExtra(AppRouteNames.manageMembers);
          if (extra is ({PoolOption pool, String ownerId})) {
            AppSession.cacheRouteExtra(AppRouteNames.manageMembers, extra);
            return ManagePoolMembersPage(
              pool: extra.pool,
              ownerId: extra.ownerId,
            );
          }
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRoutes.contestantDetail,
        name: AppRouteNames.contestantDetail,
        builder: (context, state) {
          final extra =
              state.extra ??
              AppSession.getRouteExtra(AppRouteNames.contestantDetail);
          if (extra
              is ({
                PoolOption pool,
                ContestantDetailResponse detail,
                Future<bool> Function() onLockPick,
              })) {
            AppSession.cacheRouteExtra(AppRouteNames.contestantDetail, extra);
            return ContestantDetailPage(
              pool: extra.pool,
              detail: extra.detail,
              onLockPick: extra.onLockPick,
            );
          }
          return const LoginPage();
        },
      ),
    ],
  );
  static bool _sessionHandlerRegistered = false;

  void _ensureSessionHandler() {
    if (_sessionHandlerRegistered) {
      return;
    }
    _sessionHandlerRegistered = true;
    AppSession.registerUnauthorizedHandler(() async {
      _router.go(AppRoutes.login);
    });
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B365D),
        brightness: Brightness.light,
      ),
      visualDensity: kIsWeb ? VisualDensity.compact : VisualDensity.standard,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      cardTheme: const CardThemeData(
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerColor: Colors.black26,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 4,
        centerTitle: false,
      ),
    );
    return base;
  }

  @override
  Widget build(BuildContext context) {
    _ensureSessionHandler();
    return MaterialApp.router(
      title: 'Survivor Pool',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: _router,
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };
}
