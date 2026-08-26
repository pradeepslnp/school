import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../organizations/widgets/onboarding_button_spinner.dart';
import '../../routes/domain/route_models.dart';
import '../../routes/domain/stop_models.dart';

/// Sets a student's pickup or drop — pick a route, then a stop on it (RTE-003, A-11).
///
/// The direction is fixed by the panel that opened this (the operator pressed "Set pickup" or
/// "Set drop"), so the form only decides *where*. The stop dropdown is empty until a route is
/// chosen, then fetched for that route — a stop has no meaning apart from its route, and a route
/// with no stops cannot carry a student yet (add them from the Routes screen first).
class AssignRouteForm extends StatefulWidget {
  const AssignRouteForm({
    super.key,
    required this.direction,
    required this.routes,
    required this.loadStops,
    required this.onSubmit,
    required this.onCancel,
    this.isSubmitting = false,
  });

  /// `PICKUP` or `DROP` — decided by the caller, shown in the title.
  final String direction;
  final List<CreatedRoute> routes;
  final Future<List<RouteStop>> Function(String routeId) loadStops;

  final void Function({required String routeId, required String stopId}) onSubmit;
  final VoidCallback onCancel;
  final bool isSubmitting;

  @override
  State<AssignRouteForm> createState() => _AssignRouteFormState();
}

class _AssignRouteFormState extends State<AssignRouteForm> {
  String? _routeId;
  String? _stopId;
  List<RouteStop> _stops = const [];
  bool _isLoadingStops = false;
  bool _stopsFailed = false;

  bool get _isPickup => widget.direction == 'PICKUP';

  Future<void> _onRouteChanged(String? routeId) async {
    if (routeId == null) return;
    setState(() {
      _routeId = routeId;
      _stopId = null;
      _stops = const [];
      _isLoadingStops = true;
      _stopsFailed = false;
    });
    try {
      final stops = await widget.loadStops(routeId);
      if (!mounted) return;
      setState(() {
        _stops = stops;
        _isLoadingStops = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingStops = false;
        _stopsFailed = true;
      });
    }
  }

  void _submit() {
    if (widget.isSubmitting) return;
    final routeId = _routeId;
    final stopId = _stopId;
    if (routeId == null || stopId == null) return;
    widget.onSubmit(routeId: routeId, stopId: stopId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_isPickup ? 'Set pickup' : 'Set drop', style: theme.textTheme.titleLarge),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          _isPickup
              ? 'Where this child is picked up in the morning.'
              : 'Where this child is dropped in the afternoon.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        DropdownButtonFormField<String>(
          key: const Key('assign_route_field'),
          initialValue: _routeId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Route',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
          hint: Text(widget.routes.isEmpty ? 'No routes on this school yet' : 'Select a route'),
          items: [
            for (final route in widget.routes)
              DropdownMenuItem(value: route.id, child: Text('${route.name} · ${route.code}')),
          ],
          onChanged: widget.isSubmitting || widget.routes.isEmpty ? null : _onRouteChanged,
        ),
        const SizedBox(height: AdminSpacing.md),
        DropdownButtonFormField<String>(
          key: const Key('assign_stop_field'),
          initialValue: _stopId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Stop',
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: kAdminTouchTarget),
          ),
          hint: Text(_stopHint()),
          items: [
            for (final stop in _stops)
              DropdownMenuItem(value: stop.id, child: Text(stop.name)),
          ],
          onChanged: widget.isSubmitting || _stops.isEmpty
              ? null
              : (value) => setState(() => _stopId = value),
        ),
        if (_stopsFailed) ...[
          const SizedBox(height: AdminSpacing.sm),
          Text(
            'Could not load this route\'s stops. Try again.',
            style: theme.textTheme.bodySmall?.copyWith(color: context.status.critical),
          ),
        ],
        const SizedBox(height: AdminSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('assign_route_cancel_button'),
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('assign_route_submit_button'),
                onPressed:
                    widget.isSubmitting || _routeId == null || _stopId == null ? null : _submit,
                child: widget.isSubmitting
                    ? const OnboardingButtonSpinner(semanticsLabel: 'Saving')
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _stopHint() {
    if (_routeId == null) return 'Select a route first';
    if (_isLoadingStops) return 'Loading stops…';
    if (_stops.isEmpty) return 'This route has no stops yet';
    return 'Select a stop';
  }
}
