import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'core/logging/app_logger.dart';
import 'core/logging/log_output.dart';

import 'config/application_bindings.dart';
import 'app/main_app.dart';

void main() {
  AppLogger.configure(
    level: kDebugMode ? Level.ALL : Level.INFO,
    outputs: const [ConsoleLogOutput()],
  );
  runApp(ApplicationBindings(child: const MainApp()));
}
