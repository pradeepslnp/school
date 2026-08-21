# guardian_theme

Shared color theme for the Guardian Platform's three Flutter clients: `admin`,
`flutter/driver_attender_app`, and `flutter/parent_app`.

This package holds **colors only** — the `GuardianColors` status palette, the
`GuardianStatusColors` theme extension (status color + surface tint pairs), and the
`guardianLightColorScheme` / `guardianDarkColorScheme` `ColorScheme`s. Touch targets,
spacing, and type scale stay defined per app, because
[`DESIGN_SYSTEM.md`](../../../documentation/05-ui/DESIGN_SYSTEM.md) specifies those as per-client
on purpose: a control sized for a desk is not sized for a moving vehicle.

Canonical values mirror the "Colour" and "Status colors" tables in
`documentation/05-ui/DESIGN_SYSTEM.md` — that doc is the source of truth; this package is its
implementation. Change a color here and every app that depends on this package picks it up
on its next `flutter pub get` / rebuild.

## Using it in an app

Each app depends on this package via a local path dependency (all four repos are expected to
sit as siblings under the same parent folder):

```yaml
dependencies:
  guardian_theme:
    path: ../guardian-theme
```

Then import it:

```dart
import 'package:guardian_theme/guardian_theme.dart';
```

## Changing a color

Edit the value in `lib/src/guardian_colors.dart` (status colors) or
`lib/src/guardian_color_schemes.dart` (brand / full `ColorScheme`), then run
`flutter pub get` in each app that depends on this package (or just rebuild — a path
dependency is picked up automatically, no version bump needed for local development).

If you later push this repo to a remote and want the apps to track it by git ref/tag instead
of a local path, switch each app's dependency to:

```yaml
dependencies:
  guardian_theme:
    git:
      url: https://github.com/your-org/guardian-theme.git
      ref: v0.1.0
```

## Note on the driver app

Before this package existed, `flutter/driver_attender_app` built its `ColorScheme` from
`ColorScheme.fromSeed(..., contrastLevel: 0.5)` — a deliberate contrast boost beyond the
platform's baseline WCAG AA, for use in a moving vehicle with glare. Migrating the driver app
onto `guardianLightColorScheme` / `guardianDarkColorScheme` (the same exact values as the
other two apps) removes that extra boost; it still meets the AA figures in
`DESIGN_SYSTEM.md`/`ACCESSIBILITY.md`, but it's worth a visual check of the driver app in
bright-light conditions before shipping this change, given how deliberately
`DRIVER_ATTENDANT_APP.md` calls out that app's legibility requirements.
