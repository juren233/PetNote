import 'package:flutter/material.dart';
import 'package:pet_care_harmony/app/app_theme.dart';
import 'package:pet_care_harmony/state/pet_care_store.dart';

class NavigationAccent {
  const NavigationAccent(this.fill, this.label);

  final Color fill;
  final Color label;

  @override
  bool operator ==(Object other) {
    return other is NavigationAccent &&
        other.fill == fill &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(fill, label);
}

NavigationAccent tabAccentFor(BuildContext context, AppTab tab) {
  final scheme = Theme.of(context).colorScheme;
  return switch (tab) {
    AppTab.checklist => NavigationAccent(scheme.primary, scheme.primary),
    AppTab.overview =>
      const NavigationAccent(Color(0xFF9B84E8), Color(0xFF9B84E8)),
    AppTab.pets => NavigationAccent(
        darkPetCareTokens.badgeRedForeground,
        darkPetCareTokens.badgeRedForeground,
      ),
    AppTab.me => NavigationAccent(
        darkPetCareTokens.badgeBlueForeground,
        darkPetCareTokens.badgeBlueForeground,
      ),
  };
}
