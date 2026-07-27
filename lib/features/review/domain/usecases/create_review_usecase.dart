import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

class CreateReviewUseCase {
  final ReviewRepository repository;

  CreateReviewUseCase(this.repository);

  Future<Either<Failure, Review>> call({
    required String clotheId,
    required int rating,
    String? title,
    required String comment,
  }) {
    return repository.createReview(
      clotheId: clotheId,
      rating: rating,
      title: title,
      comment: comment,
    );
  }
}
