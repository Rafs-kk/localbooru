import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/views/image_manager/components/tagfield.dart';

class TagTypesSettings extends StatefulWidget {
    const TagTypesSettings({super.key, required this.booru});

    final Booru booru;

    @override
    State<TagTypesSettings> createState() => _TagTypesSettingsState();
}

class _TagTypesSettingsState extends State<TagTypesSettings> {
    final _formKey = GlobalKey<FormState>();

    final artistTagController = TextEditingController();
    final characterTagController = TextEditingController();
    final copyrightTagController = TextEditingController();
    final speciesTagController = TextEditingController();

    bool _loading = true;
    Object? _loadError;

    @override
    void initState() {
        super.initState();
        _loadTagTypes();
    }

    Future<void> _loadTagTypes() async {
        try {
            final rawInfo = await widget.booru.getRawInfo();
            final dynamic specificTagsValue = rawInfo["specificTags"];
            final Map<dynamic, dynamic> separatedTags = specificTagsValue is Map
                ? specificTagsValue
                : const <dynamic, dynamic>{};

            String tagsFor(String key) {
                final dynamic value = separatedTags[key];
                if (value is Iterable) {
                    return value
                        .map((tag) => tag.toString())
                        .where((tag) => tag.isNotEmpty)
                        .join(" ");
                }
                return "";
            }

            if (!mounted) return;
            setState(() {
                artistTagController.text = tagsFor("artist");
                characterTagController.text = tagsFor("character");
                copyrightTagController.text = tagsFor("copyright");
                speciesTagController.text = tagsFor("species");
                _loading = false;
                _loadError = null;
            });
        } catch (error, stackTrace) {
            debugPrint("[TagTypesSettings] Failed to load specificTags: $error");
            debugPrintStack(stackTrace: stackTrace);
            if (!mounted) return;
            setState(() {
                _loading = false;
                _loadError = error;
            });
        }
    }

    @override
    void dispose() {
        artistTagController.dispose();
        characterTagController.dispose();
        copyrightTagController.dispose();
        speciesTagController.dispose();
        super.dispose();
    }

    List<String> _parseTags(String text) => text
        .split(RegExp(r'\s+'))
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    String? validateTagTexts(String? value, String type) {
        final candidate = _parseTags(value ?? '').toSet();
        if (candidate.isEmpty) return null;

        final controllers = <String, TextEditingController>{
            'artist': artistTagController,
            'character': characterTagController,
            'copyright': copyrightTagController,
            'species': speciesTagController,
        };
        for (final entry in controllers.entries) {
            if (entry.key == type) continue;
            if (_parseTags(entry.value.text).toSet().intersection(candidate).isNotEmpty) {
                return "Overlapping tags exist with the ${entry.key} field";
            }
        }
        return null;
    }

    Future<void> _save() async {
        if (!(_formKey.currentState?.validate() ?? false)) return;
        await writeSpecificTags({
            "artist": _parseTags(artistTagController.text),
            "character": _parseTags(characterTagController.text),
            "copyright": _parseTags(copyrightTagController.text),
            "species": _parseTags(speciesTagController.text),
        });
        if (!mounted) return;
        classicSafeBack(context, fallback: '/settings/booru');
    }

    @override
    Widget build(BuildContext context) {
        if (_loading) {
            return const Center(child: CircularProgressIndicator());
        }

        if (_loadError != null) {
            return ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                children: [
                    ClassicPanel(
                        title: 'Tag Types',
                        icon: Icons.label_outline,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                const Text(
                                    'LocalBooru could not read the tag classifications for this collection.',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                    '$_loadError',
                                    style: const TextStyle(fontSize: 11, color: ClassicPalette.muted),
                                ),
                                const SizedBox(height: 10),
                                ClassicBevelButton(
                                    label: 'Retry',
                                    onPressed: () {
                                        setState(() {
                                            _loading = true;
                                            _loadError = null;
                                        });
                                        _loadTagTypes();
                                    },
                                ),
                            ],
                        ),
                    ),
                ],
            );
        }

        return Form(
            key: _formKey,
            child: ListView(
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
                                    height: 31,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: const BoxDecoration(
                                        color: Color(0xFFAAB9AC),
                                        border: Border(bottom: BorderSide(color: ClassicPalette.borderDark)),
                                    ),
                                    child: const Row(
                                        children: [
                                            Image(
                                                image: AssetImage('assets/classic_deviantart/search_terms/general.png'),
                                                width: 18,
                                                height: 18,
                                                filterQuality: FilterQuality.medium,
                                                isAntiAlias: true,
                                            ),
                                            SizedBox(width: 7),
                                            Text('Tag Types', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                                            Spacer(),
                                            Text('LocalBooru tag classification', style: TextStyle(fontSize: 10.5, color: ClassicPalette.muted)),
                                        ],
                                    ),
                                ),
                                Container(
                                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                                    color: const Color(0xFFD4DED2),
                                    child: const Text(
                                        'Assign existing tags to a category by typing them into the matching field. Remove a tag from every field to return it to General. A tag can only belong to one category at a time.',
                                        style: TextStyle(fontSize: 11.5, height: 1.25),
                                    ),
                                ),
                                const _ForumTableHeader(),
                                _TagTypeForumRow(
                                    asset: 'assets/classic_deviantart/search_terms/artist.png',
                                    title: 'Artist(s)',
                                    subtitle: 'Names of artists or creators',
                                    color: SpecificTagsColors.artist,
                                    child: TagField(
                                        controller: artistTagController,
                                        decoration: const InputDecoration(hintText: 'artist_name another_artist'),
                                        type: 'generic',
                                        validator: (value) => validateTagTexts(value, 'artist'),
                                        style: const TextStyle(color: SpecificTagsColors.artist, fontWeight: FontWeight.w600),
                                    ),
                                ),
                                _TagTypeForumRow(
                                    asset: 'assets/classic_deviantart/search_terms/character.png',
                                    title: 'Character(s)',
                                    subtitle: 'Characters appearing in deviations',
                                    color: SpecificTagsColors.character,
                                    child: TagField(
                                        controller: characterTagController,
                                        decoration: const InputDecoration(hintText: 'character_name'),
                                        type: 'generic',
                                        validator: (value) => validateTagTexts(value, 'character'),
                                        style: const TextStyle(color: SpecificTagsColors.character, fontWeight: FontWeight.w600),
                                    ),
                                ),
                                _TagTypeForumRow(
                                    asset: 'assets/classic_deviantart/search_terms/copyright.png',
                                    title: 'Copyright',
                                    subtitle: 'Series, franchise or copyright holders',
                                    color: SpecificTagsColors.copyright,
                                    child: TagField(
                                        controller: copyrightTagController,
                                        decoration: const InputDecoration(hintText: 'franchise series_name'),
                                        type: 'generic',
                                        validator: (value) => validateTagTexts(value, 'copyright'),
                                        style: const TextStyle(color: SpecificTagsColors.copyright, fontWeight: FontWeight.w600),
                                    ),
                                ),
                                _TagTypeForumRow(
                                    asset: 'assets/classic_deviantart/search_terms/species.png',
                                    title: 'Species',
                                    subtitle: 'Species or creature classification',
                                    color: SpecificTagsColors.species,
                                    child: TagField(
                                        controller: speciesTagController,
                                        decoration: const InputDecoration(hintText: 'species_name'),
                                        type: 'generic',
                                        validator: (value) => validateTagTexts(value, 'species'),
                                        style: const TextStyle(color: SpecificTagsColors.species, fontWeight: FontWeight.w600),
                                    ),
                                ),
                                Container(
                                    padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                                    decoration: const BoxDecoration(
                                        color: Color(0xFFDCE5D9),
                                        border: Border(top: BorderSide(color: ClassicPalette.border)),
                                    ),
                                    child: const Row(
                                        children: [
                                            Image(
                                                image: AssetImage('assets/classic_deviantart/search_terms/general.png'),
                                                width: 18,
                                                height: 18,
                                                filterQuality: FilterQuality.medium,
                                                isAntiAlias: true,
                                            ),
                                            SizedBox(width: 7),
                                            Expanded(child: Text('General tags are everything not assigned above.', style: TextStyle(fontSize: 11, color: ClassicPalette.muted))),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                        alignment: Alignment.centerRight,
                        child: ClassicBevelButton(
                            label: 'Save Changes',
                            leading: const ClassicSpriteIcon(index: 11, size: 17),
                            accent: true,
                            onPressed: _save,
                        ),
                    ),
                ],
            ),
        );
    }
}

class _ForumTableHeader extends StatelessWidget {
    const _ForumTableHeader();

    @override
    Widget build(BuildContext context) {
        return Container(
            height: 27,
            decoration: const BoxDecoration(
                color: Color(0xFF9DAC9F),
                border: Border(top: BorderSide(color: ClassicPalette.borderDark), bottom: BorderSide(color: ClassicPalette.borderDark)),
            ),
            child: const Row(
                children: [
                    SizedBox(width: 230, child: Padding(padding: EdgeInsets.only(left: 10), child: Text('Tag type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)))),
                    VerticalDivider(width: 1, thickness: 1, color: ClassicPalette.borderDark),
                    Expanded(child: Padding(padding: EdgeInsets.only(left: 10), child: Text('Tags assigned to this type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)))),
                ],
            ),
        );
    }
}

class _TagTypeForumRow extends StatelessWidget {
    const _TagTypeForumRow({required this.asset, required this.title, required this.subtitle, required this.child, required this.color});

    final String asset;
    final String title;
    final String subtitle;
    final Widget child;
    final Color color;

    @override
    Widget build(BuildContext context) {
        // This row lives inside a vertical ListView. A ListView deliberately gives
        // its children an unbounded maximum height, so CrossAxisAlignment.stretch
        // would try to stretch the Row's children to an infinite height. Keep the
        // row content-sized instead and draw the column divider as a border.
        return Container(
            constraints: const BoxConstraints(minHeight: 68),
            decoration: const BoxDecoration(
                color: Color(0xFFCFD9CD),
                border: Border(bottom: BorderSide(color: ClassicPalette.border)),
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Container(
                        width: 230,
                        constraints: const BoxConstraints(minHeight: 68),
                        padding: const EdgeInsets.fromLTRB(10, 9, 8, 8),
                        decoration: const BoxDecoration(
                            border: Border(right: BorderSide(color: ClassicPalette.border)),
                        ),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                SizedBox.square(
                                    dimension: 26,
                                    child: Image.asset(
                                        asset,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.medium,
                                        isAntiAlias: true,
                                    ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                                            const SizedBox(height: 2),
                                            Text(subtitle, style: const TextStyle(fontSize: 10.5, color: ClassicPalette.muted, height: 1.2)),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                    ),
                    Expanded(
                        child: Container(
                            constraints: const BoxConstraints(minHeight: 68),
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
                            alignment: Alignment.topLeft,
                            child: child,
                        ),
                    ),
                ],
            ),
        );
    }
}
