import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/config/env.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Renders a small, non-interactive map preview for an event venue or
/// partner address. Degrades gracefully to a placeholder card when
/// [Env.googleMapsApiKey] hasn't been configured for this build, so the
/// app never crashes in environments without a Maps API key.
class LocationMapPreview extends StatelessWidget {
  const LocationMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.label,
    this.height = 160,
  });

  final double latitude;
  final double longitude;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppSpacing.radiusMd);

    if (!Env.hasGoogleMaps) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceLightGray,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, color: AppColors.textDisabled, size: 28),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              Text(
                'Map preview unavailable (no Maps API key configured)',
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: LatLng(latitude, longitude), zoom: 15),
          markers: {
            Marker(markerId: const MarkerId('location'), position: LatLng(latitude, longitude), infoWindow: InfoWindow(title: label)),
          },
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}
