import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/network/rest_client.dart';
import '../bloc/notifications_bloc.dart';
import '../data_provider/notifications_data_provider.dart';
import '../repository/notifications_repository.dart';
import 'notifications_screen.dart';

/// The notification centre route — P-08.
///
/// Owns this feature's wiring (docs/06-development/PROJECT_STRUCTURE.md).
class NotificationsRoute extends StatelessWidget {
  const NotificationsRoute({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
    this.onUnauthorized,
  });

  final String apiBaseUrl;
  final Future<String?> Function() accessToken;
  final Future<void> Function()? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<NotificationsRepository>(
      create: (_) => NotificationsRepository(
        dataProvider: NotificationsDataProvider(
          client: RestClient(
            baseUrl: apiBaseUrl,
            clientType: 'PARENT_APP',
            accessTokenProvider: accessToken,
            onUnauthorized: onUnauthorized,
          ),
        ),
      ),
      child: Builder(
        builder: (context) => BlocProvider<NotificationsBloc>(
          create: (_) => NotificationsBloc(
            repository: context.read<NotificationsRepository>(),
          )..add(const NotificationsStarted()),
          child: const _NotificationsView(),
        ),
      ),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        return NotificationsScreen(
          items: state.items,
          isLoading: state.isLoading,
          loadFailure: state.showsFailureInsteadOfContent
              ? _failureText(state)
              : null,
          onRefresh: () async =>
              context.read<NotificationsBloc>().add(const NotificationsRefreshed()),
          onItemTapped: (id) =>
              context.read<NotificationsBloc>().add(NotificationsItemOpened(id)),
        );
      },
    );
  }

  /// Plain language describing the situation, never a code (docs/05-ui/ACCESSIBILITY.md).
  static String _failureText(NotificationsState state) {
    return switch (state.failure?.code) {
      ErrorCode.dependencyUnavailable =>
        'Your device cannot reach the school right now. '
            'Check your connection and try again.',
      ErrorCode.rateLimitExceeded =>
        'Too many attempts just now. Wait a moment and try again.',
      _ => 'Something went wrong loading your notifications. Please try again.',
    };
  }
}
