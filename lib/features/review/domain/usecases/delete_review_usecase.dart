import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import '../repositories/review_repository.dart';

class DeleteReviewUseCase {
  final ReviewRepository repository;

  DeleteReviewUseCase(this.repository);

  Future<Either<Failure, void>> call(String reviewId) {
    return repository.deleteReview(reviewId);
  }
}
