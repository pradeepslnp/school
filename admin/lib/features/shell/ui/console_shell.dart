import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/session/session.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../console_destination.dart';
import '../widgets/account_menu.dart';
import '../widgets/console_navigation.dart';
import '../widgets/language_switcher.dart';
import '../widgets/no_modules_notice.dart';

/// The authenticated console frame: header, navigation, content.
///
/// Every signed-in screen renders inside this. It owns the responsive behaviour and the
/// account control, and nothing else — the content is passed in, so a screen is written
/// without knowing it is inside a shell.
///
/// ## Layout (ADMIN_WEB.md §Responsive)
///
/// | Width | Layout |
/// |---|---|
/// | ≥1280 | Extended rail with labels beside icons |
/// | 768–1279 | Collapsed rail, labels beneath icons |
/// | <768 | Drawer, and the **incident-response subset only** |
///
/// The narrow case is not a smaller version of the console. It carries dashboard, alerts,
/// SOS, and live map, because a transport manager on a phone during an incident needs to
/// act, not administer — the filtering is [ConsoleDestinations.forNarrowLayout].
class ConsoleShell extends StatelessWidget {
  const ConsoleShell({
    super.key,
    required this.user,
    required this.onSignOut,
    this.destinations = ConsoleDestinations.all,
    this.selectedDestinationId,
    this.onDestinationSelected,
    this.isSigningOut = false,
    this.headerSearch,
    this.child,
  });

  final AuthenticatedUser user;
  final VoidCallback onSignOut;
  final bool isSigningOut;

  final List<ConsoleDestination> destinations;

  /// The destination currently shown, by [ConsoleDestination.id].
  final String? selectedDestinationId;

  final ValueChanged<ConsoleDestination>? onDestinationSelected;

  /// The screen. Null while the console has no modules — see [NoModulesNotice].
  final Widget? child;

  /// Global search (SRC-001), shown in the header — or null for an operator it is not offered
  /// to. Passed in rather than built here, so the shell still knows nothing about what search
  /// finds or where it leads.
  ///
  /// Not shown below [narrowBreakpoint]: the narrow layout is the incident-response subset
  /// (ADMIN_WEB.md §Responsive), and a results panel wider than the screen is not usable there.
  final Widget? headerSearch;

  /// Full sidebar and detail panel above this (ADMIN_WEB.md §Responsive).
  static const double wideBreakpoint = 1280;

  /// Below this, the incident-response subset only.
  static const double narrowBreakpoint = 768;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isNarrow = width < narrowBreakpoint;

        final visible = isNarrow
            ? ConsoleDestinations.forNarrowLayout()
            : destinations;

        // Navigation appears only where there is a choice to make. With one destination
        // there is nowhere else to go, and the rail would be a permanent column of chrome
        // pointing at the screen already open. `NavigationRail` also asserts on fewer than
        // two destinations, so this is the difference between an empty console and a crash
        // on the day A-01 ships alone.
        final showNavigation = visible.length >= 2;

        final selectedIndex = _selectedIndex(visible);
        final content = child ?? const NoModulesNotice();

        return Scaffold(
          appBar: _ConsoleHeader(
            user: user,
            onSignOut: onSignOut,
            isSigningOut: isSigningOut,
            search: isNarrow ? null : headerSearch,
            // The drawer button is only meaningful when there is something in the drawer.
            showMenuButton: isNarrow && showNavigation,
            // The wordmark lives on the rail. Where there is no rail — narrow, or a console
            // with nothing to navigate between — the header carries it instead, so the
            // product is never unnamed.
            showBrand: isNarrow || !showNavigation,
          ),
          drawer: isNarrow && showNavigation
              ? _ConsoleDrawer(
                  destinations: visible,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                )
              : null,
          body: Row(
            children: [
              if (!isNarrow && showNavigation)
                ConsoleNavigation(
                  destinations: visible,
                  selectedIndex: selectedIndex,
                  extended: width >= wideBreakpoint,
                  header: _RailBrand(extended: width >= wideBreakpoint),
                  onDestinationSelected: (destination) =>
                      onDestinationSelected?.call(destination),
                ),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }

  int? _selectedIndex(List<ConsoleDestination> visible) {
    if (selectedDestinationId == null) return null;
    final index = visible.indexWhere((d) => d.id == selectedDestinationId);
    // -1 means the current screen is not in the visible set — a wide-only screen viewed
    // after the window narrowed. Reported as "nothing selected" rather than defaulting to
    // the first item, which would highlight a destination the operator is not on.
    return index < 0 ? null : index;
  }
}

/// The product mark, at the head of the livery rail.
///
/// Set in the display face on the rail's own ink — the one place in the console where the
/// brand is stated rather than implied. Collapsed, the bus mark carries it alone: the
/// wordmark would truncate at 88px and a truncated wordmark reads as a bug.
class _RailBrand extends StatelessWidget {
  const _RailBrand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final livery = context.livery;

    if (!extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
        child: Semantics(
          label: context.l10n.consoleHeaderBrand,
          child: Icon(
            Icons.directions_bus_filled_outlined,
            size: 26,
            color: livery.railInk,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        AdminSpacing.lg,
        20,
        AdminSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_bus_filled_outlined,
                size: 26,
                color: livery.railInk,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  context.l10n.consoleHeaderBrand.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kAdminDisplayFontFamily,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: livery.railInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Transport Console'.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: livery.railMutedInk,
            ),
          ),
        ],
      ),
    );
  }
}

/// The console header: product mark, and who is signed in.
class _ConsoleHeader extends StatelessWidget implements PreferredSizeWidget {
  const _ConsoleHeader({
    required this.user,
    required this.onSignOut,
    required this.isSigningOut,
    required this.showMenuButton,
    required this.showBrand,
    this.search,
  });

  final AuthenticatedUser user;
  final VoidCallback onSignOut;
  final bool isSigningOut;
  final bool showMenuButton;
  final bool showBrand;
  final Widget? search;

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final livery = context.livery;

    return AppBar(
      automaticallyImplyLeading: showMenuButton,
      titleSpacing: showMenuButton ? 0 : AdminSpacing.md,
      backgroundColor: livery.panel,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: livery.border)),
      title: showBrand || search != null
          ? Row(
              children: [
                if (showBrand) ...[
                  Semantics(
                    excludeSemantics: true,
                    child: Icon(
                      Icons.directions_bus_filled_outlined,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AdminSpacing.sm),
                  Text(
                    context.l10n.consoleHeaderBrand,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: kAdminDisplayFontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (search != null) ...[
                  if (showBrand) const SizedBox(width: AdminSpacing.lg),
                  // Bounded: a search field stretched across a wide monitor reads as a banner,
                  // and its results panel would open far from where the eye is.
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: search,
                    ),
                  ),
                ],
              ],
            )
          : null,
      actions: [
        const LanguageSwitcher(),
        const SizedBox(width: AdminSpacing.sm),
        AccountMenu(
          user: user,
          onSignOut: onSignOut,
          isSigningOut: isSigningOut,
        ),
        const SizedBox(width: AdminSpacing.md),
      ],
    );
  }
}

/// Navigation below 768 px.
class _ConsoleDrawer extends StatelessWidget {
  const _ConsoleDrawer({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<ConsoleDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<ConsoleDestination>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        // Dismissed from this context, which is below the shell's Scaffold — closing it
        // first means the new screen is not revealed behind a scrim the operator then has
        // to dismiss themselves.
        Navigator.of(context).pop();
        onDestinationSelected?.call(destinations[index]);
      },
      children: [
        const SizedBox(height: AdminSpacing.md),
        for (final destination in destinations)
          NavigationDrawerDestination(
            key: Key('admin_drawer_${destination.id}'),
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label(context)),
          ),
      ],
    );
  }
}
