import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/api/tags/index.dart';
import 'package:localbooru/components/dialogs/image_selector_dialog.dart';
import 'package:localbooru/components/dialogs/radio_dialogs.dart';
import 'package:localbooru/components/classic_rating_icon.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/views/image_manager/components/image_upload.dart';
import 'package:localbooru/views/image_manager/components/list_string_text_input.dart';
import 'package:localbooru/views/image_manager/components/related_images.dart';
import 'package:localbooru/views/image_manager/components/tagfield.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageManagerForm extends StatefulWidget {
    const ImageManagerForm({super.key, this.preset, required this.onChanged, this.onMultipleImagesAdded, this.onErrorUpdate, this.showRelatedImagesCard = true, this.updateNotifier});

    final PresetImage? preset;
    final bool showRelatedImagesCard;
    final void Function(PresetImage preset) onChanged;
    final void Function(bool hasError)? onErrorUpdate;
    final void Function(List<File> files)? onMultipleImagesAdded;
    final ChangeNotifier? updateNotifier;

    @override
    State<ImageManagerForm> createState() => _ImageManagerFormState();
}

class _ImageManagerFormState extends State<ImageManagerForm> {
    final _formKey = GlobalKey<FormState>();

    final tagController = TextEditingController();
    final artistTagController = TextEditingController();
    final characterTagController = TextEditingController();
    final copyrightTagController = TextEditingController();
    final speciesTagController = TextEditingController();
    final noteController = TextEditingController();

    bool isEditing = false;
    bool isGeneratingTags = false;

    Rating? rating;
    List<String> urlList = [];
    String loadedImage = "";
    List<ImageID> relatedImages = [];

    @override
    void initState() {
        super.initState();
        isEditing = widget.preset?.replaceID != null;
        if(widget.preset != null) updateInformation(widget.preset!);
        if(widget.updateNotifier != null) widget.updateNotifier!.addListener(updateListenable);
    }

    @override
    void dispose() {
        tagController.dispose();
        artistTagController.dispose();
        characterTagController.dispose();
        copyrightTagController.dispose();
        speciesTagController.dispose();
        noteController.dispose();
        if(widget.updateNotifier != null) widget.updateNotifier!.removeListener(updateListenable);
        super.dispose();
    }

    void updateListenable() {
        if(widget.preset != null) updateInformation(widget.preset!);
    }

    void updateInformation(PresetImage preset) {
        if(preset.image != null) loadedImage = preset.image!.path;
        if(preset.sources != null) urlList = List<String>.from(preset.sources!);
        rating = preset.rating;
        relatedImages = List<ImageID>.from(preset.relatedImages ?? const <ImageID>[]);
        noteController.text = preset.note ?? '';

        if(preset.tags != null) {
            tagController.text = preset.tags!["generic"]?.join(" ") ?? "";
            artistTagController.text = preset.tags!["artist"]?.join(" ") ?? "";
            characterTagController.text = preset.tags!["character"]?.join(" ") ?? "";
            copyrightTagController.text = preset.tags!["copyright"]?.join(" ") ?? "";
            speciesTagController.text = preset.tags!["species"]?.join(" ") ?? "";
        }
    }

    List<String> _tagTokens(String text) {
        final seen = <String>{};
        final result = <String>[];
        for(final token in text.trim().split(RegExp(r'\s+'))) {
            final cleaned = token.trim();
            if(cleaned.isEmpty || !seen.add(cleaned)) continue;
            result.add(cleaned);
        }
        return result;
    }

    String _mergeTagText(String current, Iterable<String> additions) {
        final merged = <String>[];
        final seen = <String>{};
        for(final tag in [..._tagTokens(current), ...additions]) {
            final cleaned = tag.trim();
            if(cleaned.isEmpty || !seen.add(cleaned)) continue;
            merged.add(cleaned);
        }
        return merged.join(' ');
    }

    void sendPreset() {
        final validation = _formKey.currentState!.validate();
        widget.onChanged(PresetImage(
            image: File(loadedImage),
            tags: {
                "generic": _tagTokens(tagController.text),
                "artist": _tagTokens(artistTagController.text),
                "character": _tagTokens(characterTagController.text),
                "copyright": _tagTokens(copyrightTagController.text),
                "species": _tagTokens(speciesTagController.text),
            },
            sources: List<String>.from(urlList),
            rating: rating,
            replaceID: widget.preset?.replaceID,
            relatedImages: List<ImageID>.from(relatedImages),
            key: widget.preset?.key,
            note: noteController.text.trim().isEmpty ? null : noteController.text,
        ));
        if(widget.onErrorUpdate != null) widget.onErrorUpdate!(!validation);
    }

    void fetchTags() async {
        final prefs = await SharedPreferences.getInstance();
        setState(() => isGeneratingTags = true);
        autoTag(File(loadedImage)).then((tags) async {
            final moreAccurateTags = filterAccurateResults(tags, prefs.getDouble("autotag_accuracy") ?? settingsDefaults["autotag_accuracy"]);
            final separatedTags = await (await getCurrentBooru()).separateTagsByType(moreAccurateTags.keys.toList());

            if(separatedTags["generic"] != null) tagController.text = _mergeTagText(tagController.text, separatedTags["generic"]!);
            if(separatedTags["artist"] != null) artistTagController.text = _mergeTagText(artistTagController.text, separatedTags["artist"]!);
            if(separatedTags["character"] != null) characterTagController.text = _mergeTagText(characterTagController.text, separatedTags["character"]!);
            if(separatedTags["copyright"] != null) copyrightTagController.text = _mergeTagText(copyrightTagController.text, separatedTags["copyright"]!);
            if(separatedTags["species"] != null) speciesTagController.text = _mergeTagText(speciesTagController.text, separatedTags["species"]!);
            sendPreset();
        }).catchError((error, stackTrace) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not obtain tag information, ${error.toString()}')));
            throw error;
        }).whenComplete(() {
            if(mounted) setState(() => isGeneratingTags = false);
        });
    }

    String? validateTagTexts(String? value, String type) {
        final currentTags = _tagTokens(value ?? '');
        final tagSets = <String, Set<String>>{
            'generic': _tagTokens(tagController.text).toSet(),
            'artist': _tagTokens(artistTagController.text).toSet(),
            'character': _tagTokens(characterTagController.text).toSet(),
            'copyright': _tagTokens(copyrightTagController.text).toSet(),
            'species': _tagTokens(speciesTagController.text).toSet(),
        };

        for(final entry in tagSets.entries) {
            if(entry.key == type) continue;
            if(entry.value.intersection(currentTags.toSet()).isNotEmpty) {
                return "Overlapping tags exists with the ${entry.key} field";
            }
        }

        for(final tag in currentTags) {
            if(Metatag.isMetatag(tag)) return "Metatags cannot be added";
        }

        if(tagSets.values.every((tags) => tags.isEmpty)) return "Please insert a tag";
        return null;
    }

    Widget _upload(Orientation orientation) {
        return ImageUploadForm(
            onChanged: (value) {
                setState(() => loadedImage = value.first.path);
                sendPreset();
                if(value.length > 1 && widget.onMultipleImagesAdded != null) {
                    widget.onMultipleImagesAdded!(value.sublist(1));
                }
            },
            onCompressed: (value) {
                setState(() => loadedImage = value);
                sendPreset();
            },
            validator: (value) {
                if(value == null || value.isEmpty) return 'Please select an image';
                return null;
            },
            currentValue: loadedImage,
            orientation: orientation,
        );
    }

    Widget _detailsPanel() {
        final filename = loadedImage.isEmpty ? 'Choose an image first' : File(loadedImage).uri.pathSegments.last;
        return ClassicPanel(
            title: 'Deviation Details',
            icon: Icons.image_outlined,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    ClassicFieldLabel(
                        label: 'Title / filename',
                        child: InputDecorator(
                            decoration: const InputDecoration(),
                            child: Text(filename, style: TextStyle(color: loadedImage.isEmpty ? ClassicPalette.muted : ClassicPalette.ink)),
                        ),
                    ),
                    const SizedBox(height: 10),
                    ClassicFieldLabel(
                        label: 'Description / note',
                        child: TextFormField(
                            controller: noteController,
                            minLines: 3,
                            maxLines: 6,
                            decoration: const InputDecoration(
                                hintText: 'Write something about this deviation...',
                            ),
                            onChanged: (_) => sendPreset(),
                        ),
                    ),
                ],
            ),
        );
    }

    Widget _tagsPanel() {
        return ClassicPanel(
            title: 'Keywords / Tags',
            icon: Icons.sell_outlined,
            headerTrailing: TextButton(
                onPressed: (loadedImage.isEmpty || isGeneratingTags) ? null : fetchTags,
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Image.asset(
                            'assets/classic_deviantart/custom/generate_tags.png',
                            width: 17,
                            height: 17,
                            filterQuality: FilterQuality.medium,
                            isAntiAlias: true,
                        ),
                        const SizedBox(width: 4),
                        Text(isGeneratingTags ? 'Generating...' : 'Generate tags'),
                    ],
                ),
            ),
            child: Column(
                children: [
                    TagField(
                        controller: tagController,
                        decoration: const InputDecoration(labelText: "General"),
                        style: const TextStyle(color: SpecificTagsColors.generic),
                        validator: (value) => validateTagTexts(value, "generic"),
                        onChanged: (_) => sendPreset(),
                    ),
                    const SizedBox(height: 6),
                    TagField(
                        controller: artistTagController,
                        decoration: const InputDecoration(labelText: "Artist(s)"),
                        type: "artist",
                        style: const TextStyle(color: SpecificTagsColors.artist),
                        validator: (value) => validateTagTexts(value, "artist"),
                        onChanged: (_) => sendPreset(),
                    ),
                    const SizedBox(height: 6),
                    TagField(
                        controller: characterTagController,
                        decoration: const InputDecoration(labelText: "Character(s)"),
                        type: "character",
                        style: const TextStyle(color: SpecificTagsColors.character),
                        validator: (value) => validateTagTexts(value, "character"),
                        onChanged: (_) => sendPreset(),
                    ),
                    const SizedBox(height: 6),
                    TagField(
                        controller: copyrightTagController,
                        decoration: const InputDecoration(labelText: "Copyright"),
                        type: "copyright",
                        style: const TextStyle(color: SpecificTagsColors.copyright),
                        validator: (value) => validateTagTexts(value, "copyright"),
                        onChanged: (_) => sendPreset(),
                    ),
                    const SizedBox(height: 6),
                    TagField(
                        controller: speciesTagController,
                        decoration: const InputDecoration(labelText: "Species"),
                        type: "species",
                        style: const TextStyle(color: SpecificTagsColors.species),
                        validator: (value) => validateTagTexts(value, "species"),
                        onChanged: (_) => sendPreset(),
                    ),
                ],
            ),
        );
    }

    Widget _sourcesPanel() {
        return ClassicPanel(
            title: 'Sources',
            headerIcon: const ClassicCustomIcon('sources_book', size: 18),
            child: ListStringTextInput(
                addButtonLabel: "Add source",
                onChanged: (list) {
                    setState(() => urlList = list);
                    sendPreset();
                },
                canBeEmpty: true,
                defaultValue: urlList,
                formValidator: (value) {
                    if(value == null || value.isEmpty) return "Please either remove the URL or fill this field";
                    return null;
                },
            ),
        );
    }

    Widget _featuresPanel() {
        return ClassicPanel(
            title: 'Features',
            icon: Icons.tune,
            padding: EdgeInsets.zero,
            child: Column(
                children: [
                    InkWell(
                        onTap: () async {
                            await showDialog<void>(
                                context: context,
                                barrierDismissible: true,
                                builder: (_) => RatingChooserDialog(
                                    selected: rating,
                                    hasNull: true,
                                    onChanged: (value) {
                                        if(!mounted) return;
                                        setState(() => rating = value);
                                        sendPreset();
                                    },
                                ),
                            );
                        },
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    ClassicRatingIcon(rating: rating, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                const Text('Content rating', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                                const SizedBox(height: 2),
                                                Text(getRatingText(rating), style: const TextStyle(fontSize: 11, color: ClassicPalette.muted)),
                                            ],
                                        ),
                                    ),
                                    const Text('Change ›', style: TextStyle(fontSize: 11, color: ClassicPalette.link, fontWeight: FontWeight.w700)),
                                ],
                            ),
                        ),
                    ),
                    const Divider(height: 1),
                    Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                const ClassicSpriteIcon(index: 42, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            const Text('Automatic tags', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 2),
                                            const Text('Scan the selected artwork and suggest matching tags.', style: TextStyle(fontSize: 11, color: ClassicPalette.muted, height: 1.25)),
                                            const SizedBox(height: 7),
                                            ClassicBevelButton(
                                                label: isGeneratingTags ? 'Generating...' : 'Generate tags',
                                                leading: Image.asset(
                                                    'assets/classic_deviantart/custom/generate_tags.png',
                                                    width: 15,
                                                    height: 15,
                                                    filterQuality: FilterQuality.medium,
                                                    isAntiAlias: true,
                                                ),
                                                onPressed: (loadedImage.isEmpty || isGeneratingTags) ? null : fetchTags,
                                            ),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        );
    }

    Widget _relatedPanel() {
        return ClassicPanel(
            title: 'Related Deviations',
            icon: Icons.collections_outlined,
            child: RelatedImagesCard(
                showBlockWarning: !widget.showRelatedImagesCard,
                relatedImages: relatedImages,
                onRemove: (imageID) {
                    setState(() => relatedImages.remove(imageID));
                    sendPreset();
                },
                onAddButtonPress: () async {
                    final imageList = await openSelectionDialog(
                        context: context,
                        selectedImages: relatedImages,
                        excludeImages: widget.preset?.replaceID != null ? [widget.preset!.replaceID!] : null,
                    );
                    if(imageList == null) return;
                    setState(() => relatedImages = List<ImageID>.from(imageList));
                    sendPreset();
                },
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return OrientationBuilder(
            builder: (context, orientation) {
                final leftColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        const Text('Create Your Deviation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _upload(orientation),
                        const SizedBox(height: 12),
                        _detailsPanel(),
                        const SizedBox(height: 12),
                        _tagsPanel(),
                        const SizedBox(height: 12),
                        _sourcesPanel(),
                    ],
                );

                final rightColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        _featuresPanel(),
                        if(widget.showRelatedImagesCard) ...[
                            const SizedBox(height: 12),
                            _relatedPanel(),
                        ],
                        const SizedBox(height: 12),
                        const ClassicPanel(
                            title: 'LocalBooru Submit',
                            icon: Icons.info_outline,
                            child: Text(
                                'Your submission stays inside this local collection. Add the file, tags and optional metadata, then use Submit above to save it.',
                                style: TextStyle(fontSize: 10.5, height: 1.3, color: ClassicPalette.muted),
                            ),
                        ),
                    ],
                );

                return Form(
                    key: _formKey,
                    child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        children: [
                            Container(
                                margin: const EdgeInsets.only(bottom: 11),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1C8),
                                    border: Border.all(color: const Color(0xFFD4B56A)),
                                    borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                    isEditing ? 'Editing an existing deviation in your local collection.' : 'Welcome to the Submit Page! Add a new deviation to your local collection.',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF8C5D0E)),
                                ),
                            ),
                            if(orientation == Orientation.landscape)
                                Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Expanded(flex: 7, child: leftColumn),
                                        const SizedBox(width: 16),
                                        SizedBox(width: 330, child: rightColumn),
                                    ],
                                )
                            else ...[
                                leftColumn,
                                const SizedBox(height: 12),
                                rightColumn,
                            ],
                        ],
                    ),
                );
            },
        );
    }
}
