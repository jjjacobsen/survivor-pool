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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Survivor Pool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B365D),
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
