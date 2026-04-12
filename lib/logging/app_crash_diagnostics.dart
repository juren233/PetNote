import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:petnote/logging/app_log_controller.dart';

typedef _PendingCrashWrite = void Function(AppLogController controller);

class AppCrashDiagnosticsBinding {
  AppCrashDiagnosticsBinding._();

  static final AppCrashDiagnosticsBinding instance =
      AppCrashDiagnosticsBinding._();

  FlutterExceptionHandler? _previousFlutterErrorHandler;
  ErrorCallback? _previousPlatformErrorHandler;
  AppLogController? _controller;
  final List<_PendingCrashWrite> _pendingWrites = <_PendingCrashWrite>[];
  bool _installed = false;

  void installGlobalHandlers() {
    if (_installed) {
      return;
    }
    _installed = true;
    _previousFlutterErrorHandler = FlutterError.onError;
    _previousPlatformErrorHandler = PlatformDispatcher.instance.onError;

    FlutterError.onError = (details) {
      _recordFlutterError(details);
      _previousFlutterErrorHandler?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      _recordDartError(
        error,
        stackTrace,
        source: 'platform_dispatcher',
      );
      final previouslyHandled =
          _previousPlatformErrorHandler?.call(error, stackTrace) ?? false;
      return previouslyHandled || true;
    };
  }

  void attachController(AppLogController controller) {
    _controller = controller;
    if (_pendingWrites.isEmpty) {
      return;
    }
    final pendingWrites = List<_PendingCrashWrite>.from(_pendingWrites);
    _pendingWrites.clear();
    for (final write in pendingWrites) {
      write(controller);
    }
  }

  void detachController(AppLogController controller) {
    if (identical(_controller, controller)) {
      _controller = null;
    }
  }

  void recordZoneError(
    Object error,
    StackTrace stackTrace,
  ) {
    _recordDartError(error, stackTrace, source: 'zone');
  }

  @visibleForTesting
  void resetForTesting() {
    if (_installed) {
      FlutterError.onError = _previousFlutterErrorHandler;
      PlatformDispatcher.instance.onError = _previousPlatformErrorHandler;
    }
    _previousFlutterErrorHandler = null;
    _previousPlatformErrorHandler = null;
    _controller = null;
    _pendingWrites.clear();
    _installed = false;
  }

  void _recordFlutterError(FlutterErrorDetails details) {
    _writeOrBuffer(
      (controller) => controller.captureUnhandledFlutterError(details),
    );
  }

  void _recordDartError(
    Object error,
    StackTrace stackTrace, {
    required String source,
  }) {
    _writeOrBuffer(
      (controller) => controller.captureUnhandledDartError(
        error,
        stackTrace,
        source: source,
      ),
    );
  }

  void _writeOrBuffer(_PendingCrashWrite write) {
    final controller = _controller;
    if (controller != null) {
      write(controller);
      return;
    }
    _pendingWrites.add(write);
  }
}
