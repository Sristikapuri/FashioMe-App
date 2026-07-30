import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:fashio_me/features/review/domain/entities/review.dart';
import 'package:fashio_me/features/review/domain/repositories/review_repository.dart';
import 'package:fashio_me/features/review/presentation/providers/review_providers.dart';
import 'package:fashio_me/features/review/presentation/widgets/reviews_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeReviewRepository implements ReviewRepository {
  final List<Review> reviews = [];
  int _nextId = 1;

  @override
  Future<Either<Failure, List<Review>>> getReviewsByClothe(String clotheId) async {
    return Right(reviews.where((r) => r.clotheId == clotheId).toList());
  }

  @override
  Future<Either<Failure, List<Review>>> getMyReviews() async => Right(reviews);

  @override
  Future<Either<Failure, Review>> createReview({
    required String clotheId,
    required int rating,
    String? title,
    required String comment,
  }) async {
    final review = Review(
      id: 'r${_nextId++}',
      clotheId: clotheId,
      userId: 'me',
      rating: rating,
      title: title,
      comment: comment,
      verifiedPurchase: false,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      reviewer: Reviewer(firstName: 'Test', lastName: 'User'),
    );
    reviews.add(review);
    return Right(review);
  }

  @override
  Future<Either<Failure, Review>> updateReview({
    required String reviewId,
    required int rating,
    String? title,
    required String comment,
  }) async {
    final index = reviews.indexWhere((r) => r.id == reviewId);
    final updated = Review(
      id: reviewId,
      clotheId: reviews[index].clotheId,
      userId: reviews[index].userId,
      rating: rating,
      title: title,
      comment: comment,
      verifiedPurchase: reviews[index].verifiedPurchase,
      createdAt: reviews[index].createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      reviewer: reviews[index].reviewer,
    );
    reviews[index] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) async {
    reviews.removeWhere((r) => r.id == reviewId);
    return const Right(null);
  }
}

void main() {
  late FakeReviewRepository fakeRepository;
  late SharedPreferences prefs;

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        reviewRepositoryProvider.overrideWithValue(fakeRepository),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  setUp(() async {
    fakeRepository = FakeReviewRepository();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('shows empty state and a write-a-review button when there are no reviews', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const ReviewsSection(clotheId: 'clothe-1')));
    await tester.pumpAndSettle();

    expect(find.text('Reviews'), findsOneWidget);
    expect(find.text('No reviews yet. Be the first to share your thoughts.'), findsOneWidget);
    expect(find.text('Write a review'), findsOneWidget);
  });

  testWidgets('submitting the review form adds the review to the list', (tester) async {
    await tester.pumpWidget(wrap(const ReviewsSection(clotheId: 'clothe-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Write a review'));
    await tester.pumpAndSettle();

    expect(find.text('Write a review'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).last, 'Fits perfectly and great quality.');
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    expect(fakeRepository.reviews, hasLength(1));
    expect(fakeRepository.reviews.single.comment, 'Fits perfectly and great quality.');
    expect(find.text('Fits perfectly and great quality.'), findsOneWidget);
    expect(find.text('No reviews yet. Be the first to share your thoughts.'), findsNothing);
  });
}
