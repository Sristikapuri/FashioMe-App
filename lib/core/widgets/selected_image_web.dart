import 'package:flutter/material.dart';

Widget buildSelectedImage(
  String imagePath, {
  required BoxFit fit,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  return Image.network(
    imagePath,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
