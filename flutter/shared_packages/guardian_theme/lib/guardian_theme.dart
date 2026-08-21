/// Shared color theme for the Guardian Platform's three Flutter clients:
/// guardian-admin-web, guardian-driver-app, and guardian-parent-app.
///
/// Canonical values mirror `guardian-docs/05-ui/DESIGN_SYSTEM.md` — the color table there is
/// the source of truth; this package is its implementation. Change a color here and every
/// app that depends on this package (via a local `path:` dependency) picks it up on its next
/// `flutter pub get` / rebuild — no need to edit each app separately.
///
/// Deliberately colors only. Touch targets, spacing, and type scale stay defined per app,
/// because DESIGN_SYSTEM.md specifies those as per-client on purpose: a control sized for a
/// desk is not sized for a moving vehicle.
library;

export 'src/guardian_color_schemes.dart';
export 'src/guardian_colors.dart';
export 'src/guardian_status_colors.dart';
