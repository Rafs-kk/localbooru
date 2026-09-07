import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/search_tag.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/views/navigation/tag_browse.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<ImageID>?> openSelectionDialog({required BuildContext context, List<ImageID>? selectedImages, List<ImageID>? excludeImages}) async {
    final booru = await getCurrentBooru();
    if(!context.mounted) return null;
    return showDialog<List<ImageID>>(
        context: context,
        builder: (context) => SelectDialog(booru: booru, selectedImages: selectedImages, excludeImages: excludeImages),
    );
}

class SelectDialog extends StatefulWidget {
    const SelectDialog({super.key, required this.booru, this.selectedImages, this.excludeImages});

    final Booru booru;
    final List<ImageID>? selectedImages;
    final List<ImageID>? excludeImages;

    @override
    State<SelectDialog> createState() => _SelectDialogState();
}

class _SelectDialogState extends State<SelectDialog> {
    final SearchTagController controller = SearchTagController();
    List<ImageID> imageIDs = [];
    String tags = '';

    @override
    void initState() {
        super.initState();
        imageIDs = List<ImageID>.from(widget.selectedImages ?? const []);
    }

    void onSearch() => setState(() => tags = controller.text);

    @override
    Widget build(context) {
        return OrientationBuilder(
            builder: (context, orientation) {
                final screen = MediaQuery.sizeOf(context);
                final width = orientation == Orientation.landscape ? screen.width * .72 : screen.width - 28;
                final height = screen.height * .78;
                return ClassicDialogFrame(
                    title: 'Select Deviations',
                    icon: const ClassicActionIcon('collection', size: 20),
                    width: width,
                    maxWidth: width,
                    contentPadding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
                    child: SizedBox(
                        height: height.clamp(420.0, 720.0).toDouble(),
                        child: Column(
                            children: [
                                SizedBox(
                                    height: 36,
                                    child: SearchTagBox(
                                        controller: controller,
                                        onSearch: (_) => onSearch(),
                                        hint: imageIDs.isNotEmpty ? 'Selected: ${imageIDs.length}' : 'Search deviations…',
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        classicStyle: orientation == Orientation.landscape,
                                    ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                    child: ClipRect(
                                        child: GalleryViewer(
                                            key: ValueKey(tags),
                                            searcher: (index) async {
                                                final prefs = await SharedPreferences.getInstance();
                                                final booru = await getCurrentBooru();
                                                final indexSize = prefs.getInt('page_size') ?? settingsDefaults['page_size'];
                                                final finalTags = [tags, ...(widget.excludeImages ?? []).map((e) => '-id:$e')].join(' ');
                                                final indexLength = await booru.getIndexNumberLength(finalTags, size: indexSize);
                                                final images = await booru.searchByTags(finalTags, index: index, size: indexSize);
                                                return SearchableInformation(images: images, indexLength: indexLength);
                                            },
                                            selectionMode: true,
                                            selectedImages: imageIDs,
                                            onSelect: (images) => setState(() => imageIDs = images),
                                            displayBackButton: false,
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                    actions: [
                        ClassicBevelButton(label: 'Cancel', onPressed: Navigator.of(context).pop),
                        ClassicBevelButton(label: 'Select (${imageIDs.length})', accent: true, onPressed: () => Navigator.of(context).pop(imageIDs)),
                    ],
                );
            },
        );
    }
}
