import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_care_harmony/app/navigation_palette.dart';
import 'package:pet_care_harmony/state/pet_care_store.dart';

void main() {
  test('maps each bottom tab to its own soft accent palette', () {
    expect(tabAccentFor(AppTab.checklist), const NavigationAccent(Color(0xFFF2C66D), Color(0xFFD39822)));
    expect(tabAccentFor(AppTab.overview), const NavigationAccent(Color(0xFFC8B0F4), Color(0xFF9071CC)));
    expect(tabAccentFor(AppTab.pets), const NavigationAccent(Color(0xFFF4B6C8), Color(0xFFD9829D)));
    expect(tabAccentFor(AppTab.me), const NavigationAccent(Color(0xFFAED3F8), Color(0xFF6D9FDC)));
  });
}
