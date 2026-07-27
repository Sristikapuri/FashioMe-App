import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

class GetMyReviewsUseCase {
  final ReviewRepository repository;

  GetMyReviewsUseCase(this.repository);

  Future<Either<Failure, List<Review>>> call() {
    return repository.getMyReviews();
  }
}
