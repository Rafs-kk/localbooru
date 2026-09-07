import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/components/fileinfo.dart';
import 'package:localbooru/components/headers.dart';
import 'package:localbooru/components/image_grid_display.dart';
import 'package:localbooru/components/video_view.dart';
import 'package:localbooru/components/classic_rating_icon.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/views/image_manager/shell.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

String classicDeviationTitle(BooruImage image) {
    final note = image.note?.trim();
    if (note != null && note.isNotEmpty) {
        final firstLine = note.split('\n').first.trim();
        if (firstLine.isNotEmpty && firstLine.length < 80) return firstLine;
    }
    final title = p.basenameWithoutExtension(image.filename).replaceAll(RegExp(r'[_-]+'), ' ').trim();
    return title.isEmpty ? 'Untitled deviation' : title;
}

class ImageViewShell extends StatelessWidget {
    const ImageViewShell({super.key, required this.image, required this.child, this.shouldShowImageOnPortrait = false, this.collections});

    final BooruImage image;
    final Widget child;
    final bool shouldShowImageOnPortrait;
    final List<BooruCollection>? collections;

    @override
    Widget build(BuildContext context) {
        final bool isMainDeviationPage = child is ImageViewProprieties;
        final Widget portraitTitle = ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(classicDeviationTitle(image), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ClassicPalette.link), overflow: TextOverflow.ellipsis),
            subtitle: Text('Deviation ID ${image.id}', style: const TextStyle(fontSize: 10, color: ClassicPalette.muted)),
        );
        final Widget? appBarLeading = isMainDeviationPage ? null : const ClassicSafeBackButton(fallback: '/search');
        final List<Widget> appBarActions = [
            if (!isMainDeviationPage) ...[
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ClassicBevelButton(
                        label: 'Edit',
                        leading: const ClassicActionIcon('edit', size: 16),
                        onPressed: () async => context.push('/manage_image', extra: PresetManageImageSendable(await PresetImage.fromExistingImage(image))),
                    ),
                ),
                const SizedBox(width: 5),
            ],
            PopupMenuButton(
                tooltip: 'Deviation actions',
                icon: const ClassicCustomIcon('image_actions', size: 18),
                padding: EdgeInsets.zero,
                itemBuilder: (context) {
                    return [
                        ...booruItems(),
                        const PopupMenuDivider(height: 1),
                        ...imageShareItems(image),
                        const PopupMenuDivider(height: 1),
                        ...imageManagementItems(
                            image,
                            context: context,
                            doulbeExitOnDelete: true,
                            includeEdit: !isMainDeviationPage,
                        )
                    ];
                }
            ),
            const SizedBox(width: 5),
        ];
        final PreferredSizeWidget? appBarBottom = (collections != null && collections!.isNotEmpty) ? PreferredSize(
            preferredSize: Size.fromHeight(36.0 * collections!.length),
            child: Container(
                color: ClassicPalette.panelHeader,
                child: Column(
                    children: collections!.map((collection) => CollectionSwitcher(collection: collection, image: image)).toList(),
                ),
            ),
        ) : null;

        return OrientationBuilder(
            builder: (context, orientation) {
                if(orientation == Orientation.portrait) {
                    return CustomScrollView(
                        slivers: [
                            SliverAppBar(
                                title: portraitTitle,
                                automaticallyImplyLeading: !isMainDeviationPage,
                                leading: appBarLeading,
                                actions: appBarActions,
                                bottom: appBarBottom,
                                pinned: true,
                                backgroundColor: ClassicPalette.panelAlt,
                            ),
                            SliverList(
                                delegate: SliverChildListDelegate([
                                    if (isMainDeviationPage)
                                        _ClassicDeviationMainContent(image: image, showImage: shouldShowImageOnPortrait)
                                    else ...[
                                        if(shouldShowImageOnPortrait) Container(
                                            color: ClassicPalette.page,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            child: ImageViewDisplay(image),
                                        ),
                                    ],
                                    child,
                                ])
                            )
                        ],
                    );
                }

                if (!isMainDeviationPage) {
                    return Scaffold(
                        appBar: AppBar(
                            title: portraitTitle,
                            leading: appBarLeading,
                            actions: appBarActions,
                            bottom: appBarBottom,
                        ),
                        body: ScrollConfiguration(
                            behavior: const MaterialScrollBehavior().copyWith(
                                dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
                            ),
                            child: Row(
                                children: [
                                    Expanded(
                                        child: Container(
                                            color: ClassicPalette.page,
                                            child: ImageViewDisplay(image),
                                        ),
                                    ),
                                    Container(
                                        width: 370,
                                        decoration: const BoxDecoration(
                                            color: ClassicPalette.page,
                                            border: Border(left: BorderSide(color: ClassicPalette.border)),
                                        ),
                                        child: LayoutBuilder(
                                            builder: (context, constraints) => SingleChildScrollView(
                                                child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                        minWidth: constraints.maxWidth,
                                                        maxWidth: constraints.maxWidth,
                                                        minHeight: constraints.maxHeight,
                                                    ),
                                                    child: child,
                                                ),
                                            ),
                                        ),
                                    )
                                ],
                            )
                        ),
                    );
                }

                return Scaffold(
                    appBar: AppBar(
                        automaticallyImplyLeading: false,
                        leading: null,
                        titleSpacing: 16,
                        title: _ClassicDeviationNavigator(image: image),
                        actions: appBarActions,
                        bottom: appBarBottom,
                    ),
                    body: ScrollConfiguration(
                        behavior: const MaterialScrollBehavior().copyWith(
                            dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
                        ),
                        child: LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                                child: ConstrainedBox(
                                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                    child: Padding(
                                        padding: const EdgeInsets.fromLTRB(28, 12, 24, 36),
                                        child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Expanded(
                                                    child: ConstrainedBox(
                                                        constraints: const BoxConstraints(maxWidth: 1280),
                                                        child: _ClassicDeviationMainContent(image: image),
                                                    ),
                                                ),
                                                const SizedBox(width: 34),
                                                SizedBox(
                                                    width: 330,
                                                    child: child,
                                                ),
                                            ],
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                );
            },
        );
    }
}

class _ClassicDeviationNavigator extends StatefulWidget {
    const _ClassicDeviationNavigator({required this.image});

    final BooruImage image;

    @override
    State<_ClassicDeviationNavigator> createState() => _ClassicDeviationNavigatorState();
}

class _ClassicDeviationNavigatorState extends State<_ClassicDeviationNavigator> {
    late Future<List<String>> _imageIds;

    @override
    void initState() {
        super.initState();
        _imageIds = _loadImageIds();
    }

    @override
    void didUpdateWidget(covariant _ClassicDeviationNavigator oldWidget) {
        super.didUpdateWidget(oldWidget);
        if (oldWidget.image.id != widget.image.id) _imageIds = _loadImageIds();
    }

    Future<List<String>> _loadImageIds() async {
        final booru = await getCurrentBooru();
        final raw = await booru.getRawInfo();
        final files = List<dynamic>.from(raw['files'] ?? const []);
        return files
            .whereType<Map>()
            .map((entry) => '${entry['id']}')
            .where((id) => id.isNotEmpty && id != 'null')
            .toList();
    }

    @override
    Widget build(BuildContext context) {
        return FutureBuilder<List<String>>(
            future: _imageIds,
            builder: (context, snapshot) {
                final ids = snapshot.data ?? const <String>[];
                final current = ids.indexOf(widget.image.id);
                final previous = current > 0 ? ids[current - 1] : null;
                final next = current >= 0 && current < ids.length - 1 ? ids[current + 1] : null;
                return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        ClassicBevelButton(
                            label: 'Prev',
                            leading: const ClassicActionIcon('prev', size: 17),
                            onPressed: previous == null ? null : () => context.go('/view/$previous'),
                        ),
                        const SizedBox(width: 3),
                        ClassicBevelButton(
                            label: 'All',
                            leading: const ClassicActionIcon('all', size: 17),
                            onPressed: () => context.go('/search'),
                        ),
                        const SizedBox(width: 3),
                        ClassicBevelButton(
                            label: 'Next',
                            leading: const ClassicActionIcon('next', size: 17),
                            onPressed: next == null ? null : () => context.go('/view/$next'),
                        ),
                    ],
                );
            },
        );
    }
}

class _ClassicDeviationMainContent extends StatelessWidget {
    const _ClassicDeviationMainContent({required this.image, this.showImage = true});

    final BooruImage image;
    final bool showImage;

    @override
    Widget build(BuildContext context) {
        final viewportHeight = MediaQuery.sizeOf(context).height;
        final stageHeight = (viewportHeight * .60).clamp(360.0, 650.0).toDouble();
        final title = classicDeviationTitle(image);
        final firstTag = image.tags.split(' ').firstWhere((tag) => tag.trim().isNotEmpty, orElse: () => 'LocalBooru');
        final note = image.note?.trim() ?? '';

        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                if (showImage) ...[
                    SizedBox(
                        height: stageHeight,
                        child: Container(
                            color: ClassicPalette.page,
                            alignment: Alignment.center,
                            child: ImageViewDisplay(image),
                        ),
                    ),
                    const SizedBox(height: 12),
                ],
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [ClassicPalette.headerTop, ClassicPalette.headerBottom],
                                ),
                                border: Border.all(color: ClassicPalette.headerBorder),
                                boxShadow: const [BoxShadow(color: Color(0x44000000), offset: Offset(1, 2), blurRadius: 2)],
                            ),
                            alignment: Alignment.center,
                            child: const Text('LB', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ClassicPalette.ink, height: 1.05)),
                                    const SizedBox(height: 3),
                                    Row(
                                        children: [
                                            const Text('by ', style: TextStyle(fontSize: 12, color: ClassicPalette.ink)),
                                            const Text('LocalBooru', style: TextStyle(fontSize: 12, color: ClassicPalette.link, fontWeight: FontWeight.w700)),
                                        ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${firstTag.replaceAll('_', ' ')}  •  Deviation ID ${image.id}  •  ${image.filename}',
                                        style: const TextStyle(fontSize: 10.5, color: ClassicPalette.muted),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: ClassicPalette.border),
                const SizedBox(height: 13),
                if (note.isNotEmpty)
                    SelectableText(note, style: const TextStyle(fontSize: 13, height: 1.45, color: ClassicPalette.ink))
                else
                    const Text('No description was provided for this deviation.', style: TextStyle(fontSize: 12, color: ClassicPalette.muted, fontStyle: FontStyle.italic)),
                const SizedBox(height: 20),
                _ClassicDeviationKeywords(image: image),
            ],
        );
    }
}

class _ClassicDeviationKeywords extends StatelessWidget {
    const _ClassicDeviationKeywords({required this.image});

    final BooruImage image;

    @override
    Widget build(BuildContext context) {
        return FutureBuilder<Map<String, List<String>>>(
            future: getCurrentBooru().then((booru) => booru.separateTagsByType(image.tags.split(' ').where((e) => e.trim().isNotEmpty).toList())),
            builder: (context, snapshot) {
                if (!snapshot.hasData) {
                    return const SizedBox(height: 22, child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))));
                }

                final tags = snapshot.data!;
                final rows = <Widget>[];
                const order = <(String, String)>[
                    ('artist', 'Artist'),
                    ('character', 'Character'),
                    ('copyright', 'Copyright'),
                    ('species', 'Species'),
                    ('generic', 'Keywords'),
                ];

                for (final item in order) {
                    final values = List<String>.from(tags[item.$1] ?? const [])..sort();
                    if (values.isEmpty) continue;
                    rows.add(Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 7,
                            runSpacing: 3,
                            children: [
                                Text('${item.$2}:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ClassicPalette.muted)),
                                ...values.map((tag) => ClassicLink(
                                    tag.replaceAll('_', ' '),
                                    fontSize: 11.5,
                                    onTap: () => context.push('/search/?tag=${Uri.encodeComponent(tag)}'),
                                )),
                            ],
                        ),
                    ));
                }

                if (rows.isEmpty) return const SizedBox.shrink();
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        Row(
                            children: [
                                const Text('Deviation Keywords', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ClassicPalette.ink)),
                                const SizedBox(width: 8),
                                const Expanded(child: Divider(height: 1, thickness: 1, color: ClassicPalette.border)),
                            ],
                        ),
                        ...rows,
                    ],
                );
            },
        );
    }
}

class ImageViewDisplay extends StatefulWidget {
    const ImageViewDisplay(this.image, {super.key});

    final BooruImage image;

    @override
    State<ImageViewDisplay> createState() => _ImageViewDisplayState();
}

class _ImageViewDisplayState extends State<ImageViewDisplay> {
    late LongPressDownDetails longPress;

    void openContextMenu(Offset globalPosition) {
        final overlayObject = Overlay.of(context).context.findRenderObject();
        if (overlayObject is! RenderBox) return;
        final overlay = overlayObject;
        final offset = overlay.globalToLocal(globalPosition);
        showMenu(
            context: context,
            position: RelativeRect.fromRect(
                Rect.fromLTWH(offset.dx, offset.dy, 10, 10),
                Offset.zero & overlay.size,
            ),
            items: imageShareItems(widget.image)
        );
    }

    @override
    Widget build(BuildContext context) {
        return SharedPreferencesBuilder(
            builder: (_, prefs) => Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                    child: lookupMimeType(widget.image.filename)!.startsWith("video/") || ((prefs.getBool("gif_video") ?? settingsDefaults["gif_video"]) && lookupMimeType(widget.image.filename) == "image/gif")
                        ? VideoView(widget.image.path)
                        : MouseRegion(
                            cursor: SystemMouseCursors.zoomIn,
                            child: GestureDetector(
                                onTap: () => {
                                    GoRouter.of(context).push("/zoom_image/${widget.image.id}")
                                },
                                onLongPress: () => openContextMenu(longPress.globalPosition),
                                onLongPressDown: (tap) => longPress = tap,
                                onSecondaryTapDown: (tap) => openContextMenu(tap.globalPosition),
                                child: Hero(
                                    tag: "detailed",
                                    child: DragItemWidget(
                                        dragItemProvider: (request) {
                                            final item = DragItem(
                                                localData: {'context': "image_view"},
                                                suggestedName: widget.image.filename
                                            );
                                            final format = SuperFormats.getFormatFromFileExtension(p.extension(widget.image.filename));
                                            // debugPrint("$format");
                                            if(format != null) item.add(format.lazy(() async => await widget.image.getImage().readAsBytes()));
                                            return item;
                                        },
                                        allowedOperations: () => [DropOperation.copy],
                                        child: DraggableWidget(
                                            child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                    color: const Color(0xFFF7F8F5),
                                                    border: Border.all(color: ClassicPalette.borderDark),
                                                    boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(2, 3))],
                                                ),
                                                child: Image.file(widget.image.getImage(), fit: BoxFit.contain),
                                            ),
                                        )
                                    ),
                                ),
                            ),
                        ),
                    ),
                ),
        );
    }
}

class ImageViewProprieties extends StatefulWidget {
    const ImageViewProprieties(this.image, {super.key});
    
    final BooruImage image;
    
    @override
    State<StatefulWidget> createState() => _ImageViewProprietiesState();
}

class _ImageViewProprietiesState extends State<ImageViewProprieties> {
    late LongPressDownDetails longPress;
    late Future<List<BooruCollection>> _collections;

    @override
    void initState() {
        super.initState();
        _collections = getCurrentBooru().then((booru) => booru.obtainMatchingCollection(widget.image.id));
    }

    @override
    void didUpdateWidget(covariant ImageViewProprieties oldWidget) {
        super.didUpdateWidget(oldWidget);
        if (oldWidget.image.id != widget.image.id) {
            _collections = getCurrentBooru().then((booru) => booru.obtainMatchingCollection(widget.image.id));
        }
    }

    void openContextMenu({required Offset globalPosition, required String url}) {
        final overlayObject = Overlay.of(context).context.findRenderObject();
        if (overlayObject is! RenderBox) return;
        final overlay = overlayObject;
        final offset = overlay.globalToLocal(globalPosition);
        showMenu(
            context: context,
            position: RelativeRect.fromRect(
                Rect.fromLTWH(offset.dx, offset.dy, 10, 10),
                Offset.zero & overlay.size,
            ),
            items: [
                PopupMenuItem(
                    enabled: false,
                    height: 16,
                    child: Text(url, maxLines: 1),
                ),
                ...urlItems(url)
            ]
        );
    }

    Widget _heading(String title, {Widget? trailing}) {
        return Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 7),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Row(
                        children: [
                            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ClassicPalette.ink))),
                            if (trailing != null) trailing,
                        ],
                    ),
                    const SizedBox(height: 5),
                    const Divider(height: 1, thickness: 1, color: ClassicPalette.border),
                ],
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    SizedBox(
                        width: double.infinity,
                        child: ClassicBevelButton(
                            label: 'Edit Deviation',
                            leading: const ClassicActionIcon('edit', size: 17),
                            onPressed: () async => context.push('/manage_image', extra: PresetManageImageSendable(await PresetImage.fromExistingImage(widget.image))),
                        ),
                    ),
                    const SizedBox(height: 9),
                    PopupMenuButton(
                        tooltip: 'Open image actions',
                        itemBuilder: (context) => imageShareItems(widget.image),
                        child: Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [ClassicPalette.buttonTop, ClassicPalette.buttonBottom],
                                ),
                                border: Border.all(color: ClassicPalette.borderDark),
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: const [BoxShadow(color: Colors.white70, offset: Offset(0, 1), blurRadius: 0)],
                            ),
                            child: const Row(
                                children: [
                                    ClassicActionIcon('share', size: 17),
                                    SizedBox(width: 5),
                                    Expanded(child: Text('Open / Copy / Share Image', style: TextStyle(fontSize: 12, color: ClassicPalette.ink, fontWeight: FontWeight.w700))),
                                    Text('▾', style: TextStyle(fontSize: 13, height: 1, color: ClassicPalette.muted, fontWeight: FontWeight.w700)),
                                ],
                            ),
                        ),
                    ),
                    if (widget.image.relatedImages.isNotEmpty) ...[
                        _heading('More from LocalBooru'),
                        SizedBox(
                            height: 86,
                            child: BooruLoader(
                                builder: (context, booru) => ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: widget.image.relatedImages.length,
                                    separatorBuilder: (context, index) => const SizedBox(width: 7),
                                    itemBuilder: (context, index) {
                                        final imageId = widget.image.relatedImages[index];
                                        return SizedBox(
                                            width: 82,
                                            height: 82,
                                            child: MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: GestureDetector(
                                                    onTap: () => context.go('/view/$imageId'),
                                                    child: BooruImageLoader(
                                                        booru: booru,
                                                        id: imageId,
                                                        builder: (context, relatedImage) => ImageGrid(image: relatedImage, resizeSize: 180),
                                                    ),
                                                ),
                                            ),
                                        );
                                    },
                                ),
                            ),
                        ),
                    ],
                    _heading('Featured in:'),
                    FutureBuilder<List<BooruCollection>>(
                        future: _collections,
                        builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox(width: 14, height: 14, child: Align(alignment: Alignment.centerLeft, child: CircularProgressIndicator(strokeWidth: 1.5)));
                            final collections = snapshot.data!;
                            if (collections.isEmpty) {
                                return const Text('Not currently featured in any collections.', style: TextStyle(fontSize: 11.5, color: ClassicPalette.muted));
                            }
                            return Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: collections.map((collection) => ClassicLink(
                                    collection.name,
                                    fontSize: 11.5,
                                    onTap: () => context.go('/collections/${collection.id}'),
                                )).toList(),
                            );
                        },
                    ),
                    if (widget.image.rating != null) ...[
                        _heading('Content Rating'),
                        Row(
                            children: [
                                ClassicRatingIcon(rating: widget.image.rating, size: 22),
                                const SizedBox(width: 7),
                                Text(getRatingText(widget.image.rating), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                            ],
                        ),
                    ],
                    if(widget.image.sources.isNotEmpty) ...[
                        _heading('Sources'),
                        ...widget.image.sources.map((url) {
                            final displayUrl = url.trim();
                            return Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                        onLongPress: () => openContextMenu(globalPosition: longPress.globalPosition, url: url),
                                        onLongPressDown: (details) => longPress = details,
                                        onSecondaryTapDown: (tap) => openContextMenu(globalPosition: tap.globalPosition, url: url),
                                        onTap: () => openExternalUrl(url),
                                        child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                                const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child: Center(child: ClassicCustomIcon('sources_book', size: 18)),
                                                ),
                                                const SizedBox(width: 7),
                                                Expanded(
                                                    child: Text(
                                                        displayUrl,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                            fontSize: 11.5,
                                                            height: 1.2,
                                                            fontWeight: FontWeight.w600,
                                                            color: ClassicPalette.link,
                                                        ),
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                ),
                            );
                        }),
                    ],
                    _heading('Details'),
                    DefaultTextStyle.merge(
                        style: const TextStyle(fontSize: 10.5, height: 1.3),
                        child: FileInfo(widget.image.getImage()),
                    ),
                ],
            ),
        );
    }
}

class CollectionSwitcher extends StatelessWidget {
    const CollectionSwitcher({super.key, required this.collection, required this.image});

    final BooruCollection collection;
    final BooruImage image;

    @override
    Widget build(BuildContext context) {
        // The position is derived from the image currently displayed. Do not cache
        // it in State: /view/:id can update in-place when Prev/Next navigation uses
        // context.go(), so a value captured only in initState becomes stale.
        final collectionPosition = collection.pages.indexOf(image.id);
        final hasCurrentImage = collectionPosition >= 0;

        return SizedBox(
            height: 40,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    IconButton(
                        icon: const ClassicNavArrow.left(size: 13),
                        onPressed: hasCurrentImage && collectionPosition > 0 ? () {
                            context.push("/view/${collection.pages[collectionPosition - 1]}");
                        } : null
                    ),
                    Expanded(
                        child: Center(
                            child: TextButton(
                                child: RichText(
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    text: TextSpan(
                                        children: [
                                            TextSpan(
                                                text: collection.name,
                                                style: TextStyle(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    // decoration: TextDecoration.underline
                                                ),
                                            ),
                                            TextSpan(
                                                text: " • ",
                                                style: TextStyle(
                                                    color: Theme.of(context).disabledColor,
                                                ),
                                                children: [
                                                    TextSpan(
                                                        text: hasCurrentImage
                                                            ? "${collectionPosition + 1}/${collection.pages.length}"
                                                            : "?/${collection.pages.length}",
                                                    ),
                                                ]
                                            ),
                                        ]
                                    ),
                                ),
                                onPressed: () => context.push("/collections/${collection.id}"),
                            ),
                        )
                    ),
                    IconButton(
                        icon: const ClassicNavArrow.right(size: 13),
                        onPressed: hasCurrentImage && (collectionPosition + 1) < collection.pages.length ? () {
                            context.push("/view/${collection.pages[collectionPosition + 1]}");
                        } : null
                    ),
                ],
            ),
        );
    }
}

class NotesView extends StatefulWidget {
    const NotesView({super.key, required this.id});

    final int id;

    @override
    State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
    final controller = TextEditingController();
    Timer? _debounce;
    late BooruImage image;

    @override
    void initState() {
        super.initState();
        setText();
    }

    void setText() async {
        final booru = await getCurrentBooru();
        image = (await booru.getImage(widget.id.toString()))!;
        controller.text = image.note ?? "";
    }
    
    @override
    Widget build(context) {
        return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Header("Note", padding: EdgeInsets.only(bottom: 16),),
                    TextField(
                        controller: controller,
                        keyboardType: TextInputType.multiline,
                        minLines: 10,
                        maxLines: null,
                        decoration: const InputDecoration(
                            hintText: 'Insert a note',
                            border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                            if (_debounce?.isActive ?? false) _debounce?.cancel();
                            _debounce = Timer(const Duration(seconds: 1), () async {
                                final preset = await PresetImage.fromExistingImage(image);
                                preset.note = value;
                                await insertImage(preset);
                            });
                        },
                    ),
                ],
            ),
        );
    }
}