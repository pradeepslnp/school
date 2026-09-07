import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/l10n_extensions.dart';
import '../../../core/network/rest_client.dart';
import '../../handover/ui/handover_route.dart';
import '../bloc/child_detail_bloc.dart';
import '../data_provider/child_detail_data_provider.dart';
import '../repository/child_detail_repository.dart';
import 'child_detail_screen.dart';

/// The child detail route — P-03.
///
/// Owns this feature's wiring, the same shape as the dashboard's `HomeRoute`: data provider
/// → repository → BLoC, assembled here rather than in a global container so the objects
/// live and die with the route (docs/06-development/PROJECT_STRUCTURE.md).
class ChildDetailRoute extends StatelessWidget {
  const ChildDetailRoute({
    super.key,
    required this.studentId,
    required this.displayName,
    required this.apiBaseUrl,
    required this.accessToken,
    this.onUnauthorized,
    this.onTrack,
  });

  final String studentId;
  final String displayName;
  final String apiBaseUrl;
  final Future<String?> Function() accessToken;
  final Future<void> Function()? onUnauthorized;

  /// Invoked with the active trip id when the parent asks to track this child. Supplied by
  /// the caller because navigation to P-04 is a routing decision, not this feature's
  /// concern.
  final void Function(String tripId)? onTrack;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ChildDetailRepository>(
      create: (_) => ChildDetailRepository(
        dataProvider: ChildDetailDataProvider(
          client: RestClient(
            baseUrl: apiBaseUrl,
            clientType: 'PARENT_APP',
            accessTokenProvider: accessToken,
            onUnauthorized: onUnauthorized,
          ),
        ),
      ),
      child: Builder(
        builder: (context) => BlocProvider<ChildDetailBloc>(
          create: (_) => ChildDetailBloc(
            repository: context.read<ChildDetailRepository>(),
            studentId: studentId,
          )..add(const ChildDetailStarted()),
          child: _ChildDetailView(
            studentId: studentId,
            displayName: displayName,
            apiBaseUrl: apiBaseUrl,
            accessToken: accessToken,
            onUnauthorized: onUnauthorized,
            onTrack: onTrack,
          ),
        ),
      ),
    );
  }
}

class _ChildDetailView extends StatelessWidget {
  const _ChildDetailView({
    required this.studentId,
    required this.displayName,
    required this.apiBaseUrl,
    required this.accessToken,
    this.onUnauthorized,
    this.onTrack,
  });

  final String studentId;
  final String displayName;
  final String apiBaseUrl;
  final Future<String?> Function() accessToken;
  final Future<void> Function()? onUnauthorized;
  final void Function(String tripId)? onTrack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChildDetailBloc, ChildDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        final tripId = detail?.tripId;
        final canTrack = (detail?.canTrack ?? false) && tripId != null;
        final resolvedName = detail?.displayName ?? displayName;

        return ChildDetailScreen(
          displayName: resolvedName,
          detail: detail,
          isLoading: state.isLoading,
          loadFailure: state.showsFailureInsteadOfContent
              ? _failureText(context, state)
              : null,
          onRefresh: () async =>
              context.read<ChildDetailBloc>().add(const ChildDetailRefreshed()),
          onTrack: canTrack && onTrack != null ? () => onTrack!(tripId) : null,
          onShowPickupCode: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HandoverRoute(
                children: [ChildOption(studentId: studentId, displayName: resolvedName)],
                apiBaseUrl: apiBaseUrl,
                accessToken: accessToken,
                onUnauthorized: onUnauthorized,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Plain language describing the situation, never a code (docs/05-ui/ACCESSIBILITY.md).
  static String _failureText(BuildContext context, ChildDetailState state) {
    final l10n = context.l10n;
    return switch (state.failure?.code) {
      // The server refuses a child this account is not linked to. Phrased as a school-office
      // matter rather than an error, because for a parent it is one — a link that was removed,
      // or a child moved between guardians.
      ErrorCode.authScopeDenied => l10n.childDetailScopeDenied,
      ErrorCode.dependencyUnavailable => l10n.errorDependencyUnavailable,
      _ => l10n.childDetailGenericFailure,
    };
  }
}
