import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:survivor_pool/core/models/user.dart';
import 'package:survivor_pool/features/auth/presentation/login_page.dart';
import 'package:survivor_pool/app/routes.dart';
import 'package:survivor_pool/features/pools/presentation/home_page.dart';
import 'package:survivor_pool/features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        final args = settings.arguments;
        if (args is AppUser) {
          return MaterialPageRoute(builder: (_) => HomePage(user: args));
        }
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.profile:
        final args = settings.arguments;
        if (args is AppUser) {
          return MaterialPageRoute(builder: (_) => ProfilePage(user: args));
        }
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.login:
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}

class SurvivorPoolApp extends StatelessWidget {
  const SurvivorPoolApp({super.key});

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
    return MaterialApp(
      title: 'Survivor Pool',
      theme: _buildTheme(),
      scrollBehavior: const AppScrollBehavior(),
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
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
