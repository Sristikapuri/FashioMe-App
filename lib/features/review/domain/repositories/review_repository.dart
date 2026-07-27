import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import '../entities/review.dart';

abstract class ReviewRepository {
  Future<Either<Failure, List<Review>>> getReviewsByClothe(String clotheId);
  Future<Either<Failure, List<Review>>> getMyReviews();
  Future<Either<Failure, Review>> createReview({
    required String clotheId,
    required int rating,
    String? title,
    required String comment,
  });
  Future<Either<Failure, Review>> updateReview({
    required String reviewId,
    required int rating,
    String? title,
    required String comment,
  });
  Future<Either<Failure, void>> deleteReview(String reviewId);
}
