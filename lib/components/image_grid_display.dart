import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/compressor.dart';
import 'package:localbooru/utils/shared_prefs_widget.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';


class SliverRepoGrid extends StatefulWidget {
    const SliverRepoGrid({super.key, required this.images, this.onPressed, this.onLongPress, this.onContextMenu, this.autoadjustColumns, this.imageQualityScale, this.dragOutside = false, this.selectedElements = const [], this.isSelection = false});

    final List<BooruImage> images;
    final Function(BooruImage image)? onPressed;
    final Function(BooruImage image)? onLongPress;
    final Function(Offset offset, BooruImage image)? onContextMenu;
    final int? autoadjustColumns;
    final double? imageQualityScale;
    final bool dragOutside;
    final List<ImageID> selectedElements;
    final bool isSelection;

    @override
    State<SliverRepoGrid> createState() => _SliverRepoGridState();
}

class _SliverRepoGridState extends State<SliverRepoGrid> {
    late LongPressDownDetails longTap;

    @override
    Widget build(BuildContext context) {
        final width = MediaQuery.of(context).size.width;
        final density = widget.autoadjustColumns ?? settingsDefaults['grid_size'];
        int columns = (width / ((20 * 50) / density)).ceil();
        if (columns < 2) columns = 2;
        if (columns > 8) columns = 8;

        final resizeSize = (width / columns) + 16;

        if(widget.images.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 0.78,
                mainAxisSpacing: 10,
                crossAxisSpacing: 8,
            ),
            delegate: SliverChildListDelegate(widget.images.map((image) {
                return SharedPreferencesBuilder(
                    key: ValueKey(image.id),
                    builder: (_, prefs) {
                        final quality = widget.imageQualityScale ?? (prefs.getDouble('thumbnail_quality') ?? settingsDefaults['thumbnail_quality']);
                        final Widget dragWidget = GestureDetector(
                            onTap: () {if(widget.onPressed != null) widget.onPressed!(image);},
                            onLongPress: () {if(widget.onLongPress != null) widget.onLongPress!(image);},
                            onLongPressDown: (tap) => longTap = tap,
                            onSecondaryTapDown: (tap) {
                                if(widget.onContextMenu != null) {
                                    widget.onContextMenu!(getOffsetRelativeToBox(offset: tap.globalPosition, renderObject: context.findRenderObject()!), image);
                                }
                            },
                            child: ImageGrid(
                                image: image,
                                resizeSize: resizeSize * quality,
                                selected: widget.selectedElements.contains(image.id),
                                showSelectionCheckbox: widget.isSelection,
                                showCaption: true,
                            )
                        );

                        return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: !widget.dragOutside ? dragWidget : DragItemWidget(
                                dragItemProvider: (request) {
                                    final item = DragItem(
                                        localData: {'context': 'image_grid'},
                                        suggestedName: image.filename
                                    );
                                    final format = SuperFormats.getFormatFromFileExtension(p.extension(image.filename));
                                    if(format != null) item.add(format.lazy(image.getImage().readAsBytes));
                                    return item;
                                },
                                allowedOperations: () => [DropOperation.copy],
                                child: DraggableWidget(child: dragWidget),
                            )
                        );
                    }
                );
            }).toList()),
        );
    }
}

class ImageGrid extends StatefulWidget {
    const ImageGrid({super.key, required this.image, this.resizeSize, this.selected = false, this.showSelectionCheckbox = false, this.showCaption = false});
    final BooruImage image;
    final double? resizeSize;
    final bool selected;
    final bool showSelectionCheckbox;
    final bool showCaption;

    @override
    State<ImageGrid> createState() => _ImageGridState();
}

class _ImageGridState extends State<ImageGrid> {
    late Future<File> imageThumbnail;

    String getType(String filename) {
        final mime = lookupMimeType(filename) ?? 'image/unknown';
        if(mime.startsWith('video')) return 'video';
        if(mime.startsWith('image/gif')) return 'gif';
        return 'image';
    }

    String get displayTitle {
        final note = widget.image.note?.trim();
        if (note != null && note.isNotEmpty) {
            final first = note.split('\n').first.trim();
            if (first.isNotEmpty && first.length <= 72) return first;
        }
        final raw = p.basenameWithoutExtension(widget.image.filename).replaceAll(RegExp(r'[_-]+'), ' ').trim();
        return raw.isEmpty ? 'Untitled deviation' : raw;
    }

    String get subtitle {
        final tags = widget.image.tags.split(' ').where((e) => e.trim().isNotEmpty).toList();
        if (tags.isNotEmpty) return 'in ${tags.first.replaceAll('_', ' ')}';
        return 'in LocalBooru';
    }

    @override
    void initState() {
        super.initState();
        imageThumbnail = getImageThumbnail(widget.image);
    }

    @override
    Widget build(context) {
        final imageType = getType(widget.image.filename);
        final Widget imageFrame = Center(
                child: AnimatedScale(
                    scale: widget.selected ? 0.93 : 1,
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOut,
                    child: Container(
                        constraints: const BoxConstraints(minWidth: 54, minHeight: 54),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF7F8F5),
                            border: Border.all(color: widget.selected ? ClassicPalette.link : ClassicPalette.borderDark, width: widget.selected ? 2 : 1),
                            boxShadow: const [
                                BoxShadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(1, 2)),
                            ],
                        ),
                        child: Stack(
                            fit: StackFit.expand,
                            children: [
                                FutureBuilder<File>(
                                    future: imageThumbnail,
                                    builder: (context, snapshot) {
                                        if(snapshot.hasData) {
                                            final thumbnail = snapshot.data!;
                                            final hasResize = widget.resizeSize != null;
                                            final ImageProvider provider = hasResize ? ResizeImage(
                                                FileImage(thumbnail),
                                                width: widget.resizeSize!.ceil(),
                                                height: widget.resizeSize!.ceil(),
                                                policy: ResizeImagePolicy.fit,
                                            ) : FileImage(thumbnail) as ImageProvider;
                                            return Image(image: provider, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
                                        }
                                        if(snapshot.hasError) {
                                            return const Center(child: Opacity(opacity: .55, child: ClassicSpriteIcon(index: 0, size: 28)));
                                        }
                                        return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
                                    },
                                ),
                                if(imageType != 'image') Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: ClassicPalette.headerBottom.withOpacity(.88),
                                            border: Border.all(color: ClassicPalette.headerBorder),
                                            borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                                imageType == 'video' ? const ClassicSpriteIcon(index: 2, size: 12) : const ClassicSpriteIcon(index: 0, size: 12),
                                                const SizedBox(width: 3),
                                                Text(imageType.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                                            ],
                                        ),
                                    ),
                                ),
                                if(widget.selected || widget.showSelectionCheckbox) Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                        width: 21,
                                        height: 21,
                                        decoration: BoxDecoration(
                                            color: widget.selected ? ClassicPalette.accent : const Color(0xDDF5F7F3),
                                            border: Border.all(color: widget.selected ? ClassicPalette.accentDark : ClassicPalette.borderDark),
                                            borderRadius: BorderRadius.circular(3),
                                        ),
                                        alignment: Alignment.center,
                                        child: widget.selected ? const Text('✓', style: TextStyle(color: ClassicPalette.ink, fontSize: 15, fontWeight: FontWeight.w800)) : null,
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            );

        if (!widget.showCaption) {
            return SizedBox.expand(child: imageFrame);
        }

        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Expanded(child: imageFrame),
                    const SizedBox(height: 7),
                    Text(
                        displayTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: ClassicPalette.link, fontSize: 12, fontWeight: FontWeight.w700, height: 1.05),
                    ),
                    const SizedBox(height: 2),
                    Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: ClassicPalette.ink, fontSize: 10, height: 1.0),
                    ),
                ],
            ),
        );
    }
}
