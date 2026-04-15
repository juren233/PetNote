import 'package:flutter/material.dart';

class FormShell extends StatelessWidget {
  const FormShell({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF17181C),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class ExpandedFormShell extends StatelessWidget {
  const ExpandedFormShell({
    super.key,
    required this.topInset,
    required this.child,
  });

  final double topInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topInset),
      child: child,
    );
  }
}

class FormScaffold extends StatelessWidget {
  const FormScaffold({
    super.key,
    required this.child,
    required this.actionLabel,
    required this.onSubmit,
    required this.actionColor,
  });

  final Widget child;
  final String actionLabel;
  final Future<void> Function() onSubmit;
  final Color actionColor;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset + 24),
            child: child,
          ),
        ),
        const SizedBox(height: 16),
        SafeArea(
          top: false,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
            ),
            onPressed: onSubmit,
            child: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}
