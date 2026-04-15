import 'package:flutter/material.dart';
import 'package:petnote/app/app_theme.dart';
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
    final tokens = context.petNoteTokens;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: pets
          .map(
            (pet) => GestureDetector(
              onTap: () => onChanged(pet.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: value == pet.id
                      ? tokens.segmentedSelectedBackground
                      : tokens.secondarySurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  pet.name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: value == pet.id
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
