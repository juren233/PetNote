import 'package:flutter/material.dart';
import 'package:petnote/app/app_theme.dart';
import 'package:petnote/app/interaction_feedback.dart';
import 'package:petnote/state/petnote_store.dart';

class PetSelector extends StatelessWidget {
  const PetSelector({
    super.key,
    required this.pets,
    required this.value,
    required this.onChanged,
  });

  final List<Pet> pets;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: pets
          .map(
            (pet) => _PetSelectorChip(
              key: ValueKey('pet-selector-chip-${pet.id}'),
              label: pet.name,
              selected: value == pet.id,
              onTap: () {
                triggerSelectionHaptic();
                onChanged(pet.id);
              },
            ),
          )
          .toList(),
    );
  }
}

class _PetSelectorChip extends StatefulWidget {
  const _PetSelectorChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PetSelectorChip> createState() => _PetSelectorChipState();
}

class _PetSelectorChipState extends State<_PetSelectorChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.petNoteTokens;
    final shadowColor = widget.selected
        ? const Color(0x334F7BFF)
        : const Color(0x14000000);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        scale: _pressed ? 0.95 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? tokens.segmentedSelectedBackground
                : tokens.secondarySurface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: widget.selected && !_pressed ? 18 : 8,
                offset: Offset(0, _pressed ? 2 : 8),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: widget.selected ? Colors.white : tokens.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
