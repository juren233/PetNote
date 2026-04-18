import 'package:flutter/material.dart';
import 'package:petnote/app/navigation_palette.dart';
import 'package:petnote/state/petnote_store.dart';

@immutable
class OverviewBottomCtaState {
  const OverviewBottomCtaState({
    required this.visible,
    required this.enabled,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final bool visible;
  final bool enabled;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  bool matchesVisual(OverviewBottomCtaState? other) {
    return other != null &&
        other.visible == visible &&
        other.enabled == enabled &&
        other.label == label &&
        other.icon == icon;
  }
}

OverviewBottomCtaState? overviewBottomCtaFallbackState({
  required PetNoteStore store,
  required AppTab activeTab,
  required OverviewBottomCtaState? syncedState,
}) {
  if (activeTab != AppTab.overview) {
    return null;
  }
  if (syncedState?.visible ?? false) {
    return syncedState;
  }
  if (store.pets.isEmpty) {
    return null;
  }
  final reportState = store.overviewAiReportState;
  final shouldShowSetup = !reportState.hasReport &&
      !reportState.isLoading &&
      !(reportState.hasRequested && reportState.errorMessage != null);
  if (!shouldShowSetup) {
    return null;
  }
  return const OverviewBottomCtaState(
    visible: true,
    enabled: false,
    label: '生成总览',
    icon: Icons.auto_awesome_rounded,
  );
}

class OverviewBottomCtaController
    extends ValueNotifier<OverviewBottomCtaState?> {
  OverviewBottomCtaController() : super(null);

  bool _isDisposed = false;

  void update(OverviewBottomCtaState? nextState) {
    if (_isDisposed) {
      return;
    }
    final currentState = value;
    if (currentState == null && nextState == null) {
      return;
    }
    if (currentState != null && nextState != null) {
      if (currentState.matchesVisual(nextState)) {
        return;
      }
    }
    value = nextState;
  }

  void clear() => update(null);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class OverviewBottomCtaBar extends StatelessWidget {
  const OverviewBottomCtaBar({
    super.key,
    required this.state,
  });

  final OverviewBottomCtaState state;

  @override
  Widget build(BuildContext context) {
    if (!state.visible) {
      return const SizedBox.shrink();
    }
    final accentColor = tabAccentFor(context, AppTab.overview).label;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const ValueKey('overview-floating-generate-button'),
        onPressed: state.enabled ? state.onPressed : null,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB8BCC6),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: Icon(state.icon, size: 18),
        label: Text(state.label),
      ),
    );
  }
}
