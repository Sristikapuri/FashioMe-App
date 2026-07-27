import 'package:dio/dio.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import '../models/review_model.dart';

class ReviewRemoteDataSource {
  final Dio _dio;

  ReviewRemoteDataSource({
    required Dio dio,
  }) : _dio = dio;

  Future<List<ReviewModel>> getReviewsByClothe(String clotheId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}/reviews/clothe/$clotheId',
      );

      final body = _asMap(response.data);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final payload = body['responseData'];
        final data = payload is Map ? payload['reviews'] : payload;
        if (data is List) {
          return data
              .whereType<Map>()
              .map((json) => ReviewModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      }
      throw Exception('Failed to load reviews');
    } catch (e) {
      throw Exception('Error fetching reviews: $e');
    }
  }

  Future<List<ReviewModel>> getMyReviews() async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}/reviews/my',
      );

      final body = _asMap(response.data);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        final data = body['responseData'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map((json) => ReviewModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      }
      throw Exception('Failed to load my reviews');
    } catch (e) {
      throw Exception('Error fetching my reviews: $e');
    }
  }

  Future<ReviewModel> createReview({
    required String clotheId,
    required int rating,
    String? title,
    required String comment,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.baseUrl}/reviews',
        data: {
          'clotheId': clotheId,
          'rating': rating,
          if (title != null && title.isNotEmpty) 'title': title,
          'comment': comment,
        },
      );

      final body = _asMap(response.data);
      if (response.statusCode == 201 && body['isSuccess'] == true) {
        return ReviewModel.fromJson(
          Map<String, dynamic>.from(body['responseData'] as Map),
        );
      }
      throw Exception('Failed to create review');
    } catch (e) {
      throw Exception('Error creating review: $e');
    }
  }

  Future<ReviewModel> updateReview({
    required String reviewId,
    required int rating,
    String? title,
    required String comment,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.baseUrl}/reviews/$reviewId',
        data: {
          'rating': rating,
          if (title != null && title.isNotEmpty) 'title': title,
          'comment': comment,
        },
      );

      final body = _asMap(response.data);
      if (response.statusCode == 200 && body['isSuccess'] == true) {
        return ReviewModel.fromJson(
          Map<String, dynamic>.from(body['responseData'] as Map),
        );
      }
      throw Exception('Failed to update review');
    } catch (e) {
      throw Exception('Error updating review: $e');
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      final response = await _dio.delete(
        '${ApiEndpoints.baseUrl}/reviews/$reviewId',
      );

      if (response.statusCode != 200 || _asMap(response.data)['isSuccess'] != true) {
        throw Exception('Failed to delete review');
      }
    } catch (e) {
      throw Exception('Error deleting review: $e');
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
