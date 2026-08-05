import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:flutter/material.dart';

Widget buildSelectedImage(
  String imagePath, {
  required BoxFit fit,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  if (imagePath.startsWith('assets/')) {
    return Image.asset(imagePath, fit: fit, errorBuilder: errorBuilder);
  }

  return CachedNetworkImage(
    imageUrl: ApiEndpoints.resolveAssetUrl(imagePath),
    fit: fit,
    placeholder: (context, url) => const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    errorWidget: (context, url, error) =>
        errorBuilder(context, error, StackTrace.empty),
  );
}
