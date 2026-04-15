import 'package:flutter/material.dart';
import 'package:petnote/app/app_theme.dart';

class ChoiceWrap<T> extends StatelessWidget {
  const ChoiceWrap({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.petNoteTokens;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values
          .map(
            (value) => GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected == value
                      ? tokens.segmentedSelectedBackground
                      : tokens.secondarySurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  labelBuilder(value),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected == value
                            ? Colors.white
                            : tokens.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
