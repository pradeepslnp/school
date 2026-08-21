import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// A child's initials, used where a photo would go.
///
/// Initials rather than a photo because student photos load through the authorising
/// endpoint and never a public URL (docs/05-ui/DESIGN_SYSTEM.md) — that endpoint is not
/// wired into this app yet, and a placeholder network image would be exactly the
/// pseudo-production code FLUTTER_APP_INSTRUCTIONS.md rules out.
///
/// The tint is derived from the name so each child in a family is visually distinct at a
/// glance, and stable across launches. It is decoration only: the name is always shown
/// beside it, so nothing depends on telling the tints apart.
class ChildAvatar extends StatelessWidget {
  const ChildAvatar({
    super.key,
    required this.name,
    this.size = 44,
  });

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    // Four brand-derived tints. All are container roles, so the scheme guarantees their
    // `on*` partner is legible in both themes.
    final fills = <(Color, Color)>[
      (scheme.primaryContainer, scheme.onPrimaryContainer),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    ];
    final (background, foreground) = fills[name.hashCode.abs() % fills.length];

    return Semantics(
      // The card states the name in text immediately after, so the avatar itself is
      // decorative to a screen reader. Announcing it again is noise.
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(
          _initials(name),
          style: context.texts.titleMedium?.copyWith(color: foreground),
          // The one place a fixed size is safe to cap: the circle cannot grow with the text
          // scale without becoming a shape that pushes the name off the card. The name
          // beside it carries the same information and scales fully.
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
  }

  /// First letter of the first and last name parts.
  ///
  /// Takes the ends rather than the first two words: many of the platform's locales place a
  /// family name last, and "Aarav Kumar Sharma" should read AS, not AK.
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}
