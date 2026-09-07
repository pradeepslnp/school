import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/dependencies.dart';
import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';

/// The console's language switcher (ADR-0013 §5).
///
/// Lives in the shell header, next to [AccountMenu], rather than inside `school_settings`:
/// a school's name, timezone, and geofence radius (TEN-002, `SchoolEditForm`) are properties
/// of the *school*, but which language this console renders in is a property of the *operator
/// looking at the screen* — the same person may administer more than one school, and a
/// colleague with a different language preference may sign in on the same shared workstation
/// next (`AccountMenu`'s own reasoning about shared desks applies here too). A per-school
/// setting would be both the wrong owner for a personal reading preference and invisible to
/// roles — `SUPER_ADMIN` chief among them — that never open School at all. The header, by
/// contrast, is reachable from every authenticated screen, matching how [AccountMenu] answers
/// "who am I" from anywhere in the console; this answers "what language am I reading it in".
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DependencyScope.of(context).localeController;

    return ValueListenableBuilder<Locale>(
      valueListenable: controller,
      builder: (context, activeLocale, _) {
        return PopupMenuButton<Locale>(
          key: const Key('admin_shell_language_switcher'),
          tooltip: context.l10n.languageSwitcherTooltip,
          padding: EdgeInsets.zero,
          initialValue: activeLocale,
          onSelected: (locale) => unawaited(controller.setLocale(locale)),
          itemBuilder: (context) => [
            for (final locale in LocaleController.supportedLocales)
              PopupMenuItem<Locale>(
                key: Key('admin_shell_language_option_${locale.languageCode}'),
                value: locale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      child: locale == activeLocale
                          ? Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    const SizedBox(width: AdminSpacing.sm),
                    Text(_nativeName(context, locale)),
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate_outlined, size: 20),
                const SizedBox(width: AdminSpacing.xs),
                Text(_nativeName(context, activeLocale), style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Each language's own name for itself — "English", "ಕನ್ನಡ" — not translated per target
  /// locale. A language picker conventionally lists every option in its own script so a
  /// reader can find their language regardless of which one the console currently renders in;
  /// see `TRANSLATION_STATUS.md` for why these two keys carry the identical value in both ARB
  /// files rather than being tracked as a pending Kannada translation.
  String _nativeName(BuildContext context, Locale locale) => switch (locale.languageCode) {
        'kn' => context.l10n.languageNameKannada,
        _ => context.l10n.languageNameEnglish,
      };
}
