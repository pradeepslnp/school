import 'package:flutter/material.dart';

import 'app/admin_app.dart';
import 'app/app_config.dart';
import 'app/dependencies.dart';

/// Entry point for the Guardian administration console.
///
/// Bootstraps before the first frame. The awaits are what keep the console from rendering
/// sign-in to someone who is already authenticated, and from letting a widget dispatch a
/// request before the session that authorizes it exists.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final dependencies = await AppDependencies.bootstrap(config);

  runApp(GuardianAdminApp(dependencies: dependencies));
}
