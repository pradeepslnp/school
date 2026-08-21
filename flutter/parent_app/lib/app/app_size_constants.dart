import 'theme.dart';

/// Fixed UI metrics that recur across screens but aren't spacing or radius.
///
/// [GuardianSpacing] and [GuardianRadius] (theme.dart) already own gaps between elements
/// and corner rounding — this file is for everything else that keeps getting typed as a
/// bare number at the call site: icon glyph sizes, dot/badge diameters, stroke widths,
/// fixed-width columns.
///
/// Every constant here replaced a literal that was already duplicated in two or more
/// widgets (see the call sites noted on each one). A value used exactly once stays a
/// literal where it's used — this file is not the place for speculative sizes nobody has
/// asked for yet (docs/06-development/PROJECT_STRUCTURE.md: no speculative abstraction).
class AppSizeConstants {
  const AppSizeConstants._();

  // ---- Icon glyph sizes --------------------------------------------------
  // Named by role, not by pixel value: retuning `iconLg` from 28 to 26 should never require
  // touching a call site.

  /// Small inline glyphs. freshness_indicator, dashboard_header.
  static const double iconXs = 14;

  /// journey_status_chip's status icon.
  static const double iconSm = 16;

  /// connection_banner, login_error_text.
  static const double iconMd = 18;

  /// critical_alert_banner's leading icon.
  static const double iconLg = 28;

  /// vehicle_map_surface's marker glyph.
  static const double iconXl = 40;

  /// The icon on a full-screen "nothing here" / error placeholder. home, journey_history,
  /// child_detail, live_trip, and notifications screens all use the same size so an empty
  /// state reads identically everywhere it appears.
  static const double emptyStateIcon = 48;

  // ---- Indicators ---------------------------------------------------------

  /// The unread dot on a notification tile. Tied to [GuardianSpacing.sm] rather than its
  /// own literal, since a dot and an 8px gap are coincidentally the same number for a
  /// reason worth keeping visible.
  static const double unreadDotDiameter = GuardianSpacing.sm;

  /// The inline loading spinner shown inside a button or form field while a request is in
  /// flight (login, absence, pickup-person forms).
  static const double inlineSpinnerSize = 20;

  // ---- Borders --------------------------------------------------------------

  /// The emphasised border on a critical-status card or banner. Deliberately thicker than
  /// the 1px hairline `CardTheme` already draws, so a genuine safety event reads as
  /// structurally different, not just differently colored (docs/05-ui/ACCESSIBILITY.md:
  /// colour is never the only signal).
  static const double emphasisBorderWidth = 2;

  // ---- Fixed-width layout -----------------------------------------------------

  /// The timestamp column shared by journey_history_entry_tile and journey_leg_tile, so a
  /// column of times lines up whether it's rendered in journey history or on a child's
  /// detail screen.
  static const double timestampColumnWidth = 92;
}
