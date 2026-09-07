import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/l10n_extensions.dart';
import '../../../core/network/rest_client.dart';
import '../bloc/journey_history_bloc.dart';
import '../data_provider/journey_history_data_provider.dart';
import '../repository/journey_history_repository.dart';
import 'journey_history_screen.dart';

/// The journey history route — P-05.
///
/// Owns this feature's wiring (docs/06-development/PROJECT_STRUCTURE.md). [children] comes
/// from the dashboard, which already knows every child the guardian may see — this feature
/// does not re-derive that scope, only which one of them is currently selected.
class JourneyHistoryRoute extends StatelessWidget {
  const JourneyHistoryRoute({
    super.key,
    required this.children,
    required this.apiBaseUrl,
    required this.accessToken,
    this.onUnauthorized,
  });

  final List<ChildOption> children;
  final String apiBaseUrl;
  final Future<String?> Function() accessToken;
  final Future<void> Function()? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<JourneyHistoryRepository>(
      create: (_) => JourneyHistoryRepository(
        dataProvider: JourneyHistoryDataProvider(
          client: RestClient(
            baseUrl: apiBaseUrl,
            clientType: 'PARENT_APP',
            accessTokenProvider: accessToken,
            onUnauthorized: onUnauthorized,
          ),
        ),
      ),
      child: Builder(
        builder: (context) => BlocProvider<JourneyHistoryBloc>(
          create: (_) => JourneyHistoryBloc(
            repository: context.read<JourneyHistoryRepository>(),
            children: children,
          )..add(const JourneyHistoryStarted()),
          child: const _JourneyHistoryView(),
        ),
      ),
    );
  }
}

class _JourneyHistoryView extends StatelessWidget {
  const _JourneyHistoryView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JourneyHistoryBloc, JourneyHistoryState>(
      builder: (context, state) {
        return JourneyHistoryScreen(
          children: state.children,
          selected: state.selected,
          entries: state.entries,
          isLoading: state.isLoading,
          loadFailure: state.showsFailureInsteadOfContent
              ? _failureText(context, state)
              : null,
          onRefresh: () async =>
              context.read<JourneyHistoryBloc>().add(const JourneyHistoryRefreshed()),
          onChildSelected: (child) =>
              context.read<JourneyHistoryBloc>().add(JourneyHistoryChildSelected(child)),
        );
      },
    );
  }

  /// Plain language describing the situation, never a code (docs/05-ui/ACCESSIBILITY.md).
  static String _failureText(BuildContext context, JourneyHistoryState state) {
    final l10n = context.l10n;
    return switch (state.failure?.code) {
      // The server refuses a child this account is not linked to. Phrased as a school-office
      // matter rather than an error, the same as child detail's handling of the same code.
      ErrorCode.authScopeDenied => l10n.journeyHistoryScopeDenied,
      ErrorCode.dependencyUnavailable => l10n.errorDependencyUnavailable,
      ErrorCode.rateLimitExceeded => l10n.errorRateLimited,
      _ => l10n.journeyHistoryGenericFailure,
    };
  }
}
