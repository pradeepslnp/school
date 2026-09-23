import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/domain.dart';
import '../../../l10n/l10n_extensions.dart';
import '../bloc/duty_bloc.dart';
import '../bloc/duty_event.dart';
import '../bloc/duty_state.dart';
import '../widgets/trip_card.dart';

/// The crew's day — the screen the driver app opens onto (TRP-004).
///
/// Replaces the placeholder that used to say "No trip loaded" and made no request at all.
class DutyBody extends StatefulWidget {
  const DutyBody({super.key});

  @override
  State<DutyBody> createState() => _DutyBodyState();
}

class _DutyBodyState extends State<DutyBody> {
  @override
  void initState() {
    super.initState();
    context.read<DutyBloc>().add(const DutyRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DutyBloc, DutyState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async => context.read<DutyBloc>().add(const DutyRequested()),
          child: ListView(
            padding: const EdgeInsets.all(DriverSpacing.md),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (state.error != null) _ErrorPanel(state: state),
              if (state.isEmpty && state.error == null) const _NoRunsPanel(),
              for (final trip in state.trips)
                TripCard(
                  trip: trip,
                  isSubmitting: state.submittingTripId == trip.id,
                  onStart: (vehicleId) => context
                      .read<DutyBloc>()
                      .add(TripStartRequested(tripId: trip.id, vehicleId: vehicleId)),
                  onEnd: () =>
                      context.read<DutyBloc>().add(TripEndRequested(tripId: trip.id)),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Why a refusal happened, in the crew's own terms.
///
/// The eligibility codes get their own sentences deliberately: ERROR_CATALOG.md's whole reason
/// for having four staff codes and two vehicle codes is that "cannot start" at 06:30 is not
/// actionable, and collapsing them back into one message here would throw that away.
class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.state});

  final DutyState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final message = switch (state.error) {
      ErrorCode.tripNotAuthorisedActor => l10n.dutyErrorNotCrew,
      ErrorCode.tripInvalidStatusTransition => l10n.dutyErrorAlreadyChanged,
      ErrorCode.tripManifestEmpty => l10n.dutyErrorManifestEmpty,
      ErrorCode.tripVehicleOnAnotherTrip => l10n.dutyErrorVehicleBusy,
      ErrorCode.staffAlreadyOnActiveTrip => l10n.dutyErrorCrewBusy,
      ErrorCode.vehicleDocumentExpired => l10n.dutyErrorVehicleDocumentExpired,
      ErrorCode.vehicleNotActive => l10n.dutyErrorVehicleNotActive,
      ErrorCode.staffLicenceExpired => l10n.dutyErrorLicenceExpired,
      ErrorCode.staffLicenceClassInvalid => l10n.dutyErrorLicenceClass,
      ErrorCode.staffNotVerified => l10n.dutyErrorNotVerified,
      ErrorCode.staffVerificationLapsed => l10n.dutyErrorVerificationLapsed,
      ErrorCode.dependencyUnavailable => l10n.dutyErrorOffline,
      _ => l10n.dutyErrorGeneric,
    };

    return Card(
      color: theme.colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: DriverSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(DriverSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: DriverSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the request succeeded and there is genuinely nothing on today.
///
/// It lists what has to be true, because every one of those links is invisible from a handset
/// and an empty screen with no explanation sends a driver to the office to ask. This is the one
/// place in the app where naming the set-up chain is worth the words.
class _NoRunsPanel extends StatelessWidget {
  const _NoRunsPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DriverSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 56, color: theme.colorScheme.outline),
          const SizedBox(height: DriverSpacing.md),
          Text(
            l10n.dutyNoRunsTitle,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DriverSpacing.sm),
          Text(
            l10n.dutyNoRunsExplanation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
