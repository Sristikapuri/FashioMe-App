import 'dart:io';

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

  final localFile = File(imagePath);
  if (localFile.isAbsolute && localFile.existsSync()) {
    return Image.file(localFile, fit: fit, errorBuilder: errorBuilder);
  }

  final resolvedImagePath = ApiEndpoints.resolveAssetUrl(imagePath);

  if (resolvedImagePath.startsWith('http://') ||
      resolvedImagePath.startsWith('https://')) {
    return Image.network(
      resolvedImagePath,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }

  return Image.file(
    File(resolvedImagePath),
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
