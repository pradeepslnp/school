import 'package:flutter/material.dart';

import '../../../app/dependencies.dart';
import '../../../core/offline/sync_status.dart';
import 'sync_status_banner.dart';

/// [SyncStatusBanner] wired to the running sync engine.
///
/// Split from the banner itself so the banner stays a pure function of its state — every
/// condition it can show can be rendered in a test or a golden by handing it a [SyncStatus],
/// with no database, no engine, and no timing.
///
/// Kept subscribed for the life of the screen it sits on. The pending count is required to be
/// visible on **every** screen (D-14), so this widget belongs in the app shell rather than
/// being remembered individually by each route.
class LiveSyncStatusBanner extends StatelessWidget {
  const LiveSyncStatusBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final engine = DependencyScope.of(context).syncEngine;

    return StreamBuilder<SyncStatus>(
      stream: engine.statusStream,
      // The engine holds its current status, so the banner renders correctly on the first
      // frame instead of showing a wrong "all sent" until the next event arrives.
      initialData: engine.status,
      builder: (context, snapshot) => SyncStatusBanner(
        status: snapshot.data ?? const SyncStatus(),
        onTap: onTap,
      ),
    );
  }
}
