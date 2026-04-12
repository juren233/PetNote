import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:petnote/app/petnote_app.dart';
import 'package:petnote/app/system_ui_policy.dart';
import 'package:petnote/logging/app_crash_diagnostics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureStartupSystemUi();
  AppCrashDiagnosticsBinding.instance.installGlobalHandlers();
  runZonedGuarded(
    () {
      runApp(const PetNoteApp());
    },
    AppCrashDiagnosticsBinding.instance.recordZoneError,
  );
}
