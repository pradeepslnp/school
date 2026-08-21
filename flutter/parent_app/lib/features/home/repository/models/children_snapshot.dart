import 'package:flutter/foundation.dart';

import '../../../../core/domain.dart';
import 'child_status.dart';

/// One reading of the dashboard: every child, and when the server said it.
///
/// The timestamp travels with the children rather than being taken from the device clock
/// on arrival. That is what lets the screen say "last updated 07:44" honestly while
/// offline — the time belongs to the data, not to the moment it was displayed.
@immutable
class ChildrenSnapshot {
  const ChildrenSnapshot({required this.children, this.observedAt});

  final List<ChildStatus> children;

  /// When the server produced this reading, in the school's timezone (BR-CFG-006).
  ///
  /// Null only when the response carried no usable timestamp. Drives both the greeting and
  /// the "last updated" label.
  final SchoolTime? observedAt;

  static const empty = ChildrenSnapshot(children: <ChildStatus>[]);
}
