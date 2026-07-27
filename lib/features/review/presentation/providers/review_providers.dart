import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/features/review/data/datasources/review_remote_datasource.dart';
import 'package:fashio_me/features/review/data/repositories/review_repository_impl.dart';
import 'package:fashio_me/features/review/domain/repositories/review_repository.dart';
import 'package:fashio_me/features/review/domain/usecases/create_review_usecase.dart';
import 'package:fashio_me/features/review/domain/usecases/get_reviews_by_clothe_usecase.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(
    remoteDataSource: ReviewRemoteDataSource(
      dio: ref.read(apiClientProvider).dio,
    ),
  );
});

final getReviewsByClotheUseCaseProvider = Provider<GetReviewsByClotheUseCase>(
  (ref) => GetReviewsByClotheUseCase(ref.read(reviewRepositoryProvider)),
);

final createReviewUseCaseProvider = Provider<CreateReviewUseCase>(
  (ref) => CreateReviewUseCase(ref.read(reviewRepositoryProvider)),
);
