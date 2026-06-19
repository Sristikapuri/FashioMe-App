import 'dart:io';

import 'package:flutter/material.dart';

Widget buildSelectedImage(
  String imagePath, {
  required BoxFit fit,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  return Image.file(
    File(imagePath),
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
