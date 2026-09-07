import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/tags/index.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';


String _classicSearchTermAsset(String type, bool isMetatag) {
    if (isMetatag) return 'assets/classic_deviantart/search_terms/search_option.png';
    return switch(type) {
        'artist' => 'assets/classic_deviantart/search_terms/artist.png',
        'character' => 'assets/classic_deviantart/search_terms/character.png',
        'copyright' => 'assets/classic_deviantart/search_terms/copyright.png',
        'species' => 'assets/classic_deviantart/search_terms/species.png',
        _ => 'assets/classic_deviantart/search_terms/general.png',
    };
}

class SearchTagBox extends StatefulWidget {
    const SearchTagBox({super.key, this.hint, required this.onSearch, this.controller, this.isFullScreen, this.actions, this.showShadow = false, this.leading = const ClassicCustomIcon('search', size: 18), this.padding = const EdgeInsets.only(left: 16.0, right: 10.0), this.backgroundColor, this.elevation, this.classicStyle = false});

    final String? hint;
    final Function(String value) onSearch;
    final SearchTagController? controller;
    final bool? isFullScreen;
    final List<Widget>? actions;
    final bool showShadow;
    final Widget? leading;
    final EdgeInsetsGeometry? padding;
    final Color? backgroundColor;
    final double? elevation;
    final bool classicStyle;

    @override
    State<SearchTagBox> createState() => _SearchTagBoxState();
}

class _SearchTagBoxState extends State<SearchTagBox> {
    SearchTagController _controller = SearchTagController();
    bool _ownsController = true;
    int _cacheGeneration = 0;

    Map<String, List<BooruTagCounterDisplay<Tag>>> tagsAndTypes = {};

    @override
    void initState() {
        super.initState();

        if(widget.controller != null) {
            _controller = widget.controller!;
            _ownsController = false;
        }

        booruUpdateListener.addListener(_handleBooruUpdate);
    }

    void _handleBooruUpdate() {
        _loadTags(refreshView: true);
    }

    @override
    void dispose() {
        booruUpdateListener.removeListener(_handleBooruUpdate);
        _cacheGeneration++;
        if (_ownsController) _controller.dispose();
        super.dispose();
    }

    Future<void> _loadTags({bool refreshView = false}) async {
        final int generation = ++_cacheGeneration;
        try {
            final Booru booru = await getCurrentBooru();
            final Map<String, BooruTagCounterDisplay<Tag>> tags = {};
            for(final tag in await booru.getAllTags()) {
                tags[tag.tag.text] = tag;
            }

            final categorizedTags = await booru.separateTagsByType(
                tags.values.map((e) => e.tag.getText()).toList(),
            );
            final Map<String, List<BooruTagCounterDisplay<Tag>>> rebuilt = {};
            for(final type in categorizedTags.entries) {
                final values = <BooruTagCounterDisplay<Tag>>[];
                for(final tagString in type.value) {
                    final display = tags[tagString];
                    if (display != null) values.add(display);
                }
                values.sort((a, b) => b.callQuantity.compareTo(a.callQuantity));
                rebuilt[type.key] = values;
            }
            rebuilt["metatag"] = List<BooruTagCounterDisplay<Tag>>.from(tagsToAddToSearch);

            if (!mounted || generation != _cacheGeneration) return;
            tagsAndTypes = rebuilt;
            if (refreshView) refreshSuggestions();
        } catch (error, stack) {
            if (!mounted || generation != _cacheGeneration) return;
            debugPrint('[SearchTags] Failed to refresh tag cache: $error');
            debugPrintStack(stackTrace: stack);
        }
    }

    void refreshSuggestions() {
        if (!mounted) return;
        final previousText = _controller.text;
        _controller.text = '\u200B$previousText'; // no good way to update the search
        _controller.text = previousText;
    }

    @override
    Widget build(BuildContext context) {
        return SearchAnchor(
            searchController: _controller,
            builder: (context, controller) => widget.classicStyle
                ? _ClassicDABrowseSearch(
                    controller: controller,
                    hint: widget.hint ?? 'Search',
                    onSearch: widget.onSearch,
                    onOpenSuggestions: controller.openView,
                )
                : SearchBar(
                    controller: controller,
                    hintText: widget.hint,
                    padding: WidgetStatePropertyAll(widget.padding),
                    onSubmitted: widget.onSearch,
                    onTap: controller.openView,
                    onChanged: (_) => controller.openView(),
                    leading: widget.leading,
                    trailing: [
                        // if(controller.text.isNotEmpty) IconButton(onPressed: _controller.clear, tooltip: 'Clear', icon: const Text('×', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                        if(widget.actions == null) SearchButton(controller: controller, onSearch: widget.onSearch, icon: const ClassicNavArrow.right(size: 13),)
                        else ...widget.actions!
                    ],
                    elevation: WidgetStatePropertyAll(widget.elevation),
                    shadowColor: widget.showShadow ? null : const WidgetStatePropertyAll(Colors.transparent),
                    backgroundColor: WidgetStatePropertyAll<Color?>(widget.backgroundColor),
                ),
            viewBuilder: widget.classicStyle
                ? (suggestions) => _ClassicDASearchSuggestionView(suggestions: suggestions)
                : null,
            viewLeading: widget.classicStyle
                ? _ClassicDASearchHeaderButton(
                    tooltip: 'Close search',
                    onTap: () => _controller.closeView(null),
                    child: const ClassicActionIcon('prev', size: 16),
                )
                : null,
            viewTrailing: widget.classicStyle
                ? [
                    _ClassicDASearchHeaderButton(
                        tooltip: 'Clear',
                        onTap: _controller.clear,
                        child: const Text(
                            '×',
                            style: TextStyle(
                                height: 1,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: ClassicPalette.ink,
                            ),
                        ),
                    ),
                    _ClassicDASearchHeaderButton(
                        tooltip: 'Search',
                        onTap: () => widget.onSearch(_controller.text),
                        child: Image.asset(
                            'assets/classic_deviantart/custom/search.png',
                            width: 17,
                            height: 17,
                            filterQuality: FilterQuality.medium,
                            isAntiAlias: true,
                        ),
                    ),
                ]
                : [
                    IconButton(onPressed: _controller.clear, tooltip: 'Clear', icon: const Text('×', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
                    SearchButton(controller: _controller, onSearch: widget.onSearch)
                ],
            viewHintText: widget.classicStyle ? (widget.hint ?? 'Search deviations...') : null,
            viewBackgroundColor: widget.classicStyle ? ClassicPalette.panel : null,
            viewSurfaceTintColor: widget.classicStyle ? Colors.transparent : null,
            viewElevation: widget.classicStyle ? 9 : null,
            viewSide: widget.classicStyle ? const BorderSide(color: ClassicPalette.borderDark, width: 1) : null,
            viewShape: widget.classicStyle
                ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                : null,
            viewBarPadding: widget.classicStyle
                ? const EdgeInsets.fromLTRB(7, 5, 7, 5)
                : null,
            headerHeight: widget.classicStyle ? 38 : null,
            headerTextStyle: widget.classicStyle
                ? const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 12,
                    height: 1,
                    color: ClassicPalette.ink,
                )
                : null,
            headerHintStyle: widget.classicStyle
                ? const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 12,
                    height: 1,
                    color: ClassicPalette.muted,
                )
                : null,
            dividerColor: widget.classicStyle ? ClassicPalette.borderDark : null,
            viewConstraints: widget.classicStyle
                ? const BoxConstraints(minWidth: 520, maxWidth: 760, maxHeight: 520)
                : null,
            viewPadding: widget.classicStyle ? EdgeInsets.zero : null,
            suggestionsBuilder: (context, controller) async {
                if(tagsAndTypes.isEmpty) await _loadTags();
                final tagsOnSearch = List<String>.from(controller.text.split(" "));

                // final filteredTags = Map<String, List<String>>.from(tagsAndTypes!)..retainWhere((s){
                //     return tagsOnSearch.last.isEmpty || s.contains(TagText(tagsOnSearch.last).text);
                // });

                final filteredTags = tagsAndTypes.map((type, tags) {
                    return MapEntry(type, tags.where((display) {
                        return tagsOnSearch.last.isEmpty
                               || display.tag.getText().contains(SearchTag.fromText(tagsOnSearch.last).tag.getText());
                    },));
                },);

                return filteredTags.entries.map((type) => type.value.map((display) {
                    final isMetatag = display.tag is Metatag;
                    final onTap = () {
                        final endResult = List<String>.from(tagsOnSearch)..removeLast()..add(display.tag.getText());
                        setState(() {
                            if(isMetatag && (display.tag as Metatag).value.isEmpty) controller.text = endResult.join(" ");
                            else controller.text = "${endResult.join(" ")} ";
                        });
                    };

                    if(widget.classicStyle) {
                        return _ClassicDASearchSuggestionRow(
                            text: display.tag.getText(),
                            type: type.key,
                            count: display.callQuantity,
                            isMetatag: isMetatag,
                            onTap: onTap,
                        );
                    }

                    final color = !isMetatag ? SpecificTagsColors.getColor(type.key) : null;
                    return ListTile(
                        leading: SizedBox.square(
                            dimension: 20,
                            child: Image.asset(
                                _classicSearchTermAsset(type.key, isMetatag),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                isAntiAlias: true,
                            ),
                        ),
                        title: Text(display.tag.getText(),
                            style: TextStyle(
                                color: color,
                                fontWeight: isMetatag ? FontWeight.bold : null
                            ),
                        ),
                        trailing: display.callQuantity > 0 ? Text("${display.callQuantity}") : null,
                        onTap: onTap,
                    );
                })).expand((i) => i);
            },
            isFullScreen: widget.isFullScreen,
        );
    }
}

class _ClassicDASearchSuggestionView extends StatelessWidget {
    const _ClassicDASearchSuggestionView({required this.suggestions});

    final Iterable<Widget> suggestions;

    @override
    Widget build(BuildContext context) {
        final items = suggestions.toList(growable: false);

        return DecoratedBox(
            decoration: const BoxDecoration(
                color: ClassicPalette.panel,
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Container(
                        height: 29,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFC9D8C6), ClassicPalette.panelHeader],
                            ),
                            border: Border(
                                bottom: BorderSide(color: ClassicPalette.border),
                            ),
                        ),
                        child: Row(
                            children: [
                                Image.asset(
                                    'assets/classic_deviantart/search_terms/search_option.png',
                                    width: 17,
                                    height: 17,
                                    filterQuality: FilterQuality.medium,
                                    isAntiAlias: true,
                                ),
                                SizedBox(width: 6),
                                Text(
                                    'Search Tags',
                                    style: TextStyle(
                                        fontFamily: 'Arial',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: ClassicPalette.ink,
                                    ),
                                ),
                                Spacer(),
                                Text(
                                    'Choose a suggestion to add it to your query',
                                    style: TextStyle(
                                        fontFamily: 'Arial',
                                        fontSize: 10.5,
                                        color: ClassicPalette.muted,
                                    ),
                                ),
                            ],
                        ),
                    ),
                    Expanded(
                        child: items.isEmpty
                            ? const Center(
                                child: Text(
                                    'No matching tags found.',
                                    style: TextStyle(
                                        fontFamily: 'Arial',
                                        fontSize: 12,
                                        color: ClassicPalette.muted,
                                    ),
                                ),
                            )
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: items.length,
                                itemBuilder: (context, index) => items[index],
                                separatorBuilder: (context, index) => const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFFC6D2C3),
                                ),
                            ),
                    ),
                ],
            ),
        );
    }
}

class _ClassicDASearchHeaderButton extends StatelessWidget {
    const _ClassicDASearchHeaderButton({
        required this.tooltip,
        required this.onTap,
        required this.child,
    });

    final String tooltip;
    final VoidCallback onTap;
    final Widget child;

    @override
    Widget build(BuildContext context) {
        return Tooltip(
            message: tooltip,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                            width: 28,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [ClassicPalette.buttonTop, ClassicPalette.buttonBottom],
                                ),
                                border: Border.all(color: ClassicPalette.borderDark),
                                borderRadius: BorderRadius.circular(3),
                            ),
                            child: child,
                        ),
                    ),
                ),
            ),
        );
    }
}

class _ClassicDASearchSuggestionRow extends StatelessWidget {
    const _ClassicDASearchSuggestionRow({
        required this.text,
        required this.type,
        required this.count,
        required this.isMetatag,
        required this.onTap,
    });

    final String text;
    final String type;
    final int count;
    final bool isMetatag;
    final VoidCallback onTap;

    String get _iconAsset => _classicSearchTermAsset(type, isMetatag);

    String get _typeLabel {
        if (isMetatag) return 'Search option';
        return switch(type) {
            'artist' => 'Artist',
            'character' => 'Character',
            'copyright' => 'Copyright',
            'species' => 'Species',
            _ => 'General',
        };
    }

    @override
    Widget build(BuildContext context) {
        return Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                hoverColor: const Color(0xFFD7E4C9),
                splashColor: ClassicPalette.accent.withValues(alpha: .16),
                highlightColor: const Color(0xFFCFDFB4),
                child: SizedBox(
                    height: 36,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                            children: [
                                SizedBox.square(
                                    dimension: 20,
                                    child: Image.asset(
                                        _iconAsset,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.medium,
                                        isAntiAlias: true,
                                    ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontFamily: 'Arial',
                                            fontSize: 12.5,
                                            fontWeight: isMetatag ? FontWeight.w700 : FontWeight.w500,
                                            color: ClassicPalette.link,
                                        ),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                    _typeLabel,
                                    style: const TextStyle(
                                        fontFamily: 'Arial',
                                        fontSize: 10.5,
                                        color: ClassicPalette.muted,
                                    ),
                                ),
                                if (count > 0) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                        constraints: const BoxConstraints(minWidth: 28),
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                            '$count',
                                            style: const TextStyle(
                                                fontFamily: 'Arial',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: ClassicPalette.ink,
                                            ),
                                        ),
                                    ),
                                ],
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}

final List<BooruTagCounterDisplay<Tag>> tagsToAddToSearch = [
    BooruTagCounterDisplay(tag: Metatag("rating", "none"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("rating", "safe"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("rating", "questionable"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("rating", "explicit"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("rating", "borderline"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("id", ""), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("file", ""), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("type", "static"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("type", "animated"), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("source", ""), callQuantity: 0),
    BooruTagCounterDisplay(tag: Metatag("source", "none"), callQuantity: 0),
];


class _ClassicDABrowseSearch extends StatelessWidget {
    const _ClassicDABrowseSearch({
        required this.controller,
        required this.hint,
        required this.onSearch,
        required this.onOpenSuggestions,
    });

    final SearchController controller;
    final String hint;
    final Function(String value) onSearch;
    final VoidCallback onOpenSuggestions;

    @override
    Widget build(BuildContext context) {
        return Container(
            height: 30,
            decoration: BoxDecoration(
                color: const Color(0xFFF4F7F1),
                border: Border.all(color: ClassicPalette.borderDark),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                    BoxShadow(color: Color(0x66FFFFFF), offset: Offset(0, 1), blurRadius: 0),
                ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Container(
                        width: 34,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE7EEE4),
                            border: Border(right: BorderSide(color: ClassicPalette.border)),
                        ),
                        child: Image.asset(
                            'assets/classic_deviantart/custom/search.png',
                            width: 20,
                            height: 20,
                            filterQuality: FilterQuality.medium,
                            isAntiAlias: true,
                        ),
                    ),
                    Expanded(
                        child: Container(
                            alignment: Alignment.centerLeft,
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFFF9FBF7), Color(0xFFE9EFE6)],
                                ),
                            ),
                            child: TextField(
                                controller: controller,
                                onSubmitted: onSearch,
                                onTap: onOpenSuggestions,
                                onChanged: (_) => onOpenSuggestions(),
                                textInputAction: TextInputAction.search,
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(fontSize: 12, height: 1, color: ClassicPalette.ink),
                                decoration: InputDecoration(
                                    hintText: hint,
                                    hintStyle: const TextStyle(fontSize: 12, height: 1, color: ClassicPalette.muted),
                                    isCollapsed: true,
                                    filled: false,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 9),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                ),
                            ),
                        ),
                    ),
                    InkWell(
                        onTap: () => onSearch(controller.text),
                        child: Container(
                            width: 70,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFFD8EA4A), Color(0xFFB6D227)],
                                ),
                                border: Border(left: BorderSide(color: ClassicPalette.accentDark)),
                            ),
                            child: const Text(
                                'Search',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: ClassicPalette.ink),
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}

class SearchButton extends StatelessWidget {
    const SearchButton({super.key, required this.controller, this.onSearch, this.icon = const ClassicCustomIcon('search', size: 18)});

    final SearchController controller;
    final Widget icon;
    final Function(String)? onSearch;
    
    @override
    Widget build(context) {
        return IconButton(
            icon: icon,
            onPressed: onSearch != null ? () => onSearch!(controller.text) : null,
        );
    }
}

class SearchTagController extends SearchController {
    // I copied some of the code straight from Flutter's implementation of buildTextSpan due to composing
    @override
    TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
        assert(!value.composing.isValid || !withComposing || value.isComposingRangeValid);
        final bool composingRegionOutOfRange = !value.isComposingRangeValid || !withComposing;

        final searchTags = text.split(" ").map((e) => SearchTag.fromText(e),).toList();

        int wordIndex = 0;
        final textSpans = searchTags.map((e) {
            final TextStyle? styleWithModifier = style?.merge(TextStyle(color: SearchTag.modifierColors[e.modifier]));
            final text = e.getText();

            final bool isWordWithinComposingRange = !composingRegionOutOfRange
                && (wordIndex + text.length) > value.composing.start
                && wordIndex < value.composing.end;

            if(isWordWithinComposingRange) {
                final composingAdjusted = TextRange(start: value.composing.start - wordIndex, end: value.composing.end - wordIndex);
                wordIndex += text.length + 1;
                return TextSpan(
                    style: styleWithModifier,
                    children: <TextSpan>[
                        TextSpan(text: composingAdjusted.textBefore(text)),
                        TextSpan(
                            style: getComposingStyle(styleWithModifier),
                            text: composingAdjusted.textInside(text),
                        ),
                        TextSpan(text: composingAdjusted.textAfter(text)),
                    ],
                );
            }
            wordIndex += text.length + 1;
            return TextSpan(
                style: styleWithModifier,
                text: text
            );
        },).expandIndexed((index, e) {
            final bool hasSpaceOnLast = value.text.endsWith(" ");
            if(!hasSpaceOnLast && index == searchTags.length) {
                return [e];
            }
            return [e, TextSpan(text: " ")];
        }).toList();

        return TextSpan(style: style, children: textSpans);
    }

    TextStyle getComposingStyle(TextStyle? style) => style?.merge(const TextStyle(decoration: TextDecoration.underline)) ?? const TextStyle(decoration: TextDecoration.underline);
}