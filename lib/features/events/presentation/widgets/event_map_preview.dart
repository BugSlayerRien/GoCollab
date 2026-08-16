import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

/// Small map preview for an event venue or partner address.
///
/// In-app tiles come from OpenStreetMap (no API key). Tapping the map opens
/// the same coordinates in Google Maps / the system browser.
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

  Uri get _externalMapsUri => Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );

  Future<void> _openExternally() async {
    await launchUrl(_externalMapsUri, mode: LaunchMode.externalApplication);
  }

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
                onTap: (_, __) => _openExternally(),
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
        Row(
          children: [
            Expanded(
              child: Text(
                '$label · © OpenStreetMap',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.appTextSecondary),
              ),
            ),
            TextButton(
              onPressed: _openExternally,
              child: const Text('Open in Maps'),
            ),
          ],
        ),
      ],
    );
  }
}
