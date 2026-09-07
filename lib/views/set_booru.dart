import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class SetBooruScreen extends StatelessWidget {
    const SetBooruScreen({super.key});

    static const _folderIcon = 'assets/classic_deviantart/custom/select_booru_folder.png';
    static const _homeIcon = 'assets/classic_deviantart/custom/create_booru_home.png';

    Future<void> _showError(BuildContext context, String title, String message) async {
        if (!context.mounted) return;
        await showDialog<void>(
            context: context,
            builder: (dialogContext) => ClassicDialogFrame(
                title: title,
                icon: const ClassicSpriteIcon(index: 14, size: 19),
                child: Text(message, style: const TextStyle(fontSize: 12, height: 1.35)),
                actions: [
                    ClassicBevelButton(
                        label: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                ],
            ),
        );
    }

    Future<void> _selectExisting(BuildContext context) async {
        final String? output = await FilePicker.platform.getDirectoryPath();
        if (output == null) return;

        final File repoinfo = File(p.join(output, 'repoinfo.json'));
        final Directory files = Directory(p.join(output, 'files'));

        if (!(await repoinfo.exists()) || !(await files.exists())) {
            await _showError(
                context,
                'That folder is not a LocalBooru collection',
                'The selected folder must contain both repoinfo.json and a files folder. No collection was changed.',
            );
            return;
        }

        try {
            final String rawText = await repoinfo.readAsString();
            final dynamic decoded = jsonDecode(rawText);
            if (decoded is! Map<String, dynamic> || !isValidBooruModel(decoded)) {
                throw const FormatException('Missing required LocalBooru properties');
            }
        } catch (_) {
            await _showError(
                context,
                'repoinfo.json could not be read',
                'The selected collection metadata is missing required fields or contains invalid JSON. The active collection was left unchanged.',
            );
            return;
        }

        await setBooru(output);
        if (context.mounted) context.go('/home');
    }

    Future<void> _createNew(BuildContext context) async {
        final String? output = await FilePicker.platform.getDirectoryPath();
        if (output == null) return;

        final File repoinfo = File(p.join(output, 'repoinfo.json'));
        final Directory files = Directory(p.join(output, 'files'));

        if (await repoinfo.exists() || await files.exists()) {
            await _showError(
                context,
                'This folder already looks like a collection',
                'Use “Select an already existing booru” if you want to open this folder. To create a new collection, choose a folder that does not already contain LocalBooru metadata.',
            );
            return;
        }

        try {
            await createDefaultBooruModel(output);
            await setBooru(output);
        } catch (error) {
            await _showError(
                context,
                'Could not create the collection',
                'LocalBooru could not initialize the selected folder. Check that the folder is writable and try again.\n\n$error',
            );
            return;
        }

        if (context.mounted) context.go('/home');
    }

    @override
    Widget build(BuildContext context) {
        return SharedPreferencesBuilder(
            loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
            builder: (context, prefs) => _SetBooruPage(
                prefs: prefs,
                selectExisting: () => _selectExisting(context),
                createNew: () => _createNew(context),
            ),
        );
    }
}

/// Settings-hosted version of the booru picker. It reuses the exact same
/// validation and collection-switching logic as the standalone first-run
/// screen, but lets SettingsShell provide the normal LocalBooru masthead,
/// page header, sidebar width and content alignment.
class ChangeBooruSettingsScreen extends StatelessWidget {
    const ChangeBooruSettingsScreen({super.key});

    @override
    Widget build(BuildContext context) {
        final helper = const SetBooruScreen();
        return SharedPreferencesBuilder(
            loading: const Center(child: CircularProgressIndicator()),
            builder: (context, prefs) => ListView(
                padding: EdgeInsets.zero,
                children: [
                    _SetupContent(
                        currentPath: prefs.getString('booruPath'),
                        selectExisting: () => helper._selectExisting(context),
                        createNew: () => helper._createNew(context),
                    ),
                    const SizedBox(height: 28),
                ],
            ),
        );
    }
}

class _SetBooruPage extends StatelessWidget {
    const _SetBooruPage({
        required this.prefs,
        required this.selectExisting,
        required this.createNew,
    });

    final SharedPreferences prefs;
    final VoidCallback selectExisting;
    final VoidCallback createNew;

    bool get hasCurrentBooru => (prefs.getString('booruPath') ?? '').trim().isNotEmpty;

    @override
    Widget build(BuildContext context) {
        final currentPath = prefs.getString('booruPath');

        return Scaffold(
            backgroundColor: ClassicPalette.page,
            body: Column(
                children: [
                    _ClassicSetupMasthead(hasCurrentBooru: hasCurrentBooru),
                    _ClassicSetupPageHeader(showBack: hasCurrentBooru),
                    Expanded(
                        child: LayoutBuilder(
                            builder: (context, constraints) {
                                final compact = constraints.maxWidth < 760;
                                final navigation = _SetupNavigation(hasCurrentBooru: hasCurrentBooru);
                                final content = _SetupContent(
                                    currentPath: currentPath,
                                    selectExisting: selectExisting,
                                    createNew: createNew,
                                );

                                return SingleChildScrollView(
                                    padding: EdgeInsets.fromLTRB(compact ? 10 : 24, 20, compact ? 10 : 24, 22),
                                    child: Center(
                                        child: ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 1180),
                                            child: compact
                                                ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: [
                                                        navigation,
                                                        const SizedBox(height: 14),
                                                        content,
                                                    ],
                                                )
                                                : Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                        SizedBox(width: 205, child: navigation),
                                                        const SizedBox(width: 18),
                                                        Expanded(child: content),
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

class _ClassicSetupMasthead extends StatelessWidget {
    const _ClassicSetupMasthead({required this.hasCurrentBooru});

    final bool hasCurrentBooru;

    @override
    Widget build(BuildContext context) {
        return Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ClassicPalette.headerTop, ClassicPalette.headerBottom],
                ),
                border: Border(
                    top: BorderSide(color: Color(0xFF688073)),
                    bottom: BorderSide(color: ClassicPalette.headerBorder, width: 1.5),
                ),
            ),
            child: Row(
                children: [
                    Image.asset(
                        'assets/classic_deviantart/custom/localbooru_logo_2010.png',
                        width: 108,
                        height: 32,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        filterQuality: FilterQuality.medium,
                        isAntiAlias: true,
                    ),
                    const Spacer(),
                    Text(
                        hasCurrentBooru ? 'Collection Settings' : 'Local Collection Setup',
                        style: const TextStyle(
                            color: Color(0xFFD7E2DC),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            shadows: [Shadow(color: Color(0x99000000), offset: Offset(0, 1))],
                        ),
                    ),
                ],
            ),
        );
    }
}

class _ClassicSetupPageHeader extends StatelessWidget {
    const _ClassicSetupPageHeader({required this.showBack});

    final bool showBack;

    @override
    Widget build(BuildContext context) {
        return Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
                color: ClassicPalette.panelAlt,
                border: Border(bottom: BorderSide(color: ClassicPalette.border)),
            ),
            child: Row(
                children: [
                    if (showBack) ...[
                        ClassicSafeBackButton(fallback: '/settings'),
                        const SizedBox(width: 3),
                    ],
                    Image.asset(
                        SetBooruScreen._folderIcon,
                        width: 19,
                        height: 19,
                        filterQuality: FilterQuality.medium,
                        isAntiAlias: true,
                    ),
                    const SizedBox(width: 8),
                    const Text('Change booru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (showBack)
                        ClassicLink(
                            'Back to Settings',
                            bold: true,
                            onTap: () => classicSafeBack(context, fallback: '/settings'),
                        ),
                ],
            ),
        );
    }
}

class _SetupNavigation extends StatelessWidget {
    const _SetupNavigation({required this.hasCurrentBooru});

    final bool hasCurrentBooru;

    Widget _heading(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ClassicPalette.ink)),
    );

    Widget _entry(String text, {bool active = false, VoidCallback? onTap}) {
        return InkWell(
            onTap: onTap,
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
                    if (hasCurrentBooru)
                        _entry('Current booru settings', onTap: () => context.go('/settings/booru')),
                    _entry('Change booru', active: true),
                    if (hasCurrentBooru) ...[
                        _heading('Application'),
                        _entry('All settings', onTap: () => context.go('/settings')),
                    ],
                ],
            ),
        );
    }
}

class _SetupContent extends StatelessWidget {
    const _SetupContent({
        required this.currentPath,
        required this.selectExisting,
        required this.createNew,
    });

    final String? currentPath;
    final VoidCallback selectExisting;
    final VoidCallback createNew;

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                ClassicPanel(
                    title: 'Choose your local collection',
                    headerIcon: Image.asset(
                        SetBooruScreen._folderIcon,
                        width: 18,
                        height: 18,
                        filterQuality: FilterQuality.medium,
                        isAntiAlias: true,
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            const Text(
                                'Where should LocalBooru keep your art?',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                                'Open an existing LocalBooru collection or create a fresh one in a folder of your choice. Everything stays on your computer.',
                                style: TextStyle(fontSize: 11.5, height: 1.35, color: ClassicPalette.muted),
                            ),
                            if ((currentPath ?? '').isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFDCE7D8),
                                        border: Border.all(color: ClassicPalette.border),
                                    ),
                                    child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            const ClassicSpriteIcon(index: 14, size: 16),
                                            const SizedBox(width: 7),
                                            Expanded(
                                                child: Text.rich(
                                                    TextSpan(
                                                        style: const TextStyle(fontSize: 11, color: ClassicPalette.ink),
                                                        children: [
                                                            const TextSpan(text: 'Current booru: ', style: TextStyle(fontWeight: FontWeight.w700)),
                                                            TextSpan(text: currentPath),
                                                        ],
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                            ],
                            const SizedBox(height: 14),
                            _BooruChoiceRow(
                                title: 'Select an already existing booru',
                                description: 'Choose a folder that already contains repoinfo.json and the LocalBooru files directory.',
                                actionLabel: 'Select an already existing booru',
                                actionIcon: SetBooruScreen._folderIcon,
                                onPressed: selectExisting,
                            ),
                            const SizedBox(height: 10),
                            _BooruChoiceRow(
                                title: 'Create a new one',
                                description: 'Choose a new folder and LocalBooru will create the metadata, artwork and thumbnail directories it needs.',
                                actionLabel: 'Create a new one',
                                actionIcon: SetBooruScreen._homeIcon,
                                accent: true,
                                onPressed: createNew,
                            ),
                        ],
                    ),
                ),
                const SizedBox(height: 12),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF2EDCF),
                        border: Border.all(color: const Color(0xFFC8B96B)),
                        borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                        'Changing the active booru does not move, upload, or delete artwork. It only tells LocalBooru which local collection folder to open.',
                        style: TextStyle(fontSize: 11, height: 1.3, color: Color(0xFF6D5A20)),
                    ),
                ),
            ],
        );
    }
}

class _BooruChoiceRow extends StatelessWidget {
    const _BooruChoiceRow({
        required this.title,
        required this.description,
        required this.actionLabel,
        required this.actionIcon,
        required this.onPressed,
        this.accent = false,
    });

    final String title;
    final String description;
    final String actionLabel;
    final String actionIcon;
    final VoidCallback onPressed;
    final bool accent;

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F5EE),
                border: Border.all(color: ClassicPalette.border),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [BoxShadow(color: Colors.white70, offset: Offset(0, 1), blurRadius: 0)],
            ),
            child: LayoutBuilder(
                builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 590;
                    final copy = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(description, style: const TextStyle(fontSize: 10.8, height: 1.3, color: ClassicPalette.muted)),
                        ],
                    );
                    final button = ClassicBevelButton(
                        label: actionLabel,
                        accent: accent,
                        leading: Image.asset(
                            actionIcon,
                            width: 17,
                            height: 17,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            isAntiAlias: true,
                        ),
                        onPressed: onPressed,
                    );

                    if (narrow) {
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                copy,
                                const SizedBox(height: 9),
                                button,
                            ],
                        );
                    }

                    return Row(
                        children: [
                            Expanded(child: copy),
                            const SizedBox(width: 14),
                            button,
                        ],
                    );
                },
            ),
        );
    }
}
