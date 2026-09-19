import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../domain/student_transport_models.dart';

/// The bus and crew under one direction of the student record's pickup-and-drop panel (A-11,
/// STU-009): "Bus 12 (DL1PC1234) · Driver Suresh Kumar · Attendant Ravi".
///
/// Worded as an assignment, never as a location. It is the route's usual bus and today's duty
/// crew; where the child actually is comes from boarding records once trips run.
///
/// A gap is shown, not hidden: a route with no bus, a bus that is not in service, or nobody on
/// duty is exactly what the office needs to notice before the morning run.
class AssignedBusLine extends StatelessWidget {
  const AssignedBusLine({super.key, required this.leg});

  final TransportLeg leg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final warning = theme.textTheme.bodySmall?.copyWith(color: context.status.warning);

    final vehicle = leg.vehicle;
    final drivers = leg.drivers;
    final attendants = leg.attendants;

    return Padding(
      padding: const EdgeInsets.only(top: AdminSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line(
            icon: Icons.directions_bus_outlined,
            // Icon as well as colour for a gap — colour is never the only signal.
            warn: vehicle == null || !vehicle.isActive,
            text: switch (vehicle) {
              null => l10n.studentTransportNoBus,
              final bus when !bus.isActive => l10n.studentTransportBusNotInService(
                bus.displayName,
                bus.registrationNo,
              ),
              final bus => l10n.studentTransportBus(bus.displayName, bus.registrationNo),
            },
            style: vehicle == null || !vehicle.isActive ? warning : muted,
          ),
          _Line(
            icon: Icons.badge_outlined,
            warn: drivers.isEmpty,
            text: drivers.isEmpty
                ? l10n.studentTransportNoDriver
                : l10n.studentTransportDriver(_names(drivers)),
            style: drivers.isEmpty ? warning : muted,
          ),
          _Line(
            icon: Icons.support_agent_outlined,
            // Not a warning: whether an attendant is required is tenant configuration
            // (BR-STAFF-005), and this panel does not know that setting.
            warn: false,
            text: attendants.isEmpty
                ? l10n.studentTransportNoAttendant
                : l10n.studentTransportAttendant(_names(attendants)),
            style: muted,
          ),
        ],
      ),
    );
  }

  static String _names(List<TransportCrewMember> crew) =>
      crew.map((member) => member.displayName).join(', ');
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, required this.style, required this.warn});

  final IconData icon;
  final String text;
  final TextStyle? style;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warn ? Icons.warning_amber_rounded : icon, size: 16, color: style?.color),
          const SizedBox(width: AdminSpacing.xs),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
