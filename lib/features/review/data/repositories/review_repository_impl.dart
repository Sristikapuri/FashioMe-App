import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/review/data/datasources/review_remote_datasource.dart';
import 'package:fashio_me/features/review/data/models/review_model.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl({required this.remoteDataSource});

  final ReviewRemoteDataSource remoteDataSource;

  Review _toEntity(ReviewModel model) => Review(
        id: model.id,
        clotheId: model.clotheId,
        userId: model.userId,
        rating: model.rating,
        title: model.title,
        comment: model.comment,
        verifiedPurchase: model.verifiedPurchase,
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
        clothe: model.clothe == null
            ? null
            : Clothe(
                name: model.clothe!.name,
                imageUrl: model.clothe!.imageUrl,
                price: model.clothe!.price,
                category: model.clothe!.category,
              ),
      );

  @override
  Future<Either<Failure, List<Review>>> getReviewsByClothe(
    String clotheId,
  ) async {
    try {
      final models = await remoteDataSource.getReviewsByClothe(clotheId);
      return Right(models.map(_toEntity).toList(growable: false));
    } catch (e) {
      return Left(ApiFailure(message: 'Failed to get reviews: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Review>>> getMyReviews() async {
    try {
      final models = await remoteDataSource.getMyReviews();
      return Right(models.map(_toEntity).toList(growable: false));
    } catch (e) {
      return Left(ApiFailure(message: 'Failed to get my reviews: $e'));
    }
  }

  @override
  Future<Either<Failure, Review>> createReview({
    required String clotheId,
    required int rating,
    String? title,
    required String comment,
  }) async {
    try {
      final model = await remoteDataSource.createReview(
        clotheId: clotheId,
        rating: rating,
        title: title,
        comment: comment,
      );
      return Right(_toEntity(model));
    } catch (e) {
      return Left(ApiFailure(message: 'Failed to create review: $e'));
    }
  }

  @override
  Future<Either<Failure, Review>> updateReview({
    required String reviewId,
    required int rating,
    String? title,
    required String comment,
  }) async {
    try {
      final model = await remoteDataSource.updateReview(
        reviewId: reviewId,
        rating: rating,
        title: title,
        comment: comment,
      );
      return Right(_toEntity(model));
    } catch (e) {
      return Left(ApiFailure(message: 'Failed to update review: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) async {
    try {
      await remoteDataSource.deleteReview(reviewId);
      return const Right(null);
    } catch (e) {
      return Left(ApiFailure(message: 'Failed to delete review: $e'));
    }
  }
}
