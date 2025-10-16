import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_strategy/url_strategy.dart';

import 'app/app.dart';
import 'app/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    setPathUrlStrategy();
  }
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await AppSession.restore();
  runApp(const SurvivorPoolApp());
}
