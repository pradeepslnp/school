import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';
import '../../../core/l10n_extensions.dart';

/// P-04's vehicle marker map (docs/05-ui/PARENT_APP.md).
///
/// Renders only what `GET /trips/{id}/position` documents for a guardian's
/// `PERM-TRACKING-LIVE-VIEW` scope (docs/04-api/TRACKING_NOTIFICATION_API.md): the vehicle's
/// position and heading. **No stop marker, no route polyline** — PARENT_APP.md's P-04
/// describes both, but neither's coordinates are available to a guardian; only
/// `PERM-ROUTE-VIEW` (`GET /routes/{id}/stops`, fleet/staff) carries them. See the note on
/// `LiveTrip.latitude` and the gap flagged in TRACKING_NOTIFICATION_API.md — closing it is a
/// backend change, not a client one.
///
/// The text summary above this widget already carries the full answer
/// ("Bus 12 · 3 stops away · ~7 min to Green Park"), independent of whether the map renders
/// tiles — a Maps API key must be supplied at build time per platform, never committed
/// (docs/06-development/LOCAL_SETUP.md), so a build without one still shows a correct,
/// complete screen with an unstyled map underneath (docs/05-ui/ACCESSIBILITY.md).
class VehicleMapSurface extends StatefulWidget {
  const VehicleMapSurface({
    super.key,
    required this.latitude,
    required this.longitude,
    this.headingDeg,
  });

  final double? latitude;
  final double? longitude;

  /// Compass heading of travel, degrees. Null reads as "unknown" and the marker points north.
  final double? headingDeg;

  @override
  State<VehicleMapSurface> createState() => _VehicleMapSurfaceState();
}

class _VehicleMapSurfaceState extends State<VehicleMapSurface> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _vehicleIcon;
  Color? _iconFill;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fill = context.colors.primary;
    // Regenerated only when the fill would actually change (a theme/brightness switch) —
    // rasterising on every rebuild would be wasted work for a marker that never moves colour
    // between frames.
    if (fill == _iconFill) return;
    _iconFill = fill;
    final border = context.colors.onPrimary;
    unawaited(
      _headingMarkerIcon(fill: fill, border: border).then((icon) {
        if (mounted) setState(() => _vehicleIcon = icon);
      }),
    );
  }

  @override
  void didUpdateWidget(covariant VehicleMapSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lat = widget.latitude;
    final lon = widget.longitude;
    if (lat == null || lon == null) return;
    if (lat == oldWidget.latitude && lon == oldWidget.longitude) return;
    final controller = _mapController;
    if (controller != null) {
      unawaited(controller.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lon))));
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.latitude;
    final lon = widget.longitude;

    return Semantics(
      // The summary above already states this as text; a screen reader gains nothing from
      // stepping through map tiles and a marker it cannot meaningfully describe further.
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GuardianRadius.lg),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHigh,
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: (lat == null || lon == null)
                ? _NoPositionYet(label: context.l10n.mapViewLabel)
                : GoogleMap(
                    initialCameraPosition: CameraPosition(target: LatLng(lat, lon), zoom: 16),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: _vehicleIcon == null
                        ? const {}
                        : {
                            Marker(
                              markerId: const MarkerId('vehicle'),
                              position: LatLng(lat, lon),
                              icon: _vehicleIcon!,
                              anchor: const Offset(0.5, 0.5),
                              rotation: widget.headingDeg ?? 0,
                              flat: true,
                              // The text summary already names the bus; repeating it in an
                              // info window is a tap that adds nothing.
                              infoWindow: InfoWindow.noText,
                            ),
                          },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                  ),
          ),
        ),
      ),
    );
  }

  /// A directional pointer rather than a generic pin — the marker must read as "facing this
  /// way" at a glance (PARENT_APP.md P-04: "vehicle marker with heading"). Drawn once per
  /// fill colour and cached, not shipped as an asset: it needs no art, and it always matches
  /// the active theme's primary colour exactly.
  static Future<BitmapDescriptor> _headingMarkerIcon({
    required Color fill,
    required Color border,
  }) async {
    const canvasSize = 120.0;
    const displaySize = 36.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, canvasSize, canvasSize));
    const center = Offset(canvasSize / 2, canvasSize / 2);

    // Points "up" (north) by default; GoogleMap rotates the drawn bitmap to `rotation`
    // degrees at render time via the marker's `flat: true`.
    final path = Path()
      ..moveTo(center.dx, center.dy - canvasSize * 0.4)
      ..lineTo(center.dx + canvasSize * 0.28, center.dy + canvasSize * 0.32)
      ..lineTo(center.dx, center.dy + canvasSize * 0.16)
      ..lineTo(center.dx - canvasSize * 0.28, center.dy + canvasSize * 0.32)
      ..close();

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = canvasSize * 0.06,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: displaySize,
      height: displaySize,
    );
  }
}

/// Shown before the first position arrives, or if a position ever comes back without
/// coordinates — an honest "nothing to draw yet", not a blank map.
class _NoPositionYet extends StatelessWidget {
  const _NoPositionYet({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.navigation,
            size: AppSizeConstants.iconXl,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: GuardianSpacing.sm),
          Text(
            label,
            style: context.texts.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

