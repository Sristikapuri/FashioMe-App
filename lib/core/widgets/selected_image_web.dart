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

  return Image.network(
    ApiEndpoints.resolveAssetUrl(imagePath),
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
