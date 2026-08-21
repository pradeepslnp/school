import 'package:flutter/widgets.dart';

import '../../app/theme.dart';
import 'responsive_context.dart';

/// Touch target sizing that can grow but never shrink.
///
/// The floor here is deliberately larger than the platform minimum and larger than the
/// parent app's. This app is operated next to a moving vehicle by someone whose attention
/// belongs on the road and the children, and a mis-tap records the **wrong child** as
/// boarded or alighted. That is a safety defect, not a usability one
/// (docs/05-ui/DRIVER_ATTENDANT_APP.md, PRODUCT_PRINCIPLES.md §1).
///
/// Sizes scale up on roomy screens and are clamped at the floor below which they never go,
/// whatever the screen size.
abstract final class TouchTarget {
  /// Absolute floor for anything tappable in this app.
  static const double minimum = kDriverTouchTarget;

  /// SOS and other emergency controls. Never shares an edge with another control.
  static const double emergency = kSosTouchTarget;

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
      medium: preferred + 4,
      // Tablet mounts are common in vehicles; use the extra room.
      expanded: preferred + 8,
    );
    return scaled < effectiveFloor ? effectiveFloor : scaled;
  }

  /// Guarantees [child] occupies at least a minimum tappable square.
  static Widget ensure({required Widget child, double? size}) {
    final target = size ?? minimum;
    return SizedBox(
      width: target,
      height: target,
      child: Center(child: child),
    );
  }
}
