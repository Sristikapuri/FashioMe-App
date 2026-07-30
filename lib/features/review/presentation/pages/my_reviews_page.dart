import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/extensions/context_extensions.dart';
import 'package:fashio_me/features/review/domain/entities/review.dart';
import 'package:fashio_me/features/review/presentation/providers/review_providers.dart';
import 'package:fashio_me/features/review/presentation/widgets/review_form_sheet.dart';
import 'package:fashio_me/features/review/presentation/widgets/star_rating.dart';

class MyReviewsPage extends ConsumerStatefulWidget {
  const MyReviewsPage({super.key});

  @override
  ConsumerState<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends ConsumerState<MyReviewsPage> {
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

    final result = await ref.read(getMyReviewsUseCaseProvider).call();

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = 'Failed to load your reviews.';
      }),
      (reviews) => setState(() {
        _loading = false;
        _reviews = reviews;
      }),
    );
  }

  Future<void> _edit(Review review) async {
    final updated = await showReviewFormSheet(
      context,
      clotheId: review.clotheId,
      existingReview: review,
    );
    if (updated != null) _load();
  }

  Future<void> _delete(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete review'),
        content: const Text('This review will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref.read(deleteReviewUseCaseProvider).call(review.id);
    if (!mounted) return;

    result.fold(
      (failure) => context.showSnackBar(
        'Failed to delete review.',
        isError: true,
      ),
      (_) => setState(() {
        _reviews = _reviews.where((r) => r.id != review.id).toList();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 12),
                  ],
                  if (_reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text('You haven\'t written any reviews yet.'),
                      ),
                    )
                  else
                    ..._reviews.map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MyReviewCard(
                          review: review,
                          onEdit: () => _edit(review),
                          onDelete: () => _delete(review),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _MyReviewCard extends StatelessWidget {
  const _MyReviewCard({
    required this.review,
    required this.onEdit,
    required this.onDelete,
  });

  final Review review;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: (review.clothe?.imageUrl == null)
                      ? Container(
                          color: AppColors.surfaceMuted,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : Image.network(
                          review.clothe!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.surfaceMuted,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  review.clothe?.name ?? 'Product',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.primary,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error,
              ),
            ],
          ),
          StarRatingDisplay(rating: review.rating.toDouble(), size: 14),
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
