import 'package:flutter/material.dart';

/// Semantic status colors for the Guardian Platform.
///
/// Canonical values — mirrors the "Status colors" table in
/// `guardian-docs/05-ui/DESIGN_SYSTEM.md`. Every client (parent, driver, admin) uses these
/// same values so "green means the child is accounted for" carries across every surface of
/// the platform.
///
/// Prefer [GuardianStatusColors] (via `GuardianStatusColors.of(brightness)`) over these
/// constants directly where you can — the extension resolves the light/dark pair for you
/// and pairs each color with its low-contrast surface tint for chip and banner fills.
class GuardianColors {
  const GuardianColors._();

  // Boarded, arrived, handed over.
  static const safe = Color(0xFF1F7A47);
  static const safeDark = Color(0xFF4CAF7D);

  // In progress, scheduled.
  static const info = Color(0xFF1B5FA8);
  static const infoDark = Color(0xFF5B9BD8);

  // Delayed, expiring, no-show.
  static const warning = Color(0xFF9A6200);
  static const warningDark = Color(0xFFE0A33E);

  /// Reserved for genuine safety events — an unaccounted child, an SOS, a handover
  /// override. Using it for a validation error would erode the one signal that must never
  /// be ignored.
  static const critical = Color(0xFFB3261E);
  static const criticalDark = Color(0xFFF2837B);

  // Not started, absent, unknown.
  static const neutral = Color(0xFF5A6472);
  static const neutralDark = Color(0xFFA2ABB8);

  /// Recorded locally, not yet synced to the server (ADR-0008).
  ///
  /// Only the driver app queues records today, but the color lives here rather than in that
  /// app so "purple means not yet synced" is available to any client that later shows the
  /// same state. Deliberately outside the [info] hue: a queued record is not "in progress",
  /// and an attendant must be able to tell the two apart at a glance.
  static const pendingSync = Color(0xFF6A4BA8);
  static const pendingSyncDark = Color(0xFFB79CE8);
}
