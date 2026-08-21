import 'package:flutter/material.dart';

import '../../../app/app_size_constants.dart';
import '../../../app/theme.dart';

/// Reserves the space P-04's map occupies, without drawing one.
///
/// A real map needs a maps SDK and per-platform API keys (docs/06-development do not
/// provision either for this build of work, which is scoped to the Flutter client and its
/// dummy data only). Rather than fabricate tiles or a fake vehicle icon moving over a static
/// image — a rendering that looks live but is not — this surface says plainly what it is.
///
/// This is not a regression for the parent: PARENT_APP.md is explicit that the map is an
/// enhancement and the text summary above it already carries the full answer
/// ("Bus 12 · 3 stops away · ~7 min to Green Park"), independent of whether a map ever
/// renders below it (docs/05-ui/ACCESSIBILITY.md).
class VehicleMapSurface extends StatelessWidget {
  const VehicleMapSurface({super.key, required this.headingDeg});

  final double? headingDeg;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // The information above already exists as text; a screen reader gains nothing from
      // this decorative surface and should not have to step through it.
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(GuardianRadius.lg),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: (headingDeg ?? 0) * 3.14159265 / 180,
                  child: Icon(
                    Icons.navigation,
                    size: AppSizeConstants.iconXl,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: GuardianSpacing.sm),
                Text(
                  'Map view',
                  style: context.texts.labelMedium
                      ?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
