import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/review_repository.dart';

class GetReviewsByClotheUseCase {
  final ReviewRepository repository;

  GetReviewsByClotheUseCase(this.repository);

  Future<Either<Failure, List<Review>>> call(String clotheId) {
    return repository.getReviewsByClothe(clotheId);
  }
}
