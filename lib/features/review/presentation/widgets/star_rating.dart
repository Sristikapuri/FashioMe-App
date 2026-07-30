import 'package:flutter/material.dart';
import 'package:fashio_me/app/theme/app_colors.dart';

/// Read-only star display for an average/given rating.
class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = rating >= index + 1;
        final half = !filled && rating > index && rating < index + 1;
        return Icon(
          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          size: size,
          color: AppColors.primary,
        );
      }),
    );
  }
}

/// Tappable 1-5 star input for writing/editing a review.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 32,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          onPressed: () => onChanged(starValue),
          icon: Icon(
            starValue <= rating ? Icons.star : Icons.star_border,
            color: AppColors.primary,
            size: size,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: size,
        );
      }),
    );
  }
}
