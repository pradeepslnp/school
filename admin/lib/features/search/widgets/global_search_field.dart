import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../bloc/global_search_bloc.dart';
import '../bloc/global_search_event.dart';
import '../bloc/global_search_state.dart';
import '../domain/search_models.dart';

/// The console header's search field and its results panel (SRC-001, ADMIN_WEB.md §Global
/// Search).
///
/// Renders [GlobalSearchState] and reports what the operator typed and chose. What lives here is
/// presentation state only: the typing pause before a search is sent, which row the keyboard has
/// highlighted, and whether the panel is open.
///
/// **Keyboard-first**, per ADMIN_WEB.md's design brief: ⌘K / Ctrl+K focuses the field from anywhere
/// in the console, the arrow keys move through results, Enter opens the highlighted one, and Escape
/// clears the query, then closes.
class GlobalSearchField extends StatefulWidget {
  const GlobalSearchField({super.key, required this.onSelected});

  final ValueChanged<SearchHit> onSelected;

  @override
  State<GlobalSearchField> createState() => _GlobalSearchFieldState();
}

class _GlobalSearchFieldState extends State<GlobalSearchField> {
  /// A pause before searching, so a name typed at an ordinary pace sends one request — and records
  /// one set of student reads (BR-IAM-012) — rather than one per keystroke.
  static const Duration _debounce = Duration(milliseconds: 300);

  final _controller = TextEditingController();
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'globalSearch',
    onKeyEvent: _onKeyEvent,
  );

  Timer? _pending;
  int _highlighted = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    HardwareKeyboard.instance.addHandler(_onShortcut);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onShortcut);
    _pending?.cancel();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _onShortcut(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyK) return false;
    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isMetaPressed && !keyboard.isControlPressed) return false;

    _focusNode.requestFocus();
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    return true;
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _portal.show();
    } else {
      _portal.hide();
    }
  }

  void _onChanged(String value) {
    _pending?.cancel();
    if (_highlighted != 0) setState(() => _highlighted = 0);
    _pending = Timer(_debounce, () {
      if (!mounted) return;
      context.read<GlobalSearchBloc>().add(GlobalSearchQueryChanged(value));
    });
  }

  List<SearchHit> _visibleHits() {
    final results = context.read<GlobalSearchBloc>().state.results;
    return results?.groups.expand((group) => group.hits).toList() ?? const [];
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_controller.text.isEmpty) {
        node.unfocus();
      } else {
        _clear();
      }
      return KeyEventResult.handled;
    }

    final hits = _visibleHits();
    if (hits.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _highlighted = (_highlighted + 1) % hits.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _highlighted = (_highlighted - 1 + hits.length) % hits.length);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _submit() {
    final hits = _visibleHits();
    if (hits.isEmpty) return;
    _select(hits[_highlighted.clamp(0, hits.length - 1)]);
  }

  void _select(SearchHit hit) {
    _focusNode.unfocus();
    widget.onSelected(hit);
  }

  void _clear() {
    _pending?.cancel();
    _controller.clear();
    setState(() => _highlighted = 0);
    context.read<GlobalSearchBloc>().add(const GlobalSearchCleared());
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildPanel,
      child: CompositedTransformTarget(link: _link, child: _buildField(context)),
    );
  }

  Widget _buildField(BuildContext context) {
    final theme = Theme.of(context);
    final livery = context.livery;
    final l10n = context.l10n;
    final shortcut = defaultTargetPlatform == TargetPlatform.macOS
        ? l10n.globalSearchShortcutMac
        : l10n.globalSearchShortcutOther;
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: livery.border),
    );

    return TextField(
      key: const Key('global_search_field'),
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onChanged,
      onSubmitted: (_) => _submit(),
      onTapOutside: (_) => _focusNode.unfocus(),
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: l10n.globalSearchHint,
        isDense: true,
        filled: true,
        fillColor: livery.panelSubtle,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => value.text.isEmpty
              ? _ShortcutHint(label: shortcut)
              : IconButton(
                  key: const Key('global_search_clear_button'),
                  tooltip: l10n.globalSearchClearTooltip,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clear,
                ),
        ),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
        constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final width = (_link.leaderSize?.width ?? 480).clamp(420.0, 640.0);

    return CompositedTransformFollower(
      link: _link,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, AdminSpacing.sm),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        // Taps inside the panel are not "outside" the field — without this, clicking a result
        // would unfocus the field and close the panel before the tap landed.
        child: TextFieldTapRegion(
          child: SizedBox(
            width: width,
            child: BlocBuilder<GlobalSearchBloc, GlobalSearchState>(
              builder: (context, state) => _ResultsPanel(
                state: state,
                highlighted: _highlighted,
                onSelected: _select,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The ⌘K / Ctrl K legend inside the empty field — how to get here without the mouse.
class _ShortcutHint extends StatelessWidget {
  const _ShortcutHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final livery = context.livery;

    return ExcludeSemantics(
      child: Center(
        widthFactor: 1,
        child: Container(
          margin: const EdgeInsetsDirectional.only(end: AdminSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: livery.panel,
            border: Border.all(color: livery.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    required this.state,
    required this.highlighted,
    required this.onSelected,
  });

  final GlobalSearchState state;
  final int highlighted;
  final ValueChanged<SearchHit> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final livery = context.livery;
    final results = state.results;
    final rows = <Widget>[];

    switch (state.status) {
      case GlobalSearchStatus.idle:
      case GlobalSearchStatus.loading:
        break;
      case GlobalSearchStatus.tooShort:
        rows.add(_Notice(icon: Icons.keyboard_outlined, message: l10n.globalSearchMinLength));
      case GlobalSearchStatus.failed:
        rows.add(_Notice(icon: Icons.cloud_off_outlined, message: l10n.globalSearchError));
      case GlobalSearchStatus.ready:
        if (results == null || results.isEmpty) {
          rows.add(_Notice(icon: Icons.search_off, message: l10n.globalSearchNoResults(state.query)));
        }
    }

    final showResults = state.status == GlobalSearchStatus.ready ||
        state.status == GlobalSearchStatus.loading;
    if (results != null && showResults) {
      var position = 0;
      for (final group in results.groups) {
        rows.add(_GroupHeader(label: _groupLabel(l10n, group.type)));
        for (final hit in group.hits) {
          final index = position++;
          rows.add(_HitRow(
            hit: hit,
            highlighted: index == highlighted,
            onTap: () => onSelected(hit),
          ));
        }
        if (group.hasMore) rows.add(_MoreHint(label: l10n.globalSearchMoreResults));
      }
    }

    final loading = state.status == GlobalSearchStatus.loading;
    if (rows.isEmpty && !loading) return const SizedBox.shrink();

    return Material(
      color: livery.panel,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: livery.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loading)
              LinearProgressIndicator(minHeight: 2, semanticsLabel: l10n.globalSearchLoading),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xs),
                children: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.md,
          vertical: AdminSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: muted),
            const SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: Text(message, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AdminSpacing.md,
          AdminSpacing.sm,
          AdminSpacing.md,
          AdminSpacing.xs,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MoreHint extends StatelessWidget {
  const _MoreHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Aligned with the row titles above, past the leading icon.
      padding: const EdgeInsetsDirectional.fromSTEB(64, 0, AdminSpacing.md, AdminSpacing.sm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.livery.placeholder),
      ),
    );
  }
}

class _HitRow extends StatelessWidget {
  const _HitRow({required this.hit, required this.highlighted, required this.onTap});

  final SearchHit hit;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final livery = context.livery;
    final (title, subtitle) = _presentation(context.l10n, hit);

    return InkWell(
      key: Key('global_search_hit_${hit.type.name}_${hit.id}'),
      onTap: onTap,
      child: Container(
        color: highlighted ? scheme.primaryContainer.withValues(alpha: 0.6) : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.md,
          vertical: AdminSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: livery.panelSubtle,
                shape: BoxShape.circle,
                border: Border.all(color: livery.border),
              ),
              child: Icon(_iconFor(hit.type), size: 18, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A result's two lines.
///
/// The title is what the operator typed: a name when a name matched, otherwise the number or code
/// itself. The subtitle says where it is from — what kind of record, whose it is when a number
/// matched, the school or child it belongs to, and, on a platform operator's search across
/// organizations, which organization.
(String, String) _presentation(AppLocalizations l10n, SearchHit hit) {
  final title = hit.matchedByName ? hit.title : hit.matchedValue;
  final schoolName = hit.schoolName;
  final code = hit.code;
  final childName = hit.relatedStudentName;
  final organizationName = hit.organizationName;

  final parts = <String>[
    _kindLabel(l10n, hit),
    if (!hit.matchedByName) hit.title,
    ...switch (hit.type) {
      SearchResultType.student => [
          if (code != null && hit.matchedField != SearchMatchedField.admissionNo)
            l10n.globalSearchAdmissionNumber(code),
          if (schoolName != null) schoolName,
        ],
      SearchResultType.guardian => [
          if (childName != null) l10n.globalSearchLinkedChild(childName),
        ],
      SearchResultType.vehicle => [
          if (code != null && hit.matchedField != SearchMatchedField.registrationNo) code,
          if (schoolName != null) schoolName,
        ],
      SearchResultType.staff || SearchResultType.route || SearchResultType.user => [
          if (schoolName != null) schoolName,
        ],
      SearchResultType.school || SearchResultType.organization => [
          if (code != null && hit.matchedField != SearchMatchedField.code) code,
        ],
      SearchResultType.unknown => const <String>[],
    },
    if (organizationName != null) organizationName,
  ];

  return (title, parts.join(l10n.globalSearchSubtitleSeparator));
}

String _kindLabel(AppLocalizations l10n, SearchHit hit) => switch (hit.type) {
      SearchResultType.student => l10n.globalSearchKindStudent,
      SearchResultType.guardian => l10n.globalSearchKindGuardian,
      SearchResultType.staff => hit.kind == 'ATTENDANT'
          ? l10n.globalSearchKindAttendant
          : l10n.globalSearchKindDriver,
      SearchResultType.vehicle => l10n.globalSearchKindVehicle,
      SearchResultType.route => l10n.globalSearchKindRoute,
      SearchResultType.user => l10n.globalSearchKindUser,
      SearchResultType.school => l10n.globalSearchKindSchool,
      SearchResultType.organization => l10n.globalSearchKindOrganization,
      SearchResultType.unknown => '',
    };

String _groupLabel(AppLocalizations l10n, SearchResultType type) => switch (type) {
      SearchResultType.student => l10n.globalSearchGroupStudents,
      SearchResultType.guardian => l10n.globalSearchGroupGuardians,
      SearchResultType.staff => l10n.globalSearchGroupStaff,
      SearchResultType.vehicle => l10n.globalSearchGroupVehicles,
      SearchResultType.route => l10n.globalSearchGroupRoutes,
      SearchResultType.user => l10n.globalSearchGroupUsers,
      SearchResultType.school => l10n.globalSearchGroupSchools,
      SearchResultType.organization => l10n.globalSearchGroupOrganizations,
      SearchResultType.unknown => '',
    };

IconData _iconFor(SearchResultType type) => switch (type) {
      SearchResultType.student => Icons.person_outline,
      SearchResultType.guardian => Icons.family_restroom,
      SearchResultType.staff => Icons.badge_outlined,
      SearchResultType.vehicle => Icons.directions_bus_outlined,
      SearchResultType.route => Icons.alt_route,
      SearchResultType.user => Icons.manage_accounts_outlined,
      SearchResultType.school => Icons.school_outlined,
      SearchResultType.organization => Icons.apartment_outlined,
      SearchResultType.unknown => Icons.search,
    };
