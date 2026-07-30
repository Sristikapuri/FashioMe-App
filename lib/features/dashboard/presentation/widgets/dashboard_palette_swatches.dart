import 'package:flutter/material.dart';

class DashboardPaletteSwatches extends StatelessWidget {
  const DashboardPaletteSwatches({super.key, required this.colors});
  final List<int> colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: colors.take(3).map((value) {
        return Container(
          margin: const EdgeInsets.only(left: 6),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Color(value),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
        );
      }).toList(),
    );
  }
}
