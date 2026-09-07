import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/update_checker.dart';

class SettingsShell extends StatelessWidget {
    const SettingsShell({super.key, required this.child, required this.routeUri});

    final Widget child;
    final Uri routeUri;

    String get _pageTitle {
        final path = routeUri.path;
        if (path.startsWith('/settings/booru/tag_types')) return 'Tag types';
        if (path.startsWith('/settings/booru/collections')) return 'Collections';
        if (path == '/settings/booru') return 'Current booru settings';
        if (path == '/settings/change_booru') return 'Change booru';
        if (path.startsWith('/settings/overall_settings')) return 'Overall settings';
        return 'All settings';
    }

    Widget get _pageIcon {
        final path = routeUri.path;
        if (path.startsWith('/settings/booru/tag_types')) {
            return const ClassicSpriteIcon(index: 45, size: 19);
        }
        if (path.startsWith('/settings/booru/collections')) {
            return const ClassicSpriteIcon(index: 28, size: 19);
        }
        if (path == '/settings/booru') {
            return const ClassicCustomIcon('booru_settings', size: 19);
        }
        if (path == '/settings/change_booru') {
            return Image.asset(
                'assets/classic_deviantart/custom/select_booru_folder.png',
                width: 19,
                height: 19,
                filterQuality: FilterQuality.medium,
                isAntiAlias: true,
            );
        }
        if (path.startsWith('/settings/overall_settings')) {
            return const ClassicCustomIcon('settings', size: 19);
        }
        return const ClassicCustomIcon('settings', size: 19);
    }

    String? get _backLabel {
        final path = routeUri.path;
        if (path == '/settings') return null;
        if (path.startsWith('/settings/booru/tag_types') || path.startsWith('/settings/booru/collections')) {
            return 'Back to Current booru settings';
        }
        return 'Back to Settings';
    }

    void _goBack(BuildContext context) {
        final path = routeUri.path;
        if (path.startsWith('/settings/booru/tag_types') || path.startsWith('/settings/booru/collections')) {
            context.go('/settings/booru');
        } else if (path != '/settings') {
            context.go('/settings');
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: ClassicPalette.page,
            body: Column(
                children: [
                    Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: const BoxDecoration(
                            color: ClassicPalette.panelAlt,
                            border: Border(bottom: BorderSide(color: ClassicPalette.border)),
                        ),
                        child: Row(
                            children: [
                                ClassicSafeBackButton(routeUri: routeUri, fallback: '/home'),
                                const SizedBox(width: 3),
                                _pageIcon,
                                const SizedBox(width: 8),
                                Text(_pageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const Spacer(),
                                if (_backLabel != null)
                                    ClassicLink(
                                        _backLabel!,
                                        bold: true,
                                        onTap: () => _goBack(context),
                                    ),
                            ],
                        ),
                    ),
                    Expanded(
                        child: LayoutBuilder(
                            builder: (context, constraints) {
                                final compact = constraints.maxWidth < 760;
                                final navigation = _SettingsNavigation(routeUri: routeUri);

                                return Padding(
                                    padding: EdgeInsets.fromLTRB(compact ? 10 : 24, 20, compact ? 10 : 24, 22),
                                    child: Center(
                                        child: ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 1180),
                                            child: compact
                                                ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: [
                                                        navigation,
                                                        const SizedBox(height: 12),
                                                        Expanded(child: child),
                                                    ],
                                                )
                                                : Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        SizedBox(width: 205, child: navigation),
                                                        const SizedBox(width: 18),
                                                        Expanded(child: child),
                                                    ],
                                                ),
                                        ),
                                    ),
                                );
                            },
                        ),
                    ),
                ],
            ),
        );
    }
}

class _SettingsNavigation extends StatelessWidget {
    const _SettingsNavigation({required this.routeUri});

    final Uri routeUri;

    bool get _currentBooruActive => routeUri.path.startsWith('/settings/booru');
    bool get _changeBooruActive => routeUri.path == '/settings/change_booru';
    bool get _allSettingsActive => !_currentBooruActive && !_changeBooruActive;

    Widget _heading(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ClassicPalette.ink),
        ),
    );

    Widget _entry(String text, {bool active = false, VoidCallback? onTap}) {
        return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(3),
            child: Container(
                constraints: const BoxConstraints(minHeight: 30),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF7D9EAA), Color(0xFF5D8492)],
                        )
                        : null,
                    border: active ? Border.all(color: const Color(0xFF4E737F)) : null,
                    borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                    text,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? Colors.white : ClassicPalette.ink,
                    ),
                ),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.fromLTRB(6, 7, 6, 9),
            decoration: BoxDecoration(
                color: const Color(0xFFD7E2D4),
                border: Border.all(color: ClassicPalette.border),
                borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    const Padding(
                        padding: EdgeInsets.fromLTRB(8, 3, 8, 5),
                        child: Text('Settings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                    _heading('Collection'),
                    _entry(
                        'Current booru settings',
                        active: _currentBooruActive,
                        onTap: _currentBooruActive ? null : () => context.go('/settings/booru'),
                    ),
                    _entry(
                        'Change booru',
                        active: _changeBooruActive,
                        onTap: _changeBooruActive ? null : () => context.go('/settings/change_booru'),
                    ),
                    _heading('Application'),
                    _entry(
                        'All settings',
                        active: _allSettingsActive,
                        onTap: routeUri.path == '/settings' ? null : () => context.go('/settings'),
                    ),
                ],
            ),
        );
    }
}

class SettingsHome extends StatelessWidget {
    const SettingsHome({super.key});

    @override
    Widget build(BuildContext context) {
        return ListView(
            padding: EdgeInsets.zero,
            children: [
                ClassicPanel(
                    title: 'LocalBooru Settings',
                    headerIcon: const ClassicCustomIcon('settings', size: 19),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                    child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                'Manage your local collection',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 4),
                            Text(
                                'Collection-specific tools and application-wide preferences are grouped below, using the same compact settings layout as the Change booru screen.',
                                style: TextStyle(fontSize: 11.5, height: 1.35, color: ClassicPalette.muted),
                            ),
                        ],
                    ),
                ),
                const SizedBox(height: 12),
                ClassicPanel(
                    title: 'Collection',
                    headerIcon: const ClassicSpriteIcon(index: 28, size: 19),
                    padding: EdgeInsets.zero,
                    child: Column(
                        children: [
                            ClassicSettingsOptionRow(
                                leading: const ClassicCustomIcon('booru_settings', size: 22),
                                title: 'Current booru settings',
                                subtitle: 'Tags, collections and library-specific options',
                                onTap: () => context.go('/settings/booru'),
                            ),
                            const Divider(height: 1, color: ClassicPalette.border),
                            ClassicSettingsOptionRow(
                                leading: Image.asset(
                                    'assets/classic_deviantart/custom/select_booru_folder.png',
                                    width: 22,
                                    height: 22,
                                    filterQuality: FilterQuality.medium,
                                    isAntiAlias: true,
                                ),
                                title: 'Change booru',
                                subtitle: 'Create or open a different local collection',
                                onTap: () => context.go('/settings/change_booru'),
                            ),
                        ],
                    ),
                ),
                const SizedBox(height: 12),
                ClassicPanel(
                    title: 'Application',
                    headerIcon: const ClassicCustomIcon('settings', size: 19),
                    padding: EdgeInsets.zero,
                    child: Column(
                        children: [
                            ClassicSettingsOptionRow(
                                leading: const ClassicCustomIcon('settings', size: 22),
                                title: 'Overall settings',
                                subtitle: 'Grid, playback, privacy and program behavior',
                                onTap: () => context.go('/settings/overall_settings'),
                            ),
                            const Divider(height: 1, color: ClassicPalette.border),
                            ClassicSettingsOptionRow(
                                leading: const ClassicSpriteIcon(index: 38, size: 22),
                                title: 'Check for updates',
                                subtitle: 'Check whether a newer LocalBooru build is available',
                                onTap: () async {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checking for updates...')));
                                    final ver = await checkForUpdates();
                                    if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    if (!(await ver.isCurrentLatest())) {
                                        if (!context.mounted) return;
                                        showDialog(context: context, builder: (context) => UpdateAvaiableDialog(ver: ver));
                                    } else {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You're on the latest version")));
                                    }
                                },
                            ),
                            const Divider(height: 1, color: ClassicPalette.border),
                            ClassicSettingsOptionRow(
                                leading: const ClassicSpriteIcon(index: 14, size: 22),
                                title: 'About LocalBooru',
                                subtitle: 'Version information, project links and interface notes',
                                onTap: () => context.go('/about'),
                            ),
                        ],
                    ),
                ),
                const SizedBox(height: 28),
            ],
        );
    }
}

class ClassicSettingsOptionRow extends StatelessWidget {
    const ClassicSettingsOptionRow({
        super.key,
        required this.leading,
        required this.title,
        this.subtitle,
        this.trailing,
        this.onTap,
    });

    final Widget leading;
    final String title;
    final String? subtitle;
    final Widget? trailing;
    final VoidCallback? onTap;

    @override
    Widget build(BuildContext context) {
        return InkWell(
            onTap: onTap,
            child: Container(
                constraints: const BoxConstraints(minHeight: 54),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                color: ClassicPalette.panel,
                child: Row(
                    children: [
                        SizedBox(width: 34, child: Align(alignment: Alignment.centerLeft, child: leading)),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                    if (subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                            subtitle!,
                                            style: const TextStyle(fontSize: 11, height: 1.2, color: ClassicPalette.muted),
                                        ),
                                    ],
                                ],
                            ),
                        ),
                        const SizedBox(width: 10),
                        trailing ?? const ClassicNavArrow.right(size: 13),
                    ],
                ),
            ),
        );
    }
}
