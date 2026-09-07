import 'package:flutter/material.dart';

import '../core/locale/locale_controller.dart';
import '../l10n/l10n_extensions.dart';

/// AppBar action that lets a driver choose the app's language (ADR-0013).
///
/// Deliberately one widget used in two places rather than two separate pickers: before
/// sign-in (`SignInScaffold`'s AppBar — a driver who cannot read the sign-in screen has no
/// other way to reach it) and after (`_DutyScreen`'s AppBar, next to sign-out). A single
/// widget means the two cannot drift apart in wording or behaviour.
///
/// An app-shell control living beside `theme.dart` and `dependencies.dart` in `lib/app/`,
/// not a `features/` widget — like theme, this has no bloc, no repository, and no remote
/// data; it is a thin view over [LocaleController] (ENGINEERING_PRINCIPLES.md §8: a bloc is
/// for a decision, and there is no decision here beyond "which of three fixed options").
class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key, required this.controller});

  final LocaleController controller;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('language_switcher_button'),
      tooltip: context.l10n.languageSwitcherTooltip,
      icon: const Icon(Icons.translate),
      onPressed: () => _openPicker(context),
    );
  }

  Future<void> _openPicker(BuildContext context) {
    final l10n = context.l10n;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => ValueListenableBuilder<Locale?>(
        valueListenable: controller,
        builder: (context, current, _) => SimpleDialog(
          title: Text(l10n.languagePickerTitle),
          children: [
            _LanguageOption(
              label: l10n.languageOptionSystemDefault,
              selected: current == null,
              onSelected: () => _choose(dialogContext, null),
            ),
            _LanguageOption(
              label: l10n.languageOptionEnglish,
              selected: current == const Locale('en'),
              onSelected: () => _choose(dialogContext, const Locale('en')),
            ),
            _LanguageOption(
              label: l10n.languageOptionKannada,
              selected: current == const Locale('kn'),
              onSelected: () => _choose(dialogContext, const Locale('kn')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(BuildContext dialogContext, Locale? locale) async {
    await controller.setLocale(locale);
    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onSelected,
      child: Semantics(
        selected: selected,
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: selected
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
