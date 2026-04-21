import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:petnote/app/app_version_info.dart';
import 'package:petnote/app/petnote_app.dart';
import 'package:petnote/app/system_ui_policy.dart';
import 'package:petnote/logging/app_crash_diagnostics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureStartupSystemUi();
  lockAppToPortrait();
  AppCrashDiagnosticsBinding.instance.installGlobalHandlers();
  runZonedGuarded(
    () {
      AppVersionInfo.load().then(
        (appVersionInfo) {
          runApp(PetNoteApp(appVersionInfo: appVersionInfo));
        },
        onError: (Object error, StackTrace stackTrace) {
          AppCrashDiagnosticsBinding.instance.recordZoneError(
            error,
            stackTrace,
          );
          runApp(const PetNoteApp());
        },
      );
    },
    AppCrashDiagnosticsBinding.instance.recordZoneError,
  );
}
