import 'package:flutter/material.dart';
import 'package:fashio_me/core/widgets/selected_image.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_palette.dart';

class DashboardNetworkImage extends StatelessWidget {
  const DashboardNetworkImage({super.key, required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return DashboardFallbackAssetImage(height: height);
    }

    return SizedBox(
      height: height.isFinite ? height : null,
      width: double.infinity,
      child: buildSelectedImage(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => DashboardFallbackAssetImage(height: height),
      ),
    );
  }
}

class DashboardFallbackAssetImage extends StatelessWidget {
  const DashboardFallbackAssetImage({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: DashboardPalette.cardAlt,
      alignment: Alignment.center,
      child: const Icon(
        Icons.auto_awesome_outlined,
        color: DashboardPalette.gold,
        size: 32,
      ),
    );
  }
}
