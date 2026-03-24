import 'package:flutter/material.dart';
import 'package:pet_care_harmony/state/pet_care_store.dart';

class NavigationAccent {
  const NavigationAccent(this.fill, this.label);

  final Color fill;
  final Color label;

  @override
  bool operator ==(Object other) {
    return other is NavigationAccent && other.fill == fill && other.label == label;
  }

  @override
  int get hashCode => Object.hash(fill, label);
}

NavigationAccent tabAccentFor(AppTab tab) => switch (tab) {
      AppTab.checklist => const NavigationAccent(Color(0xFFF2C66D), Color(0xFFD39822)),
      AppTab.overview => const NavigationAccent(Color(0xFFC8B0F4), Color(0xFF9071CC)),
      AppTab.pets => const NavigationAccent(Color(0xFFF4B6C8), Color(0xFFD9829D)),
      AppTab.me => const NavigationAccent(Color(0xFFAED3F8), Color(0xFF6D9FDC)),
    };
