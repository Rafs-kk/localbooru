import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/components/dialogs/textfield_dialogs.dart';
import 'package:localbooru/theme/classic_deviantart.dart';

class CollectionsListPage extends StatefulWidget {
    const CollectionsListPage({super.key, required this.booru});

    final Booru booru;

    @override
    State<CollectionsListPage> createState() => _CollectionsListPageState();
}

class _CollectionsListPageState extends State<CollectionsListPage> {
    late Future<List<BooruCollection>> collectionFuture;
    late LongPressDownDetails longTap;

    @override
    void initState() {
        super.initState();
        _refresh();
    }

    void _refresh() {
        collectionFuture = widget.booru.getAllCollections();
    }

    void openContextMenu(Offset offset, BooruCollection collection) {
        final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
        showMenu(
            context: context,
            position: RelativeRect.fromRect(
                Rect.fromLTWH(offset.dx, offset.dy, 10, 10),
                Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width, overlay.paintBounds.size.height),
            ),
            items: [
                PopupMenuItem(
                    height: 36,
                    child: const Row(
                        children: [
                            ClassicActionIcon('edit', size: 17),
                            SizedBox(width: 7),
                            Text('Edit collection'),
                        ],
                    ),
                    onTap: () => context.push('/settings/booru/collections?id=${collection.id}')
                )
            ]
        );
    }

    Future<void> _addCollection() async {
        final name = await showDialog<String>(
            context: context,
            builder: (context) => const AddCollectionDialog()
        );
        if(name == null) return;
        await insertCollection(PresetCollection(name: name, pages: []));
        if (!mounted) return;
        setState(_refresh);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Row(
                    children: [
                        ClassicActionIcon('collection', size: 19),
                        SizedBox(width: 7),
                        Text('Collections'),
                        SizedBox(width: 9),
                        Text('Favourites', style: TextStyle(fontSize: 10.5, color: ClassicPalette.muted, fontWeight: FontWeight.w400)),
                    ],
                ),
                actions: [
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ClassicBevelButton(label: 'New Collection', leading: const ClassicActionIcon('collection', size: 17), accent: true, onPressed: _addCollection),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton(
                        tooltip: 'Collection options',
                        icon: const ClassicCustomIcon('menu', size: 18),
                        padding: EdgeInsets.zero,
                        itemBuilder: (context) => [
                            PopupMenuItem(
                                height: 36,
                                child: const Row(
                                    children: [
                                        ClassicActionIcon('collection', size: 17),
                                        SizedBox(width: 7),
                                        Text('Manage collections'),
                                    ],
                                ),
                                onTap: () => context.push('/settings/booru/collections'),
                            )
                        ],
                    ),
                    const SizedBox(width: 5),
                ],
            ),
            body: FutureBuilder<List<BooruCollection>>(
                future: collectionFuture,
                builder: (context, snapshot) {
                    if(snapshot.hasError) throw snapshot.error!;
                    if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    if(snapshot.data!.isEmpty) {
                        return Center(
                            child: ClassicPanel(
                                title: 'Your Collections',
                                icon: Icons.photo_library_outlined,
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        const Text('No collections have been created yet.'),
                                        const SizedBox(height: 12),
                                        ClassicBevelButton(label: 'Create a collection', leading: const ClassicActionIcon('collection', size: 17), accent: true, onPressed: _addCollection),
                                    ],
                                ),
                            ),
                        );
                    }

                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                color: ClassicPalette.panelAlt,
                                child: Text(
                                    'Favourites  •  ${snapshot.data!.length} collection${snapshot.data!.length == 1 ? '' : 's'} in this booru',
                                    style: const TextStyle(fontSize: 12, color: ClassicPalette.muted),
                                ),
                            ),
                            Expanded(
                                child: GridView.extent(
                                    maxCrossAxisExtent: 240,
                                    childAspectRatio: 0.86,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    padding: const EdgeInsets.all(16),
                                    children: snapshot.data!.map((collection) {
                                        return GestureDetector(
                                            onSecondaryTapDown: (tap) => openContextMenu(getOffsetRelativeToBox(offset: tap.globalPosition, renderObject: context.findRenderObject()!), collection),
                                            onLongPressDown: (details) => longTap = details,
                                            onLongPress: () => openContextMenu(getOffsetRelativeToBox(offset: longTap.globalPosition, renderObject: context.findRenderObject()!), collection),
                                            child: CollectionCard(
                                                collection: collection,
                                                booru: widget.booru,
                                                onPressed: () => context.push('/collections/${collection.id}'),
                                            ),
                                        );
                                    }).toList(),
                                ),
                            ),
                        ],
                    );
                }
            ),
        );
    }
}

class CollectionCard extends StatelessWidget {
    const CollectionCard({super.key, required this.collection, required this.booru, this.onPressed});

    final BooruCollection collection;
    final Booru booru;
    final void Function()? onPressed;

    @override
    Widget build(BuildContext context) {
        return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(5),
                child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                        children: [
                            Expanded(
                                child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8F5),
                                        border: Border.all(color: ClassicPalette.borderDark),
                                        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 3, offset: Offset(1, 2))],
                                    ),
                                    child: collection.pages.isNotEmpty ? BooruImageLoader(
                                        booru: booru,
                                        id: collection.pages.first,
                                        builder: (context, image) => Image(
                                            image: FileImage(image.getImage()),
                                            fit: BoxFit.contain,
                                        )
                                    ) : const Center(
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                                const Opacity(opacity: .55, child: ClassicSpriteIcon(index: 0, size: 38)),
                                                SizedBox(height: 7),
                                                Text('No images', style: TextStyle(fontSize: 11, color: ClassicPalette.muted)),
                                            ],
                                        ),
                                    ),
                                ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                                collection.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: ClassicPalette.link, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text('${collection.pages.length} deviations', style: const TextStyle(fontSize: 10, color: ClassicPalette.muted)),
                        ],
                    ),
                ),
            ),
        );
    }
}
