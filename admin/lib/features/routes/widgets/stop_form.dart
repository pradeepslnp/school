import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../domain/stop_models.dart';

/// Adds one stop to a route (RTE-001).
///
/// A coordinate-and-details form, not a map: the map editor (A-31) does not exist yet, so an
/// operator enters latitude/longitude directly — the smallest correct thing that lets a route
/// carry students today, and what the map editor will later replace.
///
/// The geofence radius is bounded 20–500 m (BR-ROUTE-003): too small and GPS drift means arrival
/// is never detected; too large and stops overlap. The field defaults to 50 m and is validated
/// here as well as by the server.
class StopForm extends StatefulWidget {
  const StopForm({super.key, required this.onAdd, required this.onCancel});

  /// Called with a stop whose [RouteStop.sequenceNo] is a placeholder — the editor renumbers the
  /// whole list on save, so a single stop does not decide its own position.
  final ValueChanged<RouteStop> onAdd;
  final VoidCallback onCancel;

  @override
  State<StopForm> createState() => _StopFormState();
}

class _StopFormState extends State<StopForm> {
  final _name = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _geofence = TextEditingController(text: '50');
  final _pickupTime = TextEditingController();
  final _dropTime = TextEditingController();
  final _landmark = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _geofence.dispose();
    _pickupTime.dispose();
    _dropTime.dispose();
    _landmark.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final lat = double.tryParse(_latitude.text.trim());
    final lng = double.tryParse(_longitude.text.trim());
    final geofence = int.tryParse(_geofence.text.trim());

    if (name.isEmpty) {
      setState(() => _error = context.l10n.stopFormErrorNameRequired);
      return;
    }
    if (lat == null || lat < -90 || lat > 90) {
      setState(() => _error = context.l10n.stopFormErrorLatitudeRange);
      return;
    }
    if (lng == null || lng < -180 || lng > 180) {
      setState(() => _error = context.l10n.stopFormErrorLongitudeRange);
      return;
    }
    if (geofence == null || geofence < 20 || geofence > 500) {
      setState(() => _error = context.l10n.stopFormErrorGeofenceRange);
      return;
    }
    if (!_timeIsValid(_pickupTime.text) || !_timeIsValid(_dropTime.text)) {
      setState(() => _error = context.l10n.stopFormErrorTimeFormat);
      return;
    }

    widget.onAdd(
      RouteStop(
        sequenceNo: 0,
        name: name,
        latitude: lat,
        longitude: lng,
        geofenceRadiusM: geofence,
        scheduledPickupTime: _blankToNull(_pickupTime.text),
        scheduledDropTime: _blankToNull(_dropTime.text),
        landmark: _blankToNull(_landmark.text),
      ),
    );
  }

  static bool _timeIsValid(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return true;
    final match = RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$').firstMatch(value);
    return match != null;
  }

  static String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.routeStopsAddButton, style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.lg),
        TextField(
          key: const Key('stop_form_name_field'),
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.stopFormNameLabel,
            hintText: context.l10n.stopFormNameHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('stop_form_latitude_field'),
                controller: _latitude,
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                decoration: InputDecoration(
                  labelText: context.l10n.schoolFieldLatitudeLabel,
                  hintText: context.l10n.stopFormLatitudeHint,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: TextField(
                key: const Key('stop_form_longitude_field'),
                controller: _longitude,
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                decoration: InputDecoration(
                  labelText: context.l10n.schoolFieldLongitudeLabel,
                  hintText: context.l10n.stopFormLongitudeHint,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('stop_form_geofence_field'),
          controller: _geofence,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.stopFormGeofenceLabel,
            hintText: context.l10n.stopFormGeofenceHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('stop_form_pickup_time_field'),
                controller: _pickupTime,
                decoration: InputDecoration(
                  labelText: context.l10n.stopFormPickupTimeLabel,
                  hintText: context.l10n.stopFormTimeHint,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: TextField(
                key: const Key('stop_form_drop_time_field'),
                controller: _dropTime,
                decoration: InputDecoration(
                  labelText: context.l10n.stopFormDropTimeLabel,
                  hintText: context.l10n.stopFormTimeHint,
                  border: const OutlineInputBorder(),
                  constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.md),
        TextField(
          key: const Key('stop_form_landmark_field'),
          controller: _landmark,
          decoration: InputDecoration(
            labelText: context.l10n.stopFormLandmarkLabel,
            hintText: context.l10n.stopFormLandmarkHint,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AdminSpacing.md),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(color: context.status.critical),
          ),
        ],
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('stop_form_cancel_button'),
                onPressed: widget.onCancel,
                child: Text(context.l10n.commonCancelButton),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('stop_form_add_button'),
                onPressed: _submit,
                child: Text(context.l10n.routeStopsAddButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
