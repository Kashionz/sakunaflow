import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || !Platform.isWindows || _initialized) return;

    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        windows: WindowsInitializationSettings(
          appName: 'SakunaFlow',
          appUserModelId: 'Kashionz.SakunaFlow.LocalCore',
          guid: '6e0f2c4a-9b7d-4cf3-89d0-a11d8b4f4e0c',
        ),
      ),
    );
    _initialized = initialized ?? false;
  }

  Future<void> showPomodoroComplete({required String taskTitle}) async {
    if (kIsWeb || !Platform.isWindows) return;
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return;

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: '專注完成',
      body: '$taskTitle 的番茄鐘已完成，準備休息一下。',
      notificationDetails: const NotificationDetails(
        windows: WindowsNotificationDetails(
          duration: WindowsNotificationDuration.long,
        ),
      ),
    );
  }
}
