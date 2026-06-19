import 'package:flutter/material.dart';

import 'selected_image_io.dart'
    if (dart.library.html) 'selected_image_web.dart' as selected_image;

Widget buildSelectedImage(
  String imagePath, {
  required BoxFit fit,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  return selected_image.buildSelectedImage(
    imagePath,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
