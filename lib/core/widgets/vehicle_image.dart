import 'dart:convert';
import 'package:flutter/material.dart';

/// Displays a vehicle image whether it's stored as an HTTPS URL
/// or a base64 data URL (data:image/jpeg;base64,...).
class VehicleImage extends StatelessWidget {
  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const VehicleImage({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = errorWidget ??
        Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          child: Icon(Icons.directions_car, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.54)),
        );

    if (src.startsWith('data:image')) {
      try {
        final base64Str = src.substring(src.indexOf(',') + 1);
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }

    return Image.network(
      src,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
