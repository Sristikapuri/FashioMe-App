import 'dart:io';

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

  final localFile = File(imagePath);
  if (localFile.isAbsolute && localFile.existsSync()) {
    return Image.file(localFile, fit: fit, errorBuilder: errorBuilder);
  }

  final resolvedImagePath = ApiEndpoints.resolveAssetUrl(imagePath);

  if (resolvedImagePath.startsWith('http://') ||
      resolvedImagePath.startsWith('https://')) {
    return CachedNetworkImage(
      imageUrl: resolvedImagePath,
      fit: fit,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) =>
          errorBuilder(context, error, StackTrace.empty),
    );
  }

  return Image.file(
    File(resolvedImagePath),
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
