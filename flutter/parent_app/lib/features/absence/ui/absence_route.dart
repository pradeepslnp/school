import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/network/rest_client.dart';
import '../bloc/absence_bloc.dart';
import '../data_provider/absence_data_provider.dart';
import '../repository/absence_repository.dart';
import 'absence_screen.dart';

/// The declare-absence route — P-06.
///
/// Owns this feature's wiring (docs/06-development/PROJECT_STRUCTURE.md). [children] comes
/// from the dashboard, the same way journey history receives it.
class AbsenceRoute extends StatelessWidget {
  const AbsenceRoute({
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
    return RepositoryProvider<AbsenceRepository>(
      create: (_) => AbsenceRepository(
        dataProvider: AbsenceDataProvider(
          client: RestClient(
            baseUrl: apiBaseUrl,
            clientType: 'PARENT_APP',
            accessTokenProvider: accessToken,
            onUnauthorized: onUnauthorized,
          ),
        ),
      ),
      child: Builder(
        builder: (context) => BlocProvider<AbsenceBloc>(
          create: (_) => AbsenceBloc(
            repository: context.read<AbsenceRepository>(),
            children: children,
          )..add(const AbsenceStarted()),
          child: const _AbsenceView(),
        ),
      ),
    );
  }
}

class _AbsenceView extends StatelessWidget {
  const _AbsenceView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AbsenceBloc, AbsenceState>(
      builder: (context, state) {
        final bloc = context.read<AbsenceBloc>();
        return AbsenceScreen(
          state: state,
          onChildSelected: (child) => bloc.add(AbsenceChildSelected(child)),
          onWhenChanged: (when) => bloc.add(AbsenceWhenChanged(when)),
          onDateRangeChanged: (from, to) =>
              bloc.add(AbsenceDateRangeChanged(from: from, to: to)),
          onJourneyChanged: (direction) => bloc.add(AbsenceJourneyChanged(direction)),
          onReasonChanged: (reason) => bloc.add(AbsenceReasonChanged(reason)),
          onSubmit: () => bloc.add(const AbsenceSubmitted()),
          onCancelAbsence: (id) => bloc.add(AbsenceCancelRequested(id)),
        );
      },
    );
  }
}
