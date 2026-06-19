import 'dart:io';

import 'package:flutter/material.dart';

Widget buildSelectedImage(
  String imagePath, {
  required BoxFit fit,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return Image.network(
      imagePath,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }

  return Image.file(
    File(imagePath),
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
