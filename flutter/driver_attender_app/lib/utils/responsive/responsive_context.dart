import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'screen_class.dart';

/// Responsive helpers on [BuildContext].
///
/// The whole point is that a widget asks a question about *this* build — "how much room do
/// I have right now" — instead of reading a constant fixed at authoring time. A rotation, a
/// split-screen resize, or a foldable opening all change the answer, and every widget that
/// asks gets the new one automatically.
extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  ScreenClass get screenClass => Breakpoints.classify(screenWidth);

  bool get isCompact => screenClass.isCompact;
  bool get isMedium => screenClass.isMedium;
  bool get isExpanded => screenClass.isExpanded;
  bool get isWideScreen => screenClass.isWide;

  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Notches, home indicators, and status bars.
  EdgeInsets get safeAreaInsets => MediaQuery.paddingOf(this);

  /// The on-screen keyboard's height, or zero.
  double get keyboardInset => MediaQuery.viewInsetsOf(this).bottom;
  bool get isKeyboardVisible => keyboardInset > 0;

  /// The user's text scaling preference.
  ///
  /// Read to *check* layouts, never to compute a font size — Flutter already applies this
  /// to every `Text`. Multiplying a font size by it as well scales twice.
  TextScaler get textScaler => MediaQuery.textScalerOf(this);

  /// True when text is enlarged enough to break dense layouts.
  ///
  /// At this point rows should become columns rather than overflow. Guardians who need
  /// large text are exactly the users who must not miss a "did not board" alert
  /// (docs/05-ui/ACCESSIBILITY.md).
  bool get hasLargeText => textScaler.scale(16) > 16 * 1.3;

  /// Picks a value for the current screen class.
  ///
  /// Falls back downward — `medium` is used for `expanded` when no expanded value is given,
  /// so a caller only names the sizes that actually differ.
  T responsive<T>({required T compact, T? medium, T? expanded}) {
    return switch (screenClass) {
      ScreenClass.compact => compact,
      ScreenClass.medium => medium ?? compact,
      ScreenClass.expanded => expanded ?? medium ?? compact,
    };
  }

  /// Horizontal page padding.
  ///
  /// Grows with the window so content is not pinned to the edges of a tablet.
  double get gutter => responsive(
        compact: DriverSpacing.md,
        medium: DriverSpacing.lg,
        expanded: DriverSpacing.xl,
      );

  EdgeInsets get pagePadding => EdgeInsets.symmetric(horizontal: gutter);

  /// Width a column of content should be constrained to.
  ///
  /// Text stretched across a wide screen is hard to read, so it is capped and centred.
  double get contentMaxWidth =>
      screenWidth < Breakpoints.readableContentWidth
          ? screenWidth
          : Breakpoints.readableContentWidth;

  /// Columns for a grid of cards, given a minimum comfortable card width.
  int gridColumns({double minTileWidth = 320}) {
    final usable = screenWidth - (gutter * 2);
    final columns = (usable / minTileWidth).floor();
    return columns < 1 ? 1 : columns;
  }
}

/// Constrains a child to a readable width and centres it.
///
/// Wrap page bodies in this rather than letting them span a tablet edge to edge.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Breakpoints.readableContentWidth,
        ),
        child: child,
      ),
    );
  }
}
