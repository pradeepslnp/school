import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../console_destination.dart';

/// The console's primary navigation: the school-bus-yellow livery rail.
///
/// Renders whatever destinations it is given and reports which one was chosen. It does not
/// know what a destination leads to, and it does not decide which are shown — the layout
/// decides that from the window width (ADMIN_WEB.md §Responsive), because the narrow subset
/// is a product rule rather than a rendering detail.
///
/// ## Why this is not a `NavigationRail`
///
/// Material's rail gives every destination the same weight in one flat column. With nine
/// modules that costs the operator a scan of the whole list on every navigation. This rail
/// bands them by [ConsoleGroup] under quiet headings, so "where do I administer users" is
/// one glance rather than a read.
///
/// Everything drawn here is [AdminLivery.railInk] on [AdminLivery.rail] — never white, for
/// the contrast reason set out on [AdminLivery]. The selected destination inverts to an ink
/// pill with yellow text, which is the strongest legible mark available on a yellow ground
/// and carries a shape difference as well as a color one (DESIGN_SYSTEM.md §Principles —
/// color is never the only signal).
class ConsoleNavigation extends StatelessWidget {
  const ConsoleNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.extended = false,
    this.header,
    this.footer,
  });

  final List<ConsoleDestination> destinations;

  /// Index into [destinations], or null when none is selected.
  final int? selectedIndex;

  final ValueChanged<ConsoleDestination> onDestinationSelected;

  /// Labels beside icons rather than beneath them. Used at ≥1280 px, where the space exists
  /// and an icon-only rail costs a recognition step on every navigation.
  final bool extended;

  /// The product mark, rendered above the destinations.
  final Widget? header;

  /// The signed-in operator, rendered at the foot of the rail.
  final Widget? footer;

  /// Wide enough for the longest label at 14px without truncation.
  static const double extendedWidth = 244;

  /// Icon plus label beneath it, at the 40px touch-target floor plus the label's two lines.
  static const double collapsedWidth = 88;

  @override
  Widget build(BuildContext context) {
    final livery = context.livery;

    return Container(
      width: extended ? extendedWidth : collapsedWidth,
      decoration: BoxDecoration(
        color: livery.rail,
        // A hard ink edge rather than a hairline divider: it separates the rail from the
        // work surface the way the black beltline separates a bus body from its glass, and
        // it holds at any zoom level.
        border: Border(right: BorderSide(color: livery.railInk, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header!,
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _bands(context, livery),
              ),
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }

  /// The destinations, in their given order, with a heading wherever the group changes.
  ///
  /// Derived from the order rather than by grouping the list: [ConsoleDestinations.all] is
  /// ordered deliberately (see its documentation), and re-sorting here would silently
  /// override that ordering from a widget.
  List<Widget> _bands(BuildContext context, AdminLivery livery) {
    final rows = <Widget>[];
    ConsoleGroup? previous;

    for (var i = 0; i < destinations.length; i++) {
      final destination = destinations[i];

      if (destination.group != previous) {
        // No heading above the first band: it would label the rail rather than divide it.
        if (previous != null) {
          rows.add(
            _GroupHeading(
              label: _groupLabel(context, destination.group),
              // Collapsed, there is no room for a word — a hairline still says "new band".
              showLabel: extended,
              livery: livery,
            ),
          );
        } else {
          rows.add(const SizedBox(height: AdminSpacing.sm));
        }
        previous = destination.group;
      }

      rows.add(
        _RailDestination(
          destination: destination,
          selected: i == selectedIndex,
          extended: extended,
          livery: livery,
          onTap: () => onDestinationSelected(destination),
        ),
      );
    }

    rows.add(const SizedBox(height: AdminSpacing.md));
    return rows;
  }

  /// Band headings are console chrome in the operator's language.
  ///
  /// Not localised through `AppLocalizations` yet: adding three ARB keys is an ADR-0013
  /// change to the shared English/Kannada bundles, which is the localisation work's to make,
  /// not this redesign's. Tracked as part of finishing A-01's rail.
  String _groupLabel(BuildContext context, ConsoleGroup group) => switch (group) {
    ConsoleGroup.operations => 'Operations',
    ConsoleGroup.administration => 'Administration',
    ConsoleGroup.platform => 'Platform',
  };
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({
    required this.label,
    required this.showLabel,
    required this.livery,
  });

  final String label;
  final bool showLabel;
  final AdminLivery livery;

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.sm,
          vertical: AdminSpacing.sm,
        ),
        child: Divider(height: 1, thickness: 1, color: livery.railInk.withValues(alpha: 0.18)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.md,
        AdminSpacing.md,
        AdminSpacing.md,
        AdminSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: livery.railMutedInk,
        ),
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  const _RailDestination({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.livery,
    required this.onTap,
  });

  final ConsoleDestination destination;
  final bool selected;
  final bool extended;
  final AdminLivery livery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = destination.label(context);
    final foreground = selected ? livery.rail : livery.railInk;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          // Hover and focus read against yellow only as a darkening — a lighter overlay
          // disappears into the rail.
          hoverColor: livery.railInk.withValues(alpha: 0.08),
          focusColor: livery.railInk.withValues(alpha: 0.16),
          child: Semantics(
            selected: selected,
            button: true,
            child: Container(
              // The 40px floor ACCESSIBILITY.md sets for this console, plus two for the
              // label when the rail is collapsed.
              constraints: BoxConstraints(minHeight: extended ? 42 : 58),
              padding: EdgeInsets.symmetric(
                horizontal: extended ? 12 : 4,
                vertical: extended ? 0 : AdminSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected ? livery.railInk : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: extended
                  ? Row(
                      children: [
                        Icon(
                          selected ? destination.selectedIcon : destination.icon,
                          size: 19,
                          color: foreground,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            label,
                            key: Key('admin_nav_${destination.id}'),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                              color: foreground,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? destination.selectedIcon : destination.icon,
                          size: 20,
                          color: foreground,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          key: Key('admin_nav_${destination.id}'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.15,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
