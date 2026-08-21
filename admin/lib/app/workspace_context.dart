import 'package:flutter/foundation.dart';

/// The school id the operator is currently working with, remembered across screens for one
/// session — so typing it once on Drivers, Vehicles, or Routes carries over to the others,
/// instead of pasting the same id into every screen in turn.
///
/// Deliberately in-memory only, matching `InMemorySessionStore`'s own reasoning: this is a
/// convenience, not a saved preference, and clears with the tab like everything else here.
/// A `ValueNotifier` rather than a plain field so a screen opened after another already set it
/// can react without an extra rebuild trigger of its own.
class WorkspaceContext extends ValueNotifier<String?> {
  WorkspaceContext() : super(null);
}
