import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/extensions/context_extensions.dart';
import 'package:fashio_me/features/review/domain/entities/review.dart';
import 'package:fashio_me/features/review/presentation/providers/review_providers.dart';
import 'package:fashio_me/features/review/presentation/widgets/star_rating.dart';


/// [Review] on success, or null if the sheet was dismissed/failed.
Future<Review?> showReviewFormSheet(
  BuildContext context, {
  required String clotheId,
  Review? existingReview,
}) {
  return showModalBottomSheet<Review>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ReviewFormSheet(
      clotheId: clotheId,
      existingReview: existingReview,
    ),
  );
}

class ReviewFormSheet extends ConsumerStatefulWidget {
  const ReviewFormSheet({super.key, required this.clotheId, this.existingReview});

  final String clotheId;
  final Review? existingReview;

  @override
  ConsumerState<ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends ConsumerState<ReviewFormSheet> {
  late int _rating = widget.existingReview?.rating ?? 5;
  late final _titleController = TextEditingController(
    text: widget.existingReview?.title ?? '',
  );
  late final _commentController = TextEditingController(
    text: widget.existingReview?.comment ?? '',
  );
  bool _isSubmitting = false;
  String? _error;

  bool get _isEditing => widget.existingReview != null;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      setState(() => _error = 'Please write a comment.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final title = _titleController.text.trim();
    final result = _isEditing
        ? await ref.read(updateReviewUseCaseProvider).call(
              reviewId: widget.existingReview!.id,
              rating: _rating,
              title: title.isEmpty ? null : title,
              comment: comment,
            )
        : await ref.read(createReviewUseCaseProvider).call(
              clotheId: widget.clotheId,
              rating: _rating,
              title: title.isEmpty ? null : title,
              comment: comment,
            );

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isSubmitting = false;
        _error = failure.message;
      }),
      (review) => context.pop(review),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        context.viewInsetsBottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit your review' : 'Write a review',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Center(
              child: StarRatingInput(
                rating: _rating,
                onChanged: (value) => setState(() => _rating = value),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Your review',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Submit review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
