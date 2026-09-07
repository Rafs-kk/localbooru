import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/dialogs/confirm_dialogs.dart';
import 'package:localbooru/components/dialogs/image_selector_dialog.dart';
import 'package:localbooru/components/image_grid_display.dart';
import 'package:localbooru/theme/classic_deviantart.dart';

class CollectionsSettings extends StatefulWidget {
    const CollectionsSettings({super.key, required this.booru, this.jumpToCollection});

    final Booru booru;
    final CollectionID? jumpToCollection;

    @override
    State<CollectionsSettings> createState() => _CollectionsSettingsState();
}

class _CollectionsSettingsState extends State<CollectionsSettings> {
    late List<PresetCollection> collectionPresets;
    final Map<CollectionID, GlobalKey> valueKeys = {};
    final List<CollectionID> deleteCollections = [];
    bool hasLoaded = false;
    bool saving = false;

    @override
    void initState() {
        super.initState();
        widget.booru.getAllCollections().then((collections) {
            collectionPresets = collections.map(PresetCollection.fromExistingPreset).toList();
            for (final collection in collections) {
                valueKeys[collection.id] = GlobalKey();
            }
            if (!mounted) return;
            setState(() => hasLoaded = true);
            if (widget.jumpToCollection != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await Future.delayed(const Duration(milliseconds: 100));
                    final keyContext = valueKeys[widget.jumpToCollection!]?.currentContext;
                    if (keyContext != null) await Scrollable.ensureVisible(keyContext, alignment: .12);
                });
            }
        });
    }

    Future<void> savePresets() async {
        if (saving) return;
        setState(() => saving = true);
        try {
            for (final preset in collectionPresets) {
                await insertCollection(preset);
            }
            for (final id in deleteCollections) {
                await removeCollection(id);
            }
            if (!mounted) return;
            classicSafeBack(context, fallback: '/settings/booru');
        } finally {
            if (mounted) setState(() => saving = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        if (!hasLoaded) return const Center(child: CircularProgressIndicator());

        return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
            children: [
                Container(
                    decoration: BoxDecoration(
                        color: ClassicPalette.panel,
                        border: Border.all(color: ClassicPalette.borderDark),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 9),
                                decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0xFFC8D8C4), ClassicPalette.panelHeader],
                                    ),
                                    border: Border(bottom: BorderSide(color: ClassicPalette.borderDark)),
                                ),
                                child: Row(
                                    children: [
                                        const ClassicActionIcon('collection', size: 19),
                                        const SizedBox(width: 7),
                                        const Text('Collections', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                                        const SizedBox(width: 9),
                                        const Text('Favourites-style folders for your local deviations', style: TextStyle(fontSize: 10.5, color: ClassicPalette.muted)),
                                        const Spacer(),
                                        ClassicBevelButton(
                                            label: saving ? 'Saving...' : 'Save Changes',
                                            leading: const ClassicSpriteIcon(index: 11, size: 15),
                                            accent: true,
                                            onPressed: saving ? null : savePresets,
                                        ),
                                    ],
                                ),
                            ),
                            Container(
                                padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                                color: const Color(0xFFD5DFD3),
                                child: Text(
                                    '${collectionPresets.length} collection${collectionPresets.length == 1 ? '' : 's'} in this booru. Expand a folder to rename it, arrange deviations, add images or remove the folder.',
                                    style: const TextStyle(fontSize: 11, color: ClassicPalette.muted),
                                ),
                            ),
                        ],
                    ),
                ),
                const SizedBox(height: 10),
                if (collectionPresets.isEmpty)
                    ClassicPanel(
                        title: 'No Collections',
                        headerIcon: const ClassicActionIcon('collection', size: 18),
                        child: const Text('Create a collection from the Collections page, then return here to manage its contents.'),
                    )
                else
                    for (final preset in List<PresetCollection>.from(collectionPresets)) ...[
                        CollectionCard(
                            key: valueKeys[preset.id ?? 'collection_${collectionPresets.indexOf(preset)}'] ??= GlobalKey(),
                            collection: preset,
                            booru: widget.booru,
                            onChanged: (collection) {
                                final index = collectionPresets.indexWhere((e) => e.id == collection.id);
                                if (index >= 0) collectionPresets[index] = collection;
                            },
                            onDeletePressed: () {
                                final id = preset.id;
                                setState(() {
                                    collectionPresets.removeWhere((e) => e.id == id);
                                    if (id != null) deleteCollections.add(id);
                                });
                            },
                            initiallyExpanded: preset.id == widget.jumpToCollection,
                        ),
                        const SizedBox(height: 9),
                    ],
            ],
        );
    }
}

class CollectionCard extends StatefulWidget {
    const CollectionCard({super.key, required this.collection, required this.booru, this.onChanged, this.onDeletePressed, this.initiallyExpanded = false});

    final PresetCollection collection;
    final Booru booru;
    final bool initiallyExpanded;
    final void Function(PresetCollection collection)? onChanged;
    final VoidCallback? onDeletePressed;

    @override
    State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
    late PresetCollection loadedCollection;

    @override
    void initState() {
        super.initState();
        loadedCollection = widget.collection;
    }

    void sendChange() => widget.onChanged?.call(loadedCollection);

    @override
    Widget build(BuildContext context) {
        return Material(
            color: ClassicPalette.panel,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(side: BorderSide(color: ClassicPalette.borderDark)),
            child: ExpansionTile(
                initiallyExpanded: widget.initiallyExpanded,
                tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                backgroundColor: ClassicPalette.panel,
                collapsedBackgroundColor: const Color(0xFFD3DED1),
                iconColor: ClassicPalette.link,
                collapsedIconColor: ClassicPalette.link,
                shape: const Border(),
                collapsedShape: const Border(),
                leading: const ClassicActionIcon('collection', size: 20),
                title: Text(loadedCollection.name ?? 'Untitled Collection', style: const TextStyle(fontSize: 12.5, color: ClassicPalette.link, fontWeight: FontWeight.w800)),
                subtitle: Text('Collection ID ${loadedCollection.id} • ${loadedCollection.pages?.length ?? 0} deviations', style: const TextStyle(fontSize: 10.5, color: ClassicPalette.muted)),
                children: [
                    Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                            color: const Color(0xFFD8E2D6),
                            border: Border.all(color: ClassicPalette.border),
                        ),
                        child: ClassicFieldLabel(
                            label: 'Collection name',
                            child: TextFormField(
                                initialValue: loadedCollection.name,
                                decoration: const InputDecoration(),
                                validator: (value) => value != null && value.isNotEmpty ? null : 'Value is empty',
                                onChanged: (value) {
                                    loadedCollection.name = value;
                                    sendChange();
                                },
                            ),
                        ),
                    ),
                    const SizedBox(height: 8),
                    if ((loadedCollection.pages ?? []).isNotEmpty)
                        ReorderableListView.builder(
                            itemCount: loadedCollection.pages!.length,
                            buildDefaultDragHandles: false,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            proxyDecorator: (child, index, animation) => Material(elevation: 4, color: Colors.transparent, child: child),
                            itemBuilder: (context, index) {
                                final imageID = loadedCollection.pages![index];
                                return ReorderableDragStartListener(
                                    key: ValueKey(imageID),
                                    index: index,
                                    child: BooruImageLoader(
                                        booru: widget.booru,
                                        id: imageID,
                                        builder: (context, image) => Container(
                                            margin: const EdgeInsets.only(bottom: 4),
                                            decoration: BoxDecoration(
                                                color: index.isEven ? const Color(0xFFD4DED2) : const Color(0xFFCBD7C9),
                                                border: Border.all(color: ClassicPalette.border),
                                            ),
                                            child: ListTile(
                                                dense: true,
                                                contentPadding: const EdgeInsets.fromLTRB(7, 3, 5, 3),
                                                leading: SizedBox(
                                                    width: 48,
                                                    height: 42,
                                                    child: ImageGrid(image: image, resizeSize: 160),
                                                ),
                                                title: Text(image.filename, style: const TextStyle(fontSize: 11.5, color: ClassicPalette.link, fontWeight: FontWeight.w700)),
                                                subtitle: Text('ID ${image.id}${index == 0 ? ' • collection cover' : ''}', style: const TextStyle(fontSize: 10)),
                                                onTap: () => context.push('/zoom_image/$imageID'),
                                                trailing: IconButton(
                                                    tooltip: 'Remove from collection',
                                                    icon: const ClassicActionIcon('delete', size: 17),
                                                    onPressed: () {
                                                        setState(() => loadedCollection.pages!.removeAt(index));
                                                        sendChange();
                                                    },
                                                ),
                                            ),
                                        ),
                                    ),
                                );
                            },
                            onReorder: (oldIndex, newIndex) {
                                if (oldIndex < newIndex) newIndex -= 1;
                                setState(() {
                                    final item = loadedCollection.pages!.removeAt(oldIndex);
                                    loadedCollection.pages!.insert(newIndex, item);
                                });
                                sendChange();
                            },
                        )
                    else
                        Container(
                            padding: const EdgeInsets.all(12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: const Color(0xFFDCE5D9), border: Border.all(color: ClassicPalette.border)),
                            child: const Text('This collection is empty.', style: TextStyle(fontSize: 11, color: ClassicPalette.muted)),
                        ),
                    const SizedBox(height: 8),
                    Row(
                        children: [
                            ClassicBevelButton(
                                label: 'Add Deviations',
                                leading: const ClassicSpriteIcon(index: 32, size: 15),
                                onPressed: () async {
                                    final imageList = await openSelectionDialog(context: context, selectedImages: loadedCollection.pages);
                                    if (imageList == null) return;
                                    setState(() => loadedCollection.pages = imageList);
                                    sendChange();
                                },
                            ),
                            const Spacer(),
                            ClassicBevelButton(
                                label: 'Delete Collection',
                                leading: const ClassicActionIcon('delete', size: 16),
                                onPressed: () async {
                                    final shouldDelete = await showDialog<bool>(context: context, builder: (context) => const DeleteImageDialogue());
                                    if (shouldDelete == true) widget.onDeletePressed?.call();
                                },
                            ),
                        ],
                    ),
                ],
            ),
        );
    }
}
