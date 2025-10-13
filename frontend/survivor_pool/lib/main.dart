import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: _envFileName());
  runApp(const SurvivorPoolApp());
}

String _envFileName() {
  const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  return appEnv == 'prod' ? 'assets/env/.env.prod' : 'assets/env/.env.dev';
}
