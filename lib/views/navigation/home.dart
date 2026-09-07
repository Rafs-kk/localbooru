import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/counter.dart';
import 'package:localbooru/components/image_grid_display.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
    final TextEditingController _searchController = TextEditingController();
    late Future<Map<String, dynamic>> _homeFuture;

    @override
    void initState() {
        super.initState();
        _homeFuture = _loadHome();
        booruUpdateListener.addListener(_refresh);
    }

    @override
    void dispose() {
        booruUpdateListener.removeListener(_refresh);
        _searchController.dispose();
        super.dispose();
    }

    void _refresh() {
        if (!mounted) return;
        setState(() {
            _homeFuture = _loadHome();
        });
    }

    Future<Map<String, dynamic>> _loadHome() async {
        final booru = await getCurrentBooru();
        final prefs = await SharedPreferences.getInstance();

        // Load repoinfo.json once. The previous home page chained several
        // helpers that each reopened and reparsed the same file. On Windows,
        // immediately after a write, that could leave the landing page waiting
        // on a collection of redundant I/O futures while the dedicated Browse
        // route continued to work. Keeping this snapshot atomic also means the
        // counts, tags and recent images all describe the same repository state.
        final raw = await booru.getRawInfo().timeout(const Duration(seconds: 8));
        final rawFiles = (raw['files'] is List)
            ? List<Map<String, dynamic>>.from(raw['files'] as List)
            : <Map<String, dynamic>>[];

        final int pageSize = settingsDefaults['page_size'] as int;
        final recentRaw = rawFiles.reversed.take(pageSize);
        final images = <BooruImage>[];

        for (final file in recentRaw) {
            final id = file['id']?.toString();
            final filename = file['filename']?.toString();
            if (id == null || filename == null || filename.isEmpty) continue;

            final Rating? rating = switch(file['rating']) {
                'safe' => Rating.safe,
                'questionable' => Rating.questionable,
                'explicit' => Rating.explicit,
                'illegal' => Rating.illegal,
                _ => null,
            };

            List<String> stringList(dynamic value) {
                if (value is! List) return <String>[];
                return value.map((e) => e.toString()).toList();
            }

            images.add(BooruImage(
                id: id,
                path: p.join(booru.path, 'files', filename),
                tags: file['tags']?.toString() ?? '',
                rating: rating,
                note: file['note']?.toString(),
                sources: stringList(file['sources']),
                relatedImages: stringList(file['related']),
            ));
        }

        final tagCounts = <String, int>{};
        for (final file in rawFiles) {
            final rawTags = file['tags']?.toString() ?? '';
            for (final tag in rawTags.split(RegExp(r'\s+')).where((tag) => tag.isNotEmpty)) {
                tagCounts.update(tag, (count) => count + 1, ifAbsent: () => 1);
            }
        }
        final tags = tagCounts.entries.toList()
          ..sort((a, b) {
              final countCompare = b.value.compareTo(a.value);
              return countCompare != 0 ? countCompare : a.key.compareTo(b.key);
          });

        final collectionCount = raw['collections'] is List ? (raw['collections'] as List).length : 0;
        return {
            'booru': booru,
            'images': images,
            'count': rawFiles.length,
            'tags': tags.take(tags.length > 14 ? 14 : tags.length).toList(),
            'collections': collectionCount,
            'path': booru.path,
            'gridSize': prefs.getInt('grid_size') ?? settingsDefaults['grid_size'],
            'thumbnailQuality': prefs.getDouble('thumbnail_quality') ?? settingsDefaults['thumbnail_quality'],
        };
    }

    void _search() {
        context.push('/search?tag=${Uri.encodeComponent(_searchController.text.trim())}');
    }

    @override
    Widget build(BuildContext context) {
        final portrait = MediaQuery.of(context).orientation == Orientation.portrait;
        return Scaffold(
            appBar: portrait ? AppBar(
                title: const Text('Browse'),
                actions: [
                    IconButton(
                        tooltip: 'Add image',
                        icon: const ClassicCustomIcon('add_image', size: 21),
                        onPressed: () => context.push('/manage_image'),
                    ),
                ],
            ) : null,
            drawer: portrait ? const Drawer(child: DefaultDrawerProxy()) : null,
            body: FutureBuilder<Map<String, dynamic>>(
                future: _homeFuture,
                builder: (context, snapshot) {
                    if (snapshot.hasError) {
                        return Center(
                            child: SizedBox(
                                width: 520,
                                child: ClassicPanel(
                                    title: 'Could not load the collection',
                                    headerIcon: const ClassicCustomIcon('error_sad', size: 18),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text('${snapshot.error}', style: const TextStyle(fontSize: 11)),
                                            const SizedBox(height: 10),
                                            ClassicBevelButton(label: 'Retry', onPressed: _refresh),
                                        ],
                                    ),
                                ),
                            ),
                        );
                    }
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final data = snapshot.data!;
                    final images = data['images'] as List<BooruImage>;

                    final gallery = CustomScrollView(
                        slivers: [
                            SliverToBoxAdapter(
                                child: Padding(
                                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                            Row(
                                                children: [
                                                    const Expanded(
                                                        child: Text('Browse Deviations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                                    ),
                                                    ClassicBevelButton(
                                                        label: 'Collections',
                                                        icon: Icons.photo_library_outlined,
                                                        onPressed: () => context.push('/collections'),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    ClassicBevelButton(
                                                        label: 'Submit',
                                                        leading: const ClassicActionIcon('submit', size: 17),
                                                        accent: true,
                                                        onPressed: () => context.push('/manage_image'),
                                                    ),
                                                ],
                                            ),
                                            const SizedBox(height: 10),
                                            Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                    color: ClassicPalette.panelAlt,
                                                    border: Border.all(color: ClassicPalette.border),
                                                    borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: Row(
                                                    children: [
                                                        const SizedBox(width: 4),
                                                        const Text('Newest', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                                        const SizedBox(width: 16),
                                                        Expanded(
                                                            child: SizedBox(
                                                                height: 31,
                                                                child: TextField(
                                                                    controller: _searchController,
                                                                    textInputAction: TextInputAction.search,
                                                                    onSubmitted: (_) => _search(),
                                                                    decoration: InputDecoration(
                                                                        prefixIcon: Padding(
                                                                            padding: const EdgeInsets.all(5),
                                                                            child: Image.asset(
                                                                                'assets/classic_deviantart/custom/search.png',
                                                                                width: 18,
                                                                                height: 18,
                                                                                filterQuality: FilterQuality.medium,
                                                                                isAntiAlias: true,
                                                                            ),
                                                                        ),
                                                                        prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                                        hintText: 'Search tags...',
                                                                    ),
                                                                ),
                                                            ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        ClassicBevelButton(label: 'Search Art', onPressed: _search, accent: true),
                                                    ],
                                                ),
                                            ),
                                            const SizedBox(height: 9),
                                            Text(
                                                '${data['count']} deviations in your local collection',
                                                style: const TextStyle(fontSize: 12, color: ClassicPalette.muted),
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                            if (images.isEmpty)
                                const SliverFillRemaining(
                                    child: Center(child: Text('Nothing to see here yet. Submit an image to begin your gallery.')),
                                )
                            else
                                SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                                    // SliverPadding must receive a widget whose render object is
                                    // always a RenderSliver. Do not put SharedPreferencesBuilder
                                    // here: while its FutureBuilder is loading it returns a Center
                                    // (RenderBox), which corrupts the sliver tree as soon as the
                                    // first stored image makes this branch active.
                                    sliver: SliverRepoGrid(
                                        images: images,
                                        autoadjustColumns: data['gridSize'] as int,
                                        imageQualityScale: data['thumbnailQuality'] as double,
                                        dragOutside: !isMobile(),
                                        onPressed: (image) => context.push('/view/${image.id}'),
                                    ),
                                ),
                            SliverToBoxAdapter(
                                child: Padding(
                                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                                    child: Center(
                                        child: ClassicBevelButton(
                                            label: 'Browse the full gallery',
                                            icon: Icons.grid_view,
                                            onPressed: () => context.push('/search'),
                                        ),
                                    ),
                                ),
                            ),
                        ],
                    );

                    if (portrait) return gallery;

                    return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            Expanded(child: gallery),
                            Container(
                                width: 250,
                                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                                child: ListView(
                                    children: [
                                        ClassicPanel(
                                            title: 'LocalBooru',
                                            icon: Icons.info_outline,
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    const Text('Your private art collection', style: TextStyle(fontWeight: FontWeight.w700)),
                                                    const SizedBox(height: 7),
                                                    _StatLine(label: 'Deviations', value: '${data['count']}'),
                                                    _StatLine(label: 'Collections', value: '${data['collections']}'),
                                                    const SizedBox(height: 9),
                                                    const Text('Collection path', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                                    const SizedBox(height: 2),
                                                    SelectableText('${data['path']}', style: const TextStyle(fontSize: 10, color: ClassicPalette.muted)),
                                                ],
                                            ),
                                        ),
                                        const SizedBox(height: 12),
                                        ClassicPanel(
                                            title: 'Popular Tags',
                                            icon: Icons.sell_outlined,
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Column(
                                                children: (data['tags'] as List).map((tag) {
                                                    return InkWell(
                                                        onTap: () => context.push('/search?tag=${Uri.encodeComponent(tag.key)}'),
                                                        child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                                            child: Row(
                                                                children: [
                                                                    Expanded(child: Text(tag.key, style: const TextStyle(fontSize: 11, color: ClassicPalette.link))),
                                                                    Text('${tag.value}', style: const TextStyle(fontSize: 10, color: ClassicPalette.muted)),
                                                                ],
                                                            ),
                                                        ),
                                                    );
                                                }).toList(),
                                            ),
                                        ),
                                        const SizedBox(height: 12),
                                        const ClassicPanel(
                                            title: 'Image Counter',
                                            icon: Icons.bar_chart,
                                            child: Center(child: ImageDisplay()),
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    );
                },
            ),
        );
    }
}

class _StatLine extends StatelessWidget {
    const _StatLine({required this.label, required this.value});
    final String label;
    final String value;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
                children: [
                    Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: ClassicPalette.muted))),
                    Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ],
            ),
        );
    }
}

/// Keeps the existing drawer on phone layouts without coupling the new home
/// page to the desktop housing implementation.
class DefaultDrawerProxy extends StatelessWidget {
    const DefaultDrawerProxy({super.key});

    @override
    Widget build(BuildContext context) {
        // Imported lazily through the existing public widget in drawer.dart.
        return const _DrawerLoader();
    }
}

class _DrawerLoader extends StatelessWidget {
    const _DrawerLoader();

    @override
    Widget build(BuildContext context) {
        return ListView(
            padding: EdgeInsets.zero,
            children: [
                const SizedBox(height: 18),
                const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('LocalBooru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                ListTile(leading: const ClassicSpriteIcon(index: 41, size: 20), title: const Text('Home'), onTap: () => context.go('/home')),
                ListTile(leading: const ClassicCustomIcon('search', size: 20), title: const Text('Search'), onTap: () => context.go('/search')),
                ListTile(leading: const ClassicActionIcon('collection', size: 20), title: const Text('Collections'), onTap: () => context.go('/collections')),
                const Divider(),
                ListTile(leading: const ClassicCustomIcon('add_image', size: 20), title: const Text('Add image'), onTap: () => context.push('/manage_image')),
                ListTile(leading: const ClassicCustomIcon('settings', size: 20), title: const Text('Settings'), onTap: () => context.go('/settings')),
            ],
        );
    }
}

class ImageDisplay extends StatefulWidget {
    const ImageDisplay({super.key});

    @override
    State<ImageDisplay> createState() => _ImageDisplayState();
}

class _ImageDisplayState extends State<ImageDisplay> {
    late Future<int> _futureNumber;

    @override
    void initState() {
        super.initState();
        counterListener.addListener(updateCounter);
        updateCounter();
    }

    @override
    void dispose() {
        counterListener.removeListener(updateCounter);
        super.dispose();
    }

    void updateCounter() {
        if (!mounted) {
            _futureNumber = (() async => (await getCurrentBooru()).getListLength())();
            return;
        }
        setState(() {
            _futureNumber = (() async => (await getCurrentBooru()).getListLength())();
        });
    }

    @override
    Widget build(context) {
        return SharedPreferencesBuilder(
            builder: (context, prefs) => FutureBuilder<int>(
                future: _futureNumber,
                builder: (context, snapshot) {
                    if(snapshot.hasData) {
                        final String counterType = prefs.getString('counter') ?? settingsDefaults['counter'];
                        return StyleCounter(number: snapshot.data!, display: counterType);
                    }
                    if(snapshot.hasError) throw snapshot.error!;
                    return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                },
            )
        );
    }
}
