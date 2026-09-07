import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';
import '../../../app/theme_controller.dart';
import '../../../core/domain.dart';
import '../../../core/l10n_extensions.dart';
import '../../../utils/utils.dart';
import '../repository/models/child_status.dart';
import '../widgets/child_status_card.dart';
import '../widgets/connection_banner.dart';
import '../widgets/critical_alert_banner.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_quick_actions.dart';

/// P-02 — the parent dashboard. What the app opens to.
///
/// **This screen is the product** (docs/05-ui/SCREEN_INVENTORY.md). It answers "is my child
/// fine?" with zero taps, in a 10–20 second one-handed glance, and everything else on it is
/// secondary to that.
///
/// Renders state it is given; it does not fetch. Loading, retry, and refresh are the
/// caller's concern, which keeps this widget testable against every state without a
/// network or a fake server (ENGINEERING_PRINCIPLES.md §8).
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.children,
    this.guardianName,
    this.schoolNow,
    this.isLoading = false,
    this.loadFailure,
    this.isConnected = true,
    this.lastUpdatedAt,
    this.onRefresh,
    this.onTrackChild,
    this.onChildDetails,
    this.onCallSchool,
    this.onDeclareAbsence,
    this.onManagePickupPersons,
  });

  final List<ChildStatus> children;

  /// Who to greet. Null while the profile is still loading — the dashboard drops the
  /// greeting rather than showing "Good morning, " with a gap in it.
  final String? guardianName;

  /// The current time at the school. Drives the greeting and the header's timezone line,
  /// which is the one place the screen declares which clock every time on it belongs to
  /// (BR-CFG-006).
  final SchoolTime? schoolNow;

  final bool isLoading;

  /// Non-null when the last load failed. Shown in place of stale content rather than
  /// alongside it — see [BR-TRACK-003].
  final String? loadFailure;

  /// False when the device cannot reach the platform.
  ///
  /// Drives the cached-data banner. The parent app is a read surface and not offline-first
  /// (ADR-0008), so this is a display concern — but an unlabelled one is the failure
  /// BR-TRACK-003 exists to prevent.
  final bool isConnected;

  /// When the shown data last loaded successfully.
  final SchoolTime? lastUpdatedAt;

  final Future<void> Function()? onRefresh;
  final void Function(ChildStatus)? onTrackChild;
  final void Function(ChildStatus)? onChildDetails;

  /// The action offered beside a critical alert. Null where the school has no reachable
  /// number configured.
  final VoidCallback? onCallSchool;

  // Quick actions. Null means the guardian does not hold the right that opens the screen —
  // see [DashboardQuickActions]. Journey history and notifications moved to the bottom tab
  // bar (Journeys, Alerts) and are no longer offered here.
  final VoidCallback? onDeclareAbsence;
  final VoidCallback? onManagePickupPersons;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.homeAppBarTitle),
        actions: [
          const _LanguageSwitcherButton(),
          const _ThemeModeButton(),
          if (onRefresh != null)
            IconButton(
              onPressed: () => onRefresh!(),
              icon: const Icon(Icons.refresh),
              tooltip: context.l10n.refreshTooltip,
            ),
        ],
      ),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (isLoading && children.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadFailure != null && children.isEmpty) {
      return _Message(
        icon: Icons.cloud_off,
        title: context.l10n.homeLoadFailureTitle,
        detail: loadFailure!,
        onRetry: onRefresh,
      );
    }

    if (children.isEmpty) {
      return _Message(
        icon: Icons.family_restroom,
        title: context.l10n.noChildrenLinkedTitle,
        detail: context.l10n.homeNoChildrenDetail,
      );
    }

    // Anything needing attention is pulled to the top. A parent should never scroll to
    // discover that a child is unaccounted for.
    final ordered = [...children]..sort(_byUrgency);
    final critical =
        ordered.where((c) => c.journeyState.isCritical).toList(growable: false);

    final content = CustomScrollView(
      // Always scrollable so pull-to-refresh works with a single child on screen, where
      // the content does not fill the viewport.
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (guardianName != null)
          SliverToBoxAdapter(
            child: _Centred(
              child: DashboardHeader(
                guardianName: guardianName!,
                schoolNow: schoolNow,
              ),
            ),
          ),
        if (!isConnected)
          SliverToBoxAdapter(
            child: _Centred(
              child: Padding(
                padding: const EdgeInsets.only(bottom: GuardianSpacing.sm),
                child: ConnectionBanner(
                  lastUpdatedAt: lastUpdatedAt,
                  onRetry: onRefresh == null ? null : () => onRefresh!(),
                ),
              ),
            ),
          ),
        // Above the cards, always. This is the only element allowed to dominate the screen
        // (docs/05-ui/PARENT_APP.md).
        SliverList.builder(
          itemCount: critical.length,
          itemBuilder: (context, index) => _Centred(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                GuardianSpacing.md,
                GuardianSpacing.sm,
                GuardianSpacing.md,
                GuardianSpacing.sm,
              ),
              child: CriticalAlertBanner(
                status: critical[index],
                onCallSchool: onCallSchool,
                onViewDetail: onChildDetails == null
                    ? null
                    : () => onChildDetails!(critical[index]),
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: ordered.length,
          itemBuilder: (context, index) {
            final status = ordered[index];
            return _Centred(
              child: ChildStatusCard(
                status: status,
                onTrackPressed: status.canTrack && onTrackChild != null
                    ? () => onTrackChild!(status)
                    : null,
                onDetailsPressed:
                    onChildDetails != null ? () => onChildDetails!(status) : null,
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: _Centred(
            child: DashboardQuickActions(
              onDeclareAbsence: onDeclareAbsence,
              onManagePickupPersons: onManagePickupPersons,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: GuardianSpacing.lg)),
      ],
    );

    // Cards stay at a readable width and centre on a tablet rather than stretching into
    // a full-width band that is hard to scan.
    final padded = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.isWideScreen ? context.gutter : 0,
      ),
      child: content,
    );

    if (onRefresh == null) return padded;
    return RefreshIndicator(onRefresh: onRefresh!, child: padded);
  }

  static int _byUrgency(ChildStatus a, ChildStatus b) {
    int rank(ChildStatus s) {
      if (s.journeyState.isCritical) return 0;
      if (s.journeyState.isWarning) return 1;
      if (s.canTrack) return 2;
      return 3;
    }

    final byRank = rank(a).compareTo(rank(b));
    return byRank != 0 ? byRank : a.displayName.compareTo(b.displayName);
  }
}

/// Constrains a dashboard row to a readable measure and centres it.
///
/// Applied per row rather than around the whole scroll view so the list keeps its own
/// scrollbar and overscroll at the window's full width.
class _Centred extends StatelessWidget {
  const _Centred({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ReadableWidth(child: child);
}

/// Switches between light, dark, and the device setting.
///
/// Sits in the app bar rather than behind a settings screen: a parent squinting at a bright
/// screen in a dark bedroom, or a washed-out one at a sunlit school gate, needs the fix
/// where they are (docs/05-ui/ACCESSIBILITY.md, situational conditions).
class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton();

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();

    final mode = controller.value;
    return IconButton(
      onPressed: controller.cycle,
      icon: Icon(mode.icon),
      // Both state and action, because an icon alone tells a screen-reader user neither
      // which theme is active nor what the button will do.
      tooltip: context.l10n.themeToggleTooltip(mode.label(context.l10n)),
      isSelected: mode != ThemeMode.system,
    );
  }
}

/// Switches between English and Kannada (ADR-0013).
///
/// Sits beside the appearance toggle for the same reason that one lives in the app bar
/// rather than behind a settings screen: this app currently has no settings surface at all
/// (P-02 is the whole product, docs/05-ui/SCREEN_INVENTORY.md), and a language a parent
/// cannot read is at least as urgent to fix from wherever they are as a screen they cannot
/// see.
class _LanguageSwitcherButton extends StatelessWidget {
  const _LanguageSwitcherButton();

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.translate_outlined),
      tooltip: context.l10n.languageSwitcherTooltip,
      initialValue: controller.value,
      onSelected: controller.set,
      itemBuilder: (context) => const [
        PopupMenuItem(value: Locale('en'), child: Text('English')),
        // Shown in its own script regardless of the active language, the same way a
        // language picker's option always names itself — a parent whose current language is
        // wrong needs to find their own language without first being able to read the menu.
        PopupMenuItem(value: Locale('kn'), child: Text('ಕನ್ನಡ')),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GuardianSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizeConstants.emptyStateIcon, color: context.colors.onSurfaceVariant),
            const SizedBox(height: GuardianSpacing.md),
            Text(
              title,
              style: context.texts.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GuardianSpacing.sm),
            Text(
              detail,
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: GuardianSpacing.lg),
              FilledButton.tonal(
                onPressed: () => onRetry!(),
                child: Text(context.l10n.tryAgainButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
