import 'package:flutter/widgets.dart';

import '../../app/theme.dart';
import 'responsive_context.dart';

/// Touch target sizing that can grow but never shrink.
///
/// This is the one place where "responsive" must be asymmetric. A layout that scales
/// everything proportionally will shrink controls on a small phone, and a control that is
/// hard to hit is not merely an annoyance here — in the driver app it is a mis-tapped child,
/// and in the parent app it is a missed absence declaration on a phone held one-handed at a
/// school gate.
///
/// So sizes scale **up** on roomy screens and are clamped at a floor below which they never
/// go, whatever the screen size or scale factor
/// (docs/05-ui/ACCESSIBILITY.md, PRODUCT_PRINCIPLES.md §1).
abstract final class TouchTarget {
  /// Absolute floor for anything tappable. Matches the platform accessibility minimum.
  ///
  /// The driver app raises this — see that app's copy of this file.
  static const double minimum = kMinimumTouchTarget;

  /// Comfortable size for a primary action.
  static const double comfortable = 56;

  /// Resolves a target size for the current screen.
  ///
  /// [preferred] may be larger than [minimum]; it is never allowed to fall below it.
  static double resolve(
    BuildContext context, {
    double preferred = minimum,
    double? floor,
  }) {
    final effectiveFloor = floor ?? minimum;
    final scaled = context.responsive(
      compact: preferred,
      medium: preferred,
      // More room, so a little more generous — never smaller.
      expanded: preferred + 4,
    );
    return scaled < effectiveFloor ? effectiveFloor : scaled;
  }

  /// Guarantees [child] occupies at least a minimum tappable square.
  ///
  /// Use around small icons: a 16dp icon is a 16dp hit area unless something enforces more.
  static Widget ensure({required Widget child, double? size}) {
    final target = size ?? minimum;
    return SizedBox(
      width: target,
      height: target,
      child: Center(child: child),
    );
  }
}
