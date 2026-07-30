import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

class UpdateReviewUseCase {
  final ReviewRepository repository;

  UpdateReviewUseCase(this.repository);

  Future<Either<Failure, Review>> call({
    required String reviewId,
    required int rating,
    String? title,
    required String comment,
  }) {
    return repository.updateReview(
      reviewId: reviewId,
      rating: rating,
      title: title,
      comment: comment,
    );
  }
}
