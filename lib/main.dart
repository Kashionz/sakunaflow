import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'features/notifications/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!const bool.fromEnvironment('FLUTTER_TEST')) {
    await windowManager.ensureInitialized();
    await LocalNotificationService.instance.initialize();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: 'SakunaFlow',
        minimumSize: Size(800, 600),
        size: Size(1120, 760),
        center: true,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  runApp(const SakunaFlowApp());
}
