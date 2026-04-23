import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ios update notification opens release url directly', () {
    final source = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(source, contains('case "showUpdateNotification":'));
    expect(source, contains('content.userInfo = ["releaseUrl": releaseUrl]'));
    expect(
        source,
        contains(
            'response.notification.request.content.userInfo["releaseUrl"]'));
    expect(source, contains('UIApplication.shared.open(url, options: [:])'));
  });
}
