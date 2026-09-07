import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
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
        Text(
          _isPickup ? context.l10n.assignRouteTitlePickup : context.l10n.assignRouteTitleDrop,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AdminSpacing.xs),
        Text(
          _isPickup ? context.l10n.assignRoutePickupSubtitle : context.l10n.assignRouteDropSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AdminSpacing.lg),
        DropdownButtonFormField<String>(
          key: const Key('assign_route_field'),
          initialValue: _routeId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.assignRouteFieldLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
          hint: Text(
            widget.routes.isEmpty
                ? context.l10n.assignRouteNoRoutesHint
                : context.l10n.assignRouteSelectRouteHint,
          ),
          items: [
            for (final route in widget.routes)
              DropdownMenuItem(
                value: route.id,
                child: Text(context.l10n.assignRouteNameAndCode(route.name, route.code)),
              ),
          ],
          onChanged: widget.isSubmitting || widget.routes.isEmpty ? null : _onRouteChanged,
        ),
        const SizedBox(height: AdminSpacing.md),
        DropdownButtonFormField<String>(
          key: const Key('assign_stop_field'),
          initialValue: _stopId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.assignStopFieldLabel,
            border: const OutlineInputBorder(),
            constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
          ),
          hint: Text(_stopHint(context)),
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
            context.l10n.assignRouteStopsLoadError,
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
                child: Text(context.l10n.commonCancelButton),
              ),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: FilledButton(
                key: const Key('assign_route_submit_button'),
                onPressed:
                    widget.isSubmitting || _routeId == null || _stopId == null ? null : _submit,
                child: widget.isSubmitting
                    ? OnboardingButtonSpinner(semanticsLabel: context.l10n.assignRouteSavingSpinnerLabel)
                    : Text(context.l10n.commonSaveButton),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _stopHint(BuildContext context) {
    if (_routeId == null) return context.l10n.assignRouteStopHintSelectRouteFirst;
    if (_isLoadingStops) return context.l10n.assignRouteStopHintLoading;
    if (_stops.isEmpty) return context.l10n.assignRouteStopHintNoStops;
    return context.l10n.assignRouteStopHintSelectStop;
  }
}
