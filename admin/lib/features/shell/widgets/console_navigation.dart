import 'package:flutter/material.dart';

import '../console_destination.dart';

/// The console's primary navigation, as a side rail.
///
/// Renders whatever destinations it is given and reports which one was chosen. It does not
/// know what a destination leads to, and it does not decide which are shown — the layout
/// decides that from the window width (ADMIN_WEB.md §Responsive), because the narrow subset
/// is a product rule rather than a rendering detail.
class ConsoleNavigation extends StatelessWidget {
  const ConsoleNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.extended = false,
  });

  final List<ConsoleDestination> destinations;

  /// Index into [destinations], or null when none is selected.
  final int? selectedIndex;

  final ValueChanged<ConsoleDestination> onDestinationSelected;

  /// Labels beside icons rather than beneath them. Used at ≥1280 px, where the space exists
  /// and an icon-only rail costs a recognition step on every navigation.
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationRail(
      extended: extended,
      // Labels always visible when collapsed too: an icon-only rail is a memory test, and
      // the console's modules are not universally recognizable pictograms
      // (DESIGN_SYSTEM.md §Principles — color and shape are never the only signal).
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) =>
          onDestinationSelected(destinations[index]),
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            // NavigationRailDestination is a data class, not a widget, so the key rides on
            // the label. Not the icon: the rail swaps icon for selectedIcon, so a key there
            // would disappear on the one destination that is currently selected.
            label: Text(
              destination.label(context),
              key: Key('admin_nav_${destination.id}'),
            ),
          ),
      ],
    );
  }
}
