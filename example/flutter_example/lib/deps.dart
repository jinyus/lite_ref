import 'package:flutter_example/settings/controller.dart';
import 'package:flutter_example/settings/service.dart';
import 'package:lite_ref/lite_ref.dart';

final settingsServiceRef = Ref.singleton(create: SettingsService.new);

final settingsControllerRef = Ref.singleton(
  create: () => SettingsController(settingsServiceRef()),
);
