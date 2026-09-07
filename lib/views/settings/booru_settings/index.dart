import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/views/settings/index.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BooruSettings extends StatefulWidget {
    const BooruSettings({super.key, required this.prefs, required this.booru});

    final SharedPreferences prefs;
    final Booru booru;

    @override
    State<BooruSettings> createState() => _BooruSettingsState();
}

class _BooruSettingsState extends State<BooruSettings> {
    late Future<List<bool>> _hideMedia;

    void setHideMedia() {
        _hideMedia = Future.wait([
            File(p.join(widget.booru.path, 'files', '.nomedia')).exists(),
            File(p.join(widget.booru.path, 'thumbnails', '.nomedia')).exists(),
        ]);
    }

    Future<void> _changeHideMedia(bool value) async {
        final nomediaFiles = File(p.join(widget.booru.path, 'files', '.nomedia'));
        final nomediaThumbnails = File(p.join(widget.booru.path, 'thumbnails', '.nomedia'));

        if (value) {
            await nomediaFiles.create();
            await nomediaThumbnails.create();
        } else {
            if (await nomediaFiles.exists()) await nomediaFiles.delete();
            if (await nomediaThumbnails.exists()) await nomediaThumbnails.delete();
        }

        if (!mounted) return;
        setState(setHideMedia);
    }

    @override
    void initState() {
        super.initState();
        setHideMedia();
    }

    @override
    Widget build(BuildContext context) {
        return ListView(
            padding: EdgeInsets.zero,
            children: [
                ClassicPanel(
                    title: 'Current booru',
                    headerIcon: const ClassicCustomIcon('booru_settings', size: 19),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            const Text(
                                'Collection-specific settings',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                                'Manage tag classifications, collections and maintenance options for the currently open LocalBooru collection.',
                                style: TextStyle(fontSize: 11.5, height: 1.35, color: ClassicPalette.muted),
                            ),
                            const SizedBox(height: 10),
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFDCE7D8),
                                    border: Border.all(color: ClassicPalette.border),
                                ),
                                child: Text.rich(
                                    TextSpan(
                                        style: const TextStyle(fontSize: 11, color: ClassicPalette.ink),
                                        children: [
                                            const TextSpan(text: 'Current booru path: ', style: TextStyle(fontWeight: FontWeight.w700)),
                                            TextSpan(text: widget.booru.path),
                                        ],
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
                const SizedBox(height: 12),
                ClassicPanel(
                    title: 'Elements',
                    headerIcon: const ClassicSpriteIcon(index: 45, size: 19),
                    padding: EdgeInsets.zero,
                    child: Column(
                        children: [
                            ClassicSettingsOptionRow(
                                leading: const ClassicSpriteIcon(index: 45, size: 22),
                                title: 'Tag types',
                                subtitle: 'Remove or create tag types',
                                onTap: () => context.go('/settings/booru/tag_types'),
                            ),
                            const Divider(height: 1, color: ClassicPalette.border),
                            ClassicSettingsOptionRow(
                                leading: const ClassicSpriteIcon(index: 28, size: 22),
                                title: 'Collections',
                                subtitle: 'Manage existing collections',
                                onTap: () => context.go('/settings/booru/collections'),
                            ),
                        ],
                    ),
                ),
                const SizedBox(height: 12),
                ClassicPanel(
                    title: 'Maintenance',
                    headerIcon: const ClassicSpriteIcon(index: 38, size: 19),
                    padding: EdgeInsets.zero,
                    child: Column(
                        children: [
                            ClassicSettingsOptionRow(
                                leading: const ClassicSpriteIcon(index: 38, size: 22),
                                title: 'Rebase',
                                subtitle: 'Reconstruct certain collection metadata if something appears inconsistent',
                                onTap: () async {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rebasing...')));
                                    final raw = await widget.booru.rebaseRaw();
                                    await writeSettings(widget.booru.path, raw);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rebased')));
                                },
                            ),
                            const Divider(height: 1, color: ClassicPalette.border),
                            FutureBuilder<List<bool>>(
                                future: _hideMedia,
                                builder: (context, snapshot) {
                                    final ready = snapshot.hasData;
                                    final value = ready && snapshot.data!.every((entry) => entry);
                                    return ClassicSettingsOptionRow(
                                        leading: const ClassicSpriteIcon(index: 18, size: 22),
                                        title: 'Hide images from gallery',
                                        subtitle: 'Add .nomedia markers to LocalBooru artwork and thumbnail folders',
                                        onTap: ready ? () => _changeHideMedia(!value) : null,
                                        trailing: Checkbox(
                                            value: value,
                                            onChanged: ready
                                                ? (newValue) {
                                                    if (newValue != null) _changeHideMedia(newValue);
                                                }
                                                : null,
                                        ),
                                    );
                                },
                            ),
                            const Divider(height: 1, color: ClassicPalette.border),
                            ClassicSettingsOptionRow(
                                leading: Image.asset(
                                    'assets/classic_deviantart/custom/syncthing.png',
                                    width: 24,
                                    height: 24,
                                    filterQuality: FilterQuality.medium,
                                    isAntiAlias: true,
                                ),
                                title: 'Syncing',
                                subtitle: 'LocalBooru has no built-in sync service; Syncthing can synchronize the collection folder between your devices',
                                trailing: const ClassicSpriteIcon(index: 16, size: 17),
                                onTap: () => launchUrlString('https://syncthing.net/'),
                            ),
                        ],
                    ),
                ),
                const SizedBox(height: 12),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF4CE),
                        border: Border.all(color: const Color(0xFFC4A653)),
                        borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                        'These options affect only the currently selected booru. Application-wide behavior remains under All settings.',
                        style: TextStyle(fontSize: 11, height: 1.25, color: Color(0xFF765D21)),
                    ),
                ),
                const SizedBox(height: 28),
            ],
        );
    }
}
