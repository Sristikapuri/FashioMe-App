import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_session_providers.dart';
import 'package:fashio_me/features/review/domain/entities/review.dart';
import 'package:fashio_me/features/review/presentation/providers/review_providers.dart';
import 'package:fashio_me/features/review/presentation/widgets/review_form_sheet.dart';
import 'package:fashio_me/features/review/presentation/widgets/star_rating.dart';


class ReviewsSection extends ConsumerStatefulWidget {
  const ReviewsSection({super.key, required this.clotheId});

  final String clotheId;

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  bool _loading = true;
  String? _error;
  List<Review> _reviews = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref
        .read(getReviewsByClotheUseCaseProvider)
        .call(widget.clotheId);

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = 'Unable to load reviews.';
      }),
      (reviews) => setState(() {
        _loading = false;
        _reviews = reviews;
      }),
    );
  }

  Future<void> _openForm({Review? existingReview}) async {
    final result = await showReviewFormSheet(
      context,
      clotheId: widget.clotheId,
      existingReview: existingReview,
    );
    if (result != null) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authSessionViewModelProvider).user?.authId;
    final myReview = currentUserId == null
        ? null
        : _reviews.where((r) => r.userId == currentUserId).firstOrNull;

    final averageRating = _reviews.isEmpty
        ? 0.0
        : _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            if (!_loading)
              TextButton(
                onPressed: () => _openForm(existingReview: myReview),
                child: Text(myReview == null ? 'Write a review' : 'Edit your review'),
              ),
          ],
        ),
        if (!_loading && _reviews.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              StarRatingDisplay(rating: averageRating),
              const SizedBox(width: 8),
              Text(
                '${averageRating.toStringAsFixed(1)} · ${_reviews.length} '
                '${_reviews.length == 1 ? 'review' : 'reviews'}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: AppColors.error))
        else if (_reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No reviews yet. Be the first to share your thoughts.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ..._reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(review: review),
            ),
          ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRatingDisplay(rating: review.rating.toDouble(), size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.reviewer?.displayName ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (review.verifiedPurchase)
                const Text(
                  'Verified purchase',
                  style: TextStyle(fontSize: 11, color: AppColors.success),
                ),
            ],
          ),
          if (review.title != null && review.title!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.title!, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 6),
          Text(review.comment),
        ],
      ),
    );
  }
}
