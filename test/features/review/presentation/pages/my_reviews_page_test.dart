import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/review/domain/entities/review.dart';
import 'package:fashio_me/features/review/domain/repositories/review_repository.dart';
import 'package:fashio_me/features/review/presentation/pages/my_reviews_page.dart';
import 'package:fashio_me/features/review/presentation/providers/review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReviewRepository implements ReviewRepository {
  final List<Review> reviews;

  FakeReviewRepository(this.reviews);

  @override
  Future<Either<Failure, List<Review>>> getReviewsByClothe(
    String clotheId,
  ) async => Right(reviews);

  @override
  Future<Either<Failure, List<Review>>> getMyReviews() async => Right(reviews);

  @override
  Future<Either<Failure, Review>> createReview({
    required String clotheId,
    required int rating,
    String? title,
    required String comment,
  }) async => Left(const ApiFailure(message: 'not used'));

  @override
  Future<Either<Failure, Review>> updateReview({
    required String reviewId,
    required int rating,
    String? title,
    required String comment,
  }) async => Left(const ApiFailure(message: 'not used'));

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) async {
    reviews.removeWhere((r) => r.id == reviewId);
    return const Right(null);
  }
}

Review _review() {
  return Review(
    id: 'r1',
    clotheId: 'clothe-1',
    userId: 'me',
    rating: 4,
    title: 'Great fit',
    comment: 'Very comfortable and true to size.',
    verifiedPurchase: true,
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
    clothe: Clothe(name: 'Silk Blazer', price: 89.99, category: 'outerwear'),
  );
}

void main() {
  Widget wrap(ReviewRepository repository) {
    return ProviderScope(
      overrides: [reviewRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: MyReviewsPage()),
    );
  }

  testWidgets('shows the empty state when the user has no reviews', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(FakeReviewRepository([])));
    await tester.pumpAndSettle();

    expect(find.text("You haven't written any reviews yet."), findsOneWidget);
  });

  testWidgets('lists a review and deletes it via the confirm dialog', (
    tester,
  ) async {
    final repository = FakeReviewRepository([_review()]);
    await tester.pumpWidget(wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('Silk Blazer'), findsOneWidget);
    expect(find.text('Very comfortable and true to size.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete review'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.reviews, isEmpty);
    expect(find.text("You haven't written any reviews yet."), findsOneWidget);
  });
}
