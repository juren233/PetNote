import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool _supportsHaptics() {
  if (kIsWeb) {
    return false;
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => false,
  };
}

void triggerSelectionHaptic() {
  if (!_supportsHaptics()) {
    return;
  }
  unawaited(HapticFeedback.selectionClick().catchError((_) {}));
}

void triggerLightImpactHaptic() {
  if (!_supportsHaptics()) {
    return;
  }
  unawaited(HapticFeedback.lightImpact().catchError((_) {}));
}
