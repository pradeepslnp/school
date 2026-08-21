import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/network/rest_client.dart';
import '../bloc/handover_bloc.dart';
import '../data_provider/handover_data_provider.dart';
import '../repository/handover_repository.dart';
import 'handover_screen.dart';

/// The handover verification route — P-12.
///
/// Owns this feature's wiring (docs/06-development/PROJECT_STRUCTURE.md). [children] comes
/// from the dashboard, the same way absence and journey history receive it.
class HandoverRoute extends StatelessWidget {
  const HandoverRoute({
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
    return RepositoryProvider<HandoverRepository>(
      create: (_) => HandoverRepository(
        dataProvider: HandoverDataProvider(
          client: RestClient(
            baseUrl: apiBaseUrl,
            clientType: 'PARENT_APP',
            accessTokenProvider: accessToken,
            onUnauthorized: onUnauthorized,
          ),
        ),
      ),
      child: Builder(
        builder: (context) => BlocProvider<HandoverBloc>(
          create: (_) => HandoverBloc(
            repository: context.read<HandoverRepository>(),
            children: children,
          )..add(const HandoverStarted()),
          child: const _HandoverView(),
        ),
      ),
    );
  }
}

class _HandoverView extends StatelessWidget {
  const _HandoverView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HandoverBloc, HandoverState>(
      builder: (context, state) {
        final bloc = context.read<HandoverBloc>();
        return HandoverScreen(
          state: state,
          onChildSelected: (child) => bloc.add(HandoverChildSelected(child)),
          onRequestNewCode: () => bloc.add(const HandoverCodeRequested()),
        );
      },
    );
  }
}
