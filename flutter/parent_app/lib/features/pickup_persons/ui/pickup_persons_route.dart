import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/network/rest_client.dart';
import '../bloc/pickup_persons_bloc.dart';
import '../data_provider/pickup_persons_data_provider.dart';
import '../repository/pickup_persons_repository.dart';
import 'pickup_persons_screen.dart';

/// The pickup-persons route — P-07.
///
/// Owns this feature's wiring (docs/06-development/PROJECT_STRUCTURE.md). [children] comes
/// from the dashboard, the same way journey history and declare absence receive it.
class PickupPersonsRoute extends StatelessWidget {
  const PickupPersonsRoute({
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
    return RepositoryProvider<PickupPersonsRepository>(
      create: (_) => PickupPersonsRepository(
        dataProvider: PickupPersonsDataProvider(
          client: RestClient(
            baseUrl: apiBaseUrl,
            clientType: 'PARENT_APP',
            accessTokenProvider: accessToken,
            onUnauthorized: onUnauthorized,
          ),
        ),
      ),
      child: Builder(
        builder: (context) => BlocProvider<PickupPersonsBloc>(
          create: (_) => PickupPersonsBloc(
            repository: context.read<PickupPersonsRepository>(),
            children: children,
          )..add(const PickupPersonsStarted()),
          child: const _PickupPersonsView(),
        ),
      ),
    );
  }
}

class _PickupPersonsView extends StatelessWidget {
  const _PickupPersonsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PickupPersonsBloc, PickupPersonsState>(
      builder: (context, state) {
        final bloc = context.read<PickupPersonsBloc>();
        return PickupPersonsScreen(
          state: state,
          onChildSelected: (child) => bloc.add(PickupPersonsChildSelected(child)),
          onAddFormToggled: (show) => bloc.add(PickupPersonsAddFormToggled(show)),
          onFullNameChanged: (value) => bloc.add(PickupPersonsFullNameChanged(value)),
          onPhoneChanged: (value) => bloc.add(PickupPersonsPhoneChanged(value)),
          onRelationshipChanged: (value) =>
              bloc.add(PickupPersonsRelationshipChanged(value)),
          onValidityChanged: (from, until) =>
              bloc.add(PickupPersonsValidityChanged(from: from, until: until)),
          onSubmit: () => bloc.add(const PickupPersonsSubmitted()),
          onRevoke: (id) => bloc.add(PickupPersonsRevokeRequested(id)),
        );
      },
    );
  }
}
