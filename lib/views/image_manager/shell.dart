import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/app_bar_linear_progress.dart';
import 'package:localbooru/components/dialogs/download_dialog.dart';
import 'package:localbooru/components/dialogs/image_selector_dialog.dart';
import 'package:localbooru/components/dialogs/textfield_dialogs.dart';
import 'package:localbooru/shortcut_handler.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/compressor.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/views/image_manager/components/image_upload.dart';
import 'package:localbooru/views/image_manager/form.dart';
import 'package:localbooru/views/image_manager/general_collection_manager.dart';
import 'package:path/path.dart' as p;

class ImageManagerShell extends StatefulWidget {
    const ImageManagerShell({super.key, this.sendable});

    final ManageImageSendable? sendable;

    @override
    State<ImageManagerShell> createState() => _ImageManagerShellState();
}

class _ImageManagerShellState extends State<ImageManagerShell> {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    
    late VirtualPresetCollection preset;
    List<bool> errorOnPages = [false];
    bool isSaving = false;
    bool saveCollection = false;
    int savedImages = 0;
    double? progressCompressedImages;
    int imagePage = 0;

    bool isCorelated = false;


    AcessibleNotifyListenerNotifier updatePreset = AcessibleNotifyListenerNotifier();

    @override
    void initState() {
        super.initState();
        if(widget.sendable == null) preset = VirtualPresetCollection(pages: [PresetImage()]);
        if(widget.sendable is PresetManageImageSendable) preset = VirtualPresetCollection(pages: [(widget.sendable as PresetManageImageSendable).preset]);
        if(widget.sendable is PresetListManageImageSendable) preset = VirtualPresetCollection(pages: (widget.sendable as PresetListManageImageSendable).presets);
        if(widget.sendable is VirtualPresetManageImageSendable) {
            saveCollection = true;
            preset = (widget.sendable as VirtualPresetManageImageSendable).preset;
        }

        if(preset.pages == null || preset.pages!.isEmpty) preset.pages = [PresetImage()];
        errorOnPages.addAll(List.generate(preset.pages!.length, (index) => preset.pages![index].image == null || preset.pages![index].tags == null));
    }

    void saveImages() async {
        if (isSaving) return;
        setState(() {
            isSaving = true;
            savedImages = 0;
        });

        try {
            final booru = await getCurrentBooru();
            final listLength = await booru.getListLength();

            final List<ImageID> imaginaryIDs = preset.pages!.mapIndexed((index, preset) {
                if(preset.replaceID != null) return preset.replaceID!;
                return "${index + listLength}";
            }).toList();

            final List<BooruImage> writtenImages = [];
            for (final (index, imagePreset) in preset.pages!.indexed) {
                if(isCorelated && preset.pages!.length > 1) {
                    final selfID = imaginaryIDs[index];
                    imagePreset.relatedImages = imaginaryIDs.where((id) => id != selfID).toList();
                }
                imagePreset.replaceID ??= imaginaryIDs[index];

                writtenImages.add(await insertImage(imagePreset));
                if (mounted) setState(() => savedImages++);
            }

            if(saveCollection) await insertCollection(PresetCollection.fromVirtualPresetCollection(preset));
            if (!mounted) return;

            // The classic masthead opens Submit with context.go(), which replaces
            // the route stack. Calling context.pop() after a successful save can
            // therefore have nothing to pop, leaving the page stuck on "Saving…".
            // Navigate to an explicit, freshly-loaded destination instead.
            if (writtenImages.length == 1) {
                context.go('/view/${writtenImages.single.id}');
            } else {
                context.go('/search');
            }
        } catch (error, stackTrace) {
            debugPrint('Failed to save deviation(s): $error');
            debugPrintStack(stackTrace: stackTrace);
            if (!mounted) return;
            setState(() => isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not save deviation: $error')),
            );
        }
    }

    String generateName(PresetImage imagePreset) {
        return imagePreset.image != null ? p.basenameWithoutExtension(imagePreset.image!.path) : "Image ${preset.pages!.indexOf(imagePreset) + 1}";
    }

    bool hasError() => errorOnPages.any((element) => element,);

    void addMultipleImages(List<File> files) {
        if (files.isEmpty) return;

        var startIndex = 0;
        if (preset.pages!.isNotEmpty && preset.pages!.first.image == null && preset.pages!.first.replaceID == null) {
            preset.pages!.first.image = files.first;
            if (errorOnPages.length > 1) errorOnPages[1] = true;
            updatePreset.update();
            startIndex = 1;
        }

        for (final file in files.skip(startIndex)) {
            preset.pages!.add(PresetImage(image: file, key: UniqueKey()));
            errorOnPages.add(true);
        }
    }

    void compressAllImages() async {
        setState(() {progressCompressedImages = 0;});
        final presetsToCompressLength = preset.pages!.where((image) => image.image != null,).length;
        for (final (index, presetImage) in preset.pages!.indexed) {
            if(presetImage.image == null) continue;
            final file = await compress(presetImage.image!);
            preset.pages![index].image = file;
            setState(() {progressCompressedImages = index / presetsToCompressLength;});
        }
        updatePreset.update();
        setState(() {progressCompressedImages = null;});
    }

    Widget _classicBulkDrawerRow({
        required Widget leading,
        required String title,
        String? subtitle,
        required bool selected,
        VoidCallback? onTap,
        Widget? trailing,
    }) {
        return Material(
            color: selected ? ClassicPalette.selection : ClassicPalette.panel,
            child: InkWell(
                onTap: onTap,
                child: Container(
                    constraints: const BoxConstraints(minHeight: 54),
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: ClassicPalette.border)),
                    ),
                    child: Row(
                        children: [
                            SizedBox(width: 34, child: Align(alignment: Alignment.centerLeft, child: leading)),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Text(
                                            title,
                                            style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                                color: selected ? ClassicPalette.link : ClassicPalette.ink,
                                            ),
                                        ),
                                        if (subtitle != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                                subtitle,
                                                style: const TextStyle(fontSize: 10.5, height: 1.2, color: ClassicPalette.muted),
                                            ),
                                        ],
                                    ],
                                ),
                            ),
                            if (trailing != null) ...[const SizedBox(width: 6), trailing],
                        ],
                    ),
                ),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return ShortcutHandler(
            paste: (context) => CallbackPasteImageAction((intent, clipboardImages) {
                final isFirstEmptyAndIsSelectingFirst = preset.pages!.first.image == null && imagePage == 0;
                List<File> images = clipboardImages;
                if(isFirstEmptyAndIsSelectingFirst) {
                    final firstFile = images.removeAt(0);
                    preset.pages!.first.image = firstFile;
                    updatePreset.update();
                }
                addMultipleImages(images);
                setState(() => imagePage = preset.pages!.length - 1);
                _scaffoldKey.currentState!.closeEndDrawer();
            },),
            child: OrientationBuilder(
                builder: (context, _) => Scaffold(
                    key: _scaffoldKey,
                    appBar: AppBar(
                        toolbarHeight: 46,
                        backgroundColor: ClassicPalette.pageDeep,
                        foregroundColor: ClassicPalette.ink,
                        titleSpacing: 10,
                        title: Row(
                            children: [
                                Image.asset(
                                    'assets/classic_deviantart/custom/submit_arrow.png',
                                    width: 22,
                                    height: 22,
                                    filterQuality: FilterQuality.medium,
                                    isAntiAlias: true,
                                ),
                                const SizedBox(width: 8),
                                Text(imagePage >= 0 ? (preset.pages![imagePage].replaceID != null ? 'Edit Deviation' : 'Submit') : 'Bulk Submit',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                                if(imagePage >= 0) ...[
                                    const SizedBox(width: 9),
                                    Flexible(
                                        child: Text(
                                            generateName(preset.pages![imagePage]),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 10.5, color: ClassicPalette.muted, fontWeight: FontWeight.w400),
                                        ),
                                    ),
                                ],
                            ],
                        ),
                        actions: [
                            Tooltip(
                                message: preset.pages!.length > 1 || saveCollection
                                    ? "${preset.pages!.length} images will be added${saveCollection ? " and put inside a new collection" : ""}"
                                    : "Add images in bulk",
                                child: InkWell(
                                    onTap: () => _scaffoldKey.currentState!.openEndDrawer(),
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Row(
                                            children: [
                                                const ClassicSpriteIcon(index: 13, size: 20),
                                                if(preset.pages!.length > 1) ...[
                                                    const SizedBox(width: 3),
                                                    Text('${preset.pages!.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                                ],
                                            ],
                                        ),
                                    ),
                                ),
                            ),
                            Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Center(
                                    child: ClassicBevelButton(
                                        label: isSaving ? 'Saving...' : (imagePage >= 0 && preset.pages![imagePage].replaceID != null ? 'Save Changes' : 'Submit'),
                                        leading: const ClassicActionIcon('submit', size: 17),
                                        accent: true,
                                        onPressed: !isSaving && !hasError() ? saveImages : null,
                                    ),
                                ),
                            ),
                        ],
                        bottom: isSaving ? AppBarLinearProgressIndicator(value: savedImages != 0 ? savedImages / preset.pages!.length : null) : null,
                    ),
                    endDrawer: SizedBox(
                        width: MediaQuery.of(context).size.width < 400 ? MediaQuery.of(context).size.width * .92 : 360,
                        child: Drawer(
                            child: Container(
                                color: ClassicPalette.page,
                                child: SafeArea(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                            Container(
                                                height: 42,
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [Color(0xFFC9D8C6), ClassicPalette.panelHeader],
                                                    ),
                                                    border: Border(bottom: BorderSide(color: ClassicPalette.border)),
                                                ),
                                                child: const Row(
                                                    children: [
                                                        ClassicSpriteIcon(index: 28, size: 20),
                                                        SizedBox(width: 7),
                                                        Text('Bulk Adding', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                                    ],
                                                ),
                                            ),
                                            Container(
                                                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                                                color: const Color(0xFFDCE7D8),
                                                child: const Text(
                                                    'Choose, arrange and edit the files in this submission.',
                                                    style: TextStyle(fontSize: 10.8, height: 1.25, color: ClassicPalette.muted),
                                                ),
                                            ),
                                            Expanded(
                                                child: ListView(
                                                    padding: EdgeInsets.zero,
                                                    children: [
                                                        _classicBulkDrawerRow(
                                                            leading: const ClassicSpriteIcon(index: 28, size: 22),
                                                            title: 'Manage images',
                                                            subtitle: 'Batch options and collection settings',
                                                            selected: imagePage == -1,
                                                            onTap: imagePage == -1 ? null : () {
                                                                setState(() => imagePage = -1);
                                                                _scaffoldKey.currentState!.closeEndDrawer();
                                                            },
                                                        ),
                                                        Container(
                                                            padding: const EdgeInsets.fromLTRB(12, 9, 12, 5),
                                                            child: const Text(
                                                                'DEVIATIONS',
                                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ClassicPalette.muted),
                                                            ),
                                                        ),
                                                        ...List.generate(preset.pages!.length, (index) => _classicBulkDrawerRow(
                                                            leading: const ClassicSpriteIcon(index: 0, size: 22),
                                                            title: generateName(preset.pages![index]),
                                                            subtitle: preset.pages![index].replaceID != null ? 'Editing an existing deviation' : 'New deviation',
                                                            selected: imagePage == index,
                                                            onTap: imagePage == index ? null : () {
                                                                setState(() => imagePage = index);
                                                                _scaffoldKey.currentState!.closeEndDrawer();
                                                            },
                                                            trailing: preset.pages!.length == 1 ? null : IconButton(
                                                                tooltip: 'Remove',
                                                                visualDensity: VisualDensity.compact,
                                                                icon: const ClassicActionIcon('delete', size: 17),
                                                                onPressed: () {
                                                                    preset.pages!.removeAt(index);
                                                                    if (errorOnPages.length > index + 1) errorOnPages.removeAt(index + 1);
                                                                    setState(() => imagePage = imagePage >= index ? imagePage - 1 : imagePage);
                                                                },
                                                            ),
                                                        )),
                                                        Container(
                                                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 5),
                                                            child: const Text(
                                                                'ADD ARTWORK',
                                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ClassicPalette.muted),
                                                            ),
                                                        ),
                                                        _classicBulkDrawerRow(
                                                            leading: const ClassicSpriteIcon(index: 32, size: 22),
                                                            title: 'Add image',
                                                            subtitle: 'Choose one or more files from disk',
                                                            selected: false,
                                                            onTap: () async {
                                                                final files = await selectFileModal(context: context);
                                                                if (files != null) {
                                                                    addMultipleImages(files);
                                                                    setState(() => imagePage = preset.pages!.length - 1);
                                                                    _scaffoldKey.currentState!.closeEndDrawer();
                                                                }
                                                            },
                                                        ),
                                                        _classicBulkDrawerRow(
                                                            leading: const ClassicSpriteIcon(index: 45, size: 22),
                                                            title: 'Edit existing image',
                                                            subtitle: 'Add a stored deviation to this editing batch',
                                                            selected: false,
                                                            onTap: () async {
                                                                final images = await openSelectionDialog(
                                                                    context: context,
                                                                    excludeImages: preset.pages!
                                                                        .where((imagePreset) => imagePreset.replaceID != null)
                                                                        .map((imagePreset) => imagePreset.replaceID!)
                                                                        .toList(),
                                                                );
                                                                if (images == null) return;
                                                                final booru = await getCurrentBooru();
                                                                preset.pages!.addAll(await Future.wait(images.map((id) async {
                                                                    final image = await PresetImage.fromExistingImage((await booru.getImage(id))!);
                                                                    errorOnPages.add(false);
                                                                    return image;
                                                                })));
                                                                setState(() => imagePage = preset.pages!.length - 1);
                                                                _scaffoldKey.currentState!.closeEndDrawer();
                                                            },
                                                        ),
                                                        _classicBulkDrawerRow(
                                                            leading: const ClassicSpriteIcon(index: 13, size: 22),
                                                            title: 'Import from external website',
                                                            subtitle: 'Download artwork from a supported URL',
                                                            selected: false,
                                                            onTap: () async {
                                                                final url = await showDialog<String>(
                                                                    context: context,
                                                                    builder: (context) => const InsertURLDialog(),
                                                                );
                                                                if (url == null) return;
                                                                final downloadedPreset = await importImageFromURL(url);
                                                                if (downloadedPreset is PresetImage) {
                                                                    preset.pages!.add(downloadedPreset);
                                                                    errorOnPages.add(false);
                                                                } else if (downloadedPreset is VirtualPresetCollection) {
                                                                    final presets = downloadedPreset.pages;
                                                                    if (presets == null) return;
                                                                    preset.pages!.addAll(presets);
                                                                    errorOnPages.addAll(presets.map((preset) => preset.image == null || preset.tags == null));
                                                                }
                                                                setState(() => imagePage = preset.pages!.length - 1);
                                                                _scaffoldKey.currentState!.closeEndDrawer();
                                                            },
                                                        ),
                                                    ],
                                                ),
                                            ),
                                            Container(
                                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                                decoration: const BoxDecoration(
                                                    color: Color(0xFFF2EDCF),
                                                    border: Border(top: BorderSide(color: Color(0xFFC8B96B))),
                                                ),
                                                child: Text(
                                                    '${preset.pages!.length} image${preset.pages!.length == 1 ? '' : 's'} in this batch',
                                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF6D5A20)),
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    ),
                    body: PopScope(
                        canPop: false,
                        onPopInvokedWithResult: (didPop, _) {
                            if(didPop) return;
                            if(imagePage == 0) {
                                context.pop();
                            } else {
                                setState(() => imagePage = 0);
                            }
                        },
                        child: IndexedStack(
                            index: imagePage + 1,
                            children: [
                                GeneralCollectionManagerScreen(
                                    displayImages: List<ImageProvider?>.generate(3, (index) => preset.pages!.asMap().containsKey(index) && preset.pages![index].image != null ? FileImage(preset.pages![index].image!) : null,),
                                    corelated: isCorelated,
                                    onCorelatedChanged: (value) => setState(() => isCorelated = value),
                                    saveCollectionToggle: saveCollection,
                                    onSaveCollectionToggle: (value) => setState(() => saveCollection = value),
                                    collection: preset,
                                    onErrorChange: (value) => setState(() => errorOnPages[0] = value),
                                    onMultiCompress: compressAllImages,
                                    progressMultiCompress: progressCompressedImages,
                                    onManageImages: () => _scaffoldKey.currentState!.openEndDrawer(),
                                    // progressMultiCompress: 0.5,
                                ),
                                for (final (index, imagePreset) in preset.pages!.indexed) ImageManagerForm(
                                    preset: imagePreset,
                                    updateNotifier: updatePreset,
                                    onChanged: (imagePreset) => setState(() => preset.pages![index] = imagePreset),
                                    onErrorUpdate: (containsError) => setState(() => errorOnPages[index + 1] = containsError),
                                    onMultipleImagesAdded: addMultipleImages,
                                    showRelatedImagesCard: !isCorelated,
                                )
                            ],
                        ),
                    ),
                    // floatingActionButton: FloatingActionButton(onPressed: () => debugPrint("$errorOnPages"),),
                )
            ),
        );
    }
}

abstract class ManageImageSendable {}
class PresetManageImageSendable extends ManageImageSendable {
    PresetManageImageSendable(this.preset);
    PresetImage preset;
}
class PresetListManageImageSendable extends ManageImageSendable {
    PresetListManageImageSendable(this.presets);
    List<PresetImage> presets;
}
class VirtualPresetManageImageSendable extends ManageImageSendable {
    VirtualPresetManageImageSendable(this.preset);
    VirtualPresetCollection preset;
}

ManageImageSendable handleSendable(VirtualPreset preset) {
    if(preset is VirtualPresetCollection) return VirtualPresetManageImageSendable(preset);
    else return PresetManageImageSendable(preset as PresetImage);
}