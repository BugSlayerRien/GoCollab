import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

/// Small map preview for an event venue or partner address.
///
/// Uses OpenStreetMap tiles (no Google Cloud billing or Maps API key).
/// Tapping the map opens the location in the browser.
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

  Uri get _openStreetMapUri => Uri.parse(
        'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=16/$latitude/$longitude',
      );

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppSpacing.radiusMd);
    final point = LatLng(latitude, longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: borderRadius,
          child: SizedBox(
            height: height,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                onTap: (_, __) => launchUrl(_openStreetMapUri, mode: LaunchMode.externalApplication),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ph.gdgoc.gocollab.gocollab',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on_rounded, color: AppColors.googleRed, size: 36),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$label · © OpenStreetMap',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.appTextSecondary),
        ),
      ],
    );
  }
}
