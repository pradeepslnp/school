import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/l10n_extensions.dart';
import '../../../core/network/rest_client.dart';
import '../bloc/live_trip_bloc.dart';
import '../data_provider/live_trip_data_provider.dart';
import '../repository/live_trip_repository.dart';
import 'live_trip_screen.dart';

/// The live trip map route — P-04.
///
/// Owns this feature's wiring: data provider → repository → BLoC
/// (docs/06-development/PROJECT_STRUCTURE.md). [vehicleDisplayName] and [stopName] are
/// supplied by the caller — the dashboard or child detail — which already has them from the
/// journey it just rendered; see [LiveTripRepository] for why the trip endpoints themselves
/// do not carry them.
class LiveTripRoute extends StatelessWidget {
  const LiveTripRoute({
    super.key,
    required this.tripId,
    required this.vehicleDisplayName,
    required this.stopName,
    required this.apiBaseUrl,
    required this.accessToken,
    this.onUnauthorized,
  });

  final String tripId;
  final String vehicleDisplayName;
  final String stopName;
  final String apiBaseUrl;
  final Future<String?> Function() accessToken;
  final Future<void> Function()? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<LiveTripRepository>(
      create: (_) => LiveTripRepository(
        dataProvider: LiveTripDataProvider(
          client: RestClient(
            baseUrl: apiBaseUrl,
            clientType: 'PARENT_APP',
            accessTokenProvider: accessToken,
            onUnauthorized: onUnauthorized,
          ),
        ),
      ),
      child: Builder(
        builder: (context) => BlocProvider<LiveTripBloc>(
          create: (_) => LiveTripBloc(
            repository: context.read<LiveTripRepository>(),
            tripId: tripId,
            vehicleDisplayName: vehicleDisplayName,
            stopName: stopName,
          )..add(const LiveTripStarted()),
          child: const _LiveTripView(),
        ),
      ),
    );
  }
}

class _LiveTripView extends StatelessWidget {
  const _LiveTripView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveTripBloc, LiveTripState>(
      builder: (context, state) {
        return LiveTripScreen(
          trip: state.trip,
          isLoading: state.isLoading,
          isOutsideTrip: state.isOutsideTrip,
          loadFailure: state.showsFailureInsteadOfContent && !state.isOutsideTrip
              ? _failureText(context, state)
              : null,
          onRefresh: () async =>
              context.read<LiveTripBloc>().add(const LiveTripRefreshed()),
        );
      },
    );
  }

  /// Plain language describing the situation, never a code (docs/05-ui/ACCESSIBILITY.md).
  ///
  /// [LiveTripState.isOutsideTrip] is handled separately by the screen (BR-TRACK-001) — this
  /// only covers genuine failures, so [ErrorCode.trackingNotAvailableOutsideTrip] never
  /// reaches this switch in practice.
  static String _failureText(BuildContext context, LiveTripState state) {
    final l10n = context.l10n;
    return switch (state.failure?.code) {
      ErrorCode.dependencyUnavailable => l10n.errorDependencyUnavailable,
      ErrorCode.rateLimitExceeded => l10n.errorRateLimited,
      _ => l10n.liveTripGenericFailure,
    };
  }
}
