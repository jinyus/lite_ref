import 'package:flutter_example/settings/controller.dart';
import 'package:flutter_example/settings/service.dart';
import 'package:lite_ref/lite_ref.dart';

final settingsServiceRef = Ref.scoped((ctx) => SettingsService());

final settingsControllerRef = Ref.scopedAsync(
  (context) async {
    final controller = SettingsController(settingsServiceRef(context));
    await controller.loadSettings();
    return controller;
  },
  autoDispose: false,
);
