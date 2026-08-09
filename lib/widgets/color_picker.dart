import 'package:flutter/material.dart';

import '../core/constants.dart';

/// A row of preset color swatches. Highlights the currently [selected] color
/// and reports taps through [onSelected].
class ColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onSelected;

  const ColorPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in kHabitPalette)
          GestureDetector(
            onTap: () => onSelected(c),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      c.toARGB32() == selected.toARGB32()
                          ? Colors.black
                          : Colors.transparent,
                  width: 2,
                ),
              ),
              child:
                  c.toARGB32() == selected.toARGB32()
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
            ),
          ),
      ],
    );
  }
}
