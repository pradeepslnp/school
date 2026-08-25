import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../domain/permission_matrix.dart';

/// A-44 — Roles & permissions: a read-only view of the nine system roles and what each may
/// do, sourced from `PERMISSION_MATRIX.md`.
///
/// **Deliberately read-only** (decision #3 in the Super Admin build plan). The permission set
/// for a system role is fixed in code (`SystemRolePermissions.java`), not stored per tenant —
/// that is an existing, documented design choice, not a gap this screen works around. A
/// screen that lets an operator *build* a custom role is real work, tracked as future work
/// rather than silently promised by this one's presence in the nav.
class RoleReferenceScreen extends StatefulWidget {
  const RoleReferenceScreen({super.key});

  @override
  State<RoleReferenceScreen> createState() => _RoleReferenceScreenState();
}

class _RoleReferenceScreenState extends State<RoleReferenceScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _roleFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<PermissionCategory> get _filtered {
    final query = _query.trim().toLowerCase();
    final roleFilter = _roleFilter;

    return [
      for (final category in kPermissionMatrix)
        PermissionCategory(
          title: category.title,
          permissions: [
            for (final row in category.permissions)
              if ((query.isEmpty ||
                      row.id.toLowerCase().contains(query) ||
                      category.title.toLowerCase().contains(query)) &&
                  (roleFilter == null || row.grants[roleFilter] != PermissionGrant.none))
                row,
          ],
        ),
    ].where((category) => category.permissions.isNotEmpty).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _filtered;

    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Roles & permissions', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AdminSpacing.xs),
          Text(
            'What each system role can do, straight from the permission matrix this platform '
            'enforces server-side on every request. Reference only — roles cannot be edited '
            'here yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AdminSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('role_reference_search_field'),
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    labelText: 'Search',
                    hintText: 'Filter by permission ID or category',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Clear search',
                            onPressed: () => setState(() {
                              _search.clear();
                              _query = '';
                            }),
                          ),
                    border: const OutlineInputBorder(),
                    constraints: const BoxConstraints(minHeight: kAdminTouchTarget),
                  ),
                ),
              ),
              const SizedBox(width: AdminSpacing.md),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: const Key('role_reference_role_filter_field'),
                  initialValue: _roleFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    constraints: BoxConstraints(minHeight: kAdminTouchTarget),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Every role')),
                    for (final role in kSystemRoleCodes)
                      DropdownMenuItem<String?>(value: role, child: Text(roleDisplayName(role))),
                  ],
                  onChanged: (value) => setState(() => _roleFilter = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.lg),
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      'No permission matches this search.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    // Vertical only, at this level — each category scrolls itself
                    // horizontally (see `_CategorySection`), rather than nesting a second
                    // scroll direction around the whole list. A Column under an unbounded
                    // horizontal extent cannot stretch its cards to a width that does not
                    // exist, which is exactly what a horizontal wrapper here would ask it
                    // to do.
                    key: const Key('role_reference_scroll'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final category in categories) ...[
                          _CategorySection(category: category, roleFilter: _roleFilter),
                          const SizedBox(height: AdminSpacing.lg),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.roleFilter});

  final PermissionCategory category;
  final String? roleFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles = roleFilter == null ? kSystemRoleCodes : [roleFilter!];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminSpacing.sm),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(category.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AdminSpacing.sm),
            // Horizontal scroll around the table alone, not the whole screen: up to nine
            // role columns plus a wide permission-name column comfortably exceed a narrow
            // window's width, and this keeps the overflow local to the one thing that is
            // actually wide.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                0: const FixedColumnWidth(260),
                for (var i = 0; i < roles.length; i++) i + 1: const FixedColumnWidth(88),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
                  ),
                  children: [
                    const Padding(padding: EdgeInsets.all(AdminSpacing.xs), child: SizedBox()),
                    for (final role in roles)
                      Padding(
                        padding: const EdgeInsets.all(AdminSpacing.xs),
                        child: Text(
                          roleShortLabel(role),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
                for (final row in category.permissions)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AdminSpacing.xs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(row.id, style: theme.textTheme.bodySmall),
                            if (row.note != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  row.note!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      for (final role in roles)
                        Padding(
                          padding: const EdgeInsets.all(AdminSpacing.xs),
                          child: Center(child: _GrantMark(grant: row.grants[role])),
                        ),
                    ],
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

class _GrantMark extends StatelessWidget {
  const _GrantMark({required this.grant});

  final PermissionGrant? grant;

  @override
  Widget build(BuildContext context) {
    final resolved = grant ?? PermissionGrant.none;
    return switch (resolved) {
      PermissionGrant.none => Text('—', style: TextStyle(color: context.status.warning)),
      PermissionGrant.full => Icon(Icons.check, size: 18, color: context.status.safe),
      PermissionGrant.narrower => Tooltip(
          message: 'Granted, narrowed to a smaller scope than this role normally has',
          child: Icon(Icons.check_circle_outline, size: 18, color: context.status.safe),
        ),
    };
  }
}
