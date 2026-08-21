import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain.dart';
import '../../../core/network/rest_client.dart';
import '../../absence/ui/absence_route.dart';
import '../../child_detail/ui/child_detail_route.dart';
import '../../handover/ui/handover_route.dart';
import '../../journey_history/ui/journey_history_route.dart';
import '../../live_trip/ui/live_trip_route.dart';
import '../../notifications/ui/notifications_route.dart';
import '../../pickup_persons/ui/pickup_persons_route.dart';
import '../bloc/home_bloc.dart';
import '../data_provider/home_data_provider.dart';
import '../repository/home_repository.dart';
import '../repository/models/child_status.dart';
import 'home_screen.dart';

/// The dashboard route.
///
/// Owns the feature's wiring — data provider → repository → BLoC — so no other feature
/// needs to know how the dashboard is assembled. Composition happens here rather than in a
/// global container: the objects live and die with the route.
///
/// It also owns navigation to every screen the dashboard opens (P-03 through P-08): the
/// dashboard is the one place that already holds the guardian's session and full child list,
/// so it is the natural place to assemble each destination route rather than threading that
/// context through the app's root.
class HomeRoute extends StatelessWidget {
  const HomeRoute({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
    required this.guardianName,
    this.onUnauthorized,
  });

  final String apiBaseUrl;

  /// Supplied per request rather than held by the client, so a rotated token is picked up
  /// without rebuilding the transport (ADR-0006).
  final Future<String?> Function() accessToken;

  final String guardianName;

  /// Invoked when the server rejects the token, so the app can re-authenticate.
  final Future<void> Function()? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<HomeRepository>(
      create: (_) => HomeRepository(
        dataProvider: HomeDataProvider(
          client: RestClient(
            baseUrl: apiBaseUrl,
            clientType: 'PARENT_APP',
            accessTokenProvider: accessToken,
            onUnauthorized: onUnauthorized,
          ),
        ),
      ),
      child: Builder(
        builder: (context) => BlocProvider<HomeBloc>(
          create: (_) =>
              HomeBloc(repository: context.read<HomeRepository>())
                ..add(const HomeStarted()),
          child: _HomeShell(
            guardianName: guardianName,
            apiBaseUrl: apiBaseUrl,
            accessToken: accessToken,
            onUnauthorized: onUnauthorized,
          ),
        ),
      ),
    );
  }
}

/// The persistent bottom-tab shell: Home, Journeys, Alerts, Pickup.
///
/// Only Home is eager. The other three are full features with their own repository, BLoC,
/// and network call on start — mounting all four the moment the dashboard loads would fire
/// three requests for screens the guardian may never open this session. Each tab mounts (and
/// stays mounted, preserving its state) the first time it is selected.
class _HomeShell extends StatefulWidget {
  const _HomeShell({
    required this.guardianName,
    required this.apiBaseUrl,
    required this.accessToken,
    this.onUnauthorized,
  });

  final String guardianName;
  final String apiBaseUrl;
  final Future<String?> Function() accessToken;
  final Future<void> Function()? onUnauthorized;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;
  final Set<int> _visited = {0};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final children = _childOptions(state.children);

        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              HomeView(
                guardianName: widget.guardianName,
                apiBaseUrl: widget.apiBaseUrl,
                accessToken: widget.accessToken,
                onUnauthorized: widget.onUnauthorized,
              ),
              _visited.contains(1)
                  ? JourneyHistoryRoute(
                      children: children,
                      apiBaseUrl: widget.apiBaseUrl,
                      accessToken: widget.accessToken,
                      onUnauthorized: widget.onUnauthorized,
                    )
                  : const SizedBox.shrink(),
              _visited.contains(2)
                  ? NotificationsRoute(
                      apiBaseUrl: widget.apiBaseUrl,
                      accessToken: widget.accessToken,
                      onUnauthorized: widget.onUnauthorized,
                    )
                  : const SizedBox.shrink(),
              _visited.contains(3)
                  ? HandoverRoute(
                      children: children,
                      apiBaseUrl: widget.apiBaseUrl,
                      accessToken: widget.accessToken,
                      onUnauthorized: widget.onUnauthorized,
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() {
              _index = index;
              _visited.add(index);
            }),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.history), label: 'Journeys'),
              NavigationDestination(
                icon: Icon(Icons.notifications_none),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_2_outlined),
                label: 'Pickup',
              ),
            ],
          ),
        );
      },
    );
  }

  static List<ChildOption> _childOptions(List<ChildStatus> children) => [
        for (final child in children)
          ChildOption(studentId: child.studentId, displayName: child.displayName),
      ];
}

/// The dashboard view, separated from its wiring so it can be driven by a supplied BLoC.
///
/// Maps BLoC state onto [HomeScreen], which stays a pure render of what it is given. That
/// split is why the screen can be exercised in every state — offline, empty, failed, five
/// children with one unaccounted — without a socket.
class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.guardianName,
    required this.apiBaseUrl,
    required this.accessToken,
    this.onUnauthorized,
  });

  final String guardianName;
  final String apiBaseUrl;
  final Future<String?> Function() accessToken;
  final Future<void> Function()? onUnauthorized;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return HomeScreen(
          children: state.children,
          guardianName: guardianName,
          schoolNow: state.observedAt,
          isLoading: state.isLoading,
          // Only when there is nothing to fall back to. With cards on screen an outage is
          // a banner, not a replacement (docs/05-ui/PARENT_APP.md).
          loadFailure: state.showsFailureInsteadOfContent
              ? _failureText(state)
              : null,
          isConnected: !state.isDisconnected,
          lastUpdatedAt: state.observedAt,
          onRefresh: () async =>
              context.read<HomeBloc>().add(const HomeRefreshed()),
          onTrackChild: (status) => _openTrack(context, status),
          onChildDetails: (status) => _openDetail(context, status),
          onDeclareAbsence: state.children.isEmpty
              ? null
              : () => _push(context, AbsenceRoute(
                    children: _childOptions(state.children),
                    apiBaseUrl: apiBaseUrl,
                    accessToken: accessToken,
                    onUnauthorized: onUnauthorized,
                  )),
          onManagePickupPersons: state.children.isEmpty
              ? null
              : () => _push(context, PickupPersonsRoute(
                    children: _childOptions(state.children),
                    apiBaseUrl: apiBaseUrl,
                    accessToken: accessToken,
                    onUnauthorized: onUnauthorized,
                  )),
        );
      },
    );
  }

  void _openDetail(BuildContext context, ChildStatus status) {
    _push(
      context,
      ChildDetailRoute(
        studentId: status.studentId,
        displayName: status.displayName,
        apiBaseUrl: apiBaseUrl,
        accessToken: accessToken,
        onUnauthorized: onUnauthorized,
        onTrack: (tripId) => _push(
          context,
          LiveTripRoute(
            tripId: tripId,
            vehicleDisplayName: status.vehicleDisplayName ?? 'the bus',
            stopName: status.stopName ?? 'your stop',
            apiBaseUrl: apiBaseUrl,
            accessToken: accessToken,
            onUnauthorized: onUnauthorized,
          ),
        ),
      ),
    );
  }

  void _openTrack(BuildContext context, ChildStatus status) {
    final tripId = status.tripId;
    if (!status.canTrack || tripId == null) return;

    _push(
      context,
      LiveTripRoute(
        tripId: tripId,
        vehicleDisplayName: status.vehicleDisplayName ?? 'the bus',
        stopName: status.stopName ?? 'your stop',
        apiBaseUrl: apiBaseUrl,
        accessToken: accessToken,
        onUnauthorized: onUnauthorized,
      ),
    );
  }

  static void _push(BuildContext context, Widget route) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => route));
  }

  static List<ChildOption> _childOptions(List<ChildStatus> children) => [
        for (final child in children)
          ChildOption(studentId: child.studentId, displayName: child.displayName),
      ];

  /// What to tell the parent when nothing could be loaded.
  ///
  /// Plain language describing the situation and what to do, never a code
  /// (docs/05-ui/ACCESSIBILITY.md). The API's localised `messageKey` is the intended source
  /// once localisation lands (BR-CFG-005); until then these strings are inline, like the
  /// rest of this app's copy.
  static String _failureText(HomeState state) {
    return switch (state.failure?.code) {
      ErrorCode.dependencyUnavailable =>
        'Your device cannot reach the school right now. '
            'Check your connection and try again.',
      ErrorCode.rateLimitExceeded =>
        'Too many attempts just now. Wait a moment and try again.',
      _ => 'Something went wrong loading your children. Please try again.',
    };
  }
}
