import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/tags/index.dart';
import 'package:localbooru/theme/classic_deviantart.dart';

class TagField extends StatefulWidget {
    const TagField({super.key, this.controller, this.decoration, this.validator, this.style, this.type = "generic", this.onChanged});

    final TextEditingController? controller;
    final InputDecoration? decoration;
    final FormFieldValidator<String>? validator;
    final void Function(String)? onChanged;
    final TextStyle? style;
    final String type;

    @override
    State<TagField> createState() => _TagFieldState();
}

class _TagFieldState extends State<TagField> {
    final FocusNode _focusNode = FocusNode();
    late final TextEditingController controller;
    late final bool _ownsController;
    final GlobalKey textboxKey = GlobalKey();

    // RawAutocomplete normally replaces the entire field with displayStringForOption
    // before invoking onSelected. Keep the latest user-authored editing value so a
    // completion can replace only the token being typed instead of every tag.
    TextEditingValue _lastUserEditingValue = TextEditingValue.empty;
    TextEditingValue? _pendingSelectionSource;

    List<BooruTagCounterDisplay<NormalTag>> allTags = [];

    @override
    void initState() {
        super.initState();
        _ownsController = widget.controller == null;
        controller = widget.controller ?? TextEditingController();
        _lastUserEditingValue = controller.value;
        cacheTags();
    }

    @override
    void dispose() {
        _focusNode.dispose();
        if(_ownsController) controller.dispose();
        super.dispose();
    }

    Future<void> cacheTags() async {
        final Booru currentBooru = await getCurrentBooru();
        // todo: change behavior to support BooruTagCounterDisplay
        allTags = await currentBooru.getAllSavedTagsFromType(widget.type);
    }

    bool spawnAtBottom() {
        if(textboxKey.currentContext == null) return true;
        final RenderBox textboxRenderBox = textboxKey.currentContext!.findRenderObject() as RenderBox;
        final double textboxPosY = textboxRenderBox.localToGlobal(Offset.zero).dy;
        return textboxPosY <= (MediaQuery.of(context).size.height / 2);
    }

    static bool _isWhitespace(String character) => RegExp(r'\s').hasMatch(character);

    static List<String> _tokens(String text) {
        final seen = <String>{};
        final result = <String>[];
        for(final token in text.trim().split(RegExp(r'\s+'))) {
            final cleaned = token.trim();
            if(cleaned.isEmpty || !seen.add(cleaned)) continue;
            result.add(cleaned);
        }
        return result;
    }

    _ActiveToken _activeToken(TextEditingValue value) {
        final text = value.text;
        if(text.isEmpty) return const _ActiveToken(start: 0, end: 0, text: '');

        var caret = value.selection.isValid ? value.selection.extentOffset : text.length;
        caret = caret.clamp(0, text.length).toInt();

        var start = caret;
        var end = caret;
        while(start > 0 && !_isWhitespace(text[start - 1])) {
            start--;
        }
        while(end < text.length && !_isWhitespace(text[end])) {
            end++;
        }
        return _ActiveToken(start: start, end: end, text: text.substring(start, end));
    }

    void _selectSuggestion(BooruTagCounterDisplay<NormalTag> option) {
        final source = _pendingSelectionSource ?? _lastUserEditingValue;
        _pendingSelectionSource = null;

        final active = _activeToken(source);
        final before = source.text.substring(0, active.start);
        final after = source.text.substring(active.end);
        final selectedTag = option.tag.text.trim();

        // Rebuild the space-delimited tag list while preserving every previously
        // entered tag, replacing only the partial token that produced the suggestion.
        // Deduplication also prevents choosing an already-present tag from creating
        // duplicate metadata.
        final merged = <String>[];
        final seen = <String>{};
        for(final tag in [..._tokens(before), selectedTag, ..._tokens(after)]) {
            if(tag.isEmpty || !seen.add(tag)) continue;
            merged.add(tag);
        }

        final newText = merged.isEmpty ? '' : '${merged.join(' ')} ';
        controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
            composing: TextRange.empty,
        );
        _lastUserEditingValue = controller.value;
        widget.onChanged?.call(newText);
    }

    @override
    Widget build(context) {
        return LayoutBuilder(
            builder: (context, constraints) {
                return RawAutocomplete<BooruTagCounterDisplay<NormalTag>>(
                    textEditingController: controller,
                    focusNode: _focusNode,
                    optionsBuilder: (textEditingValue) async {
                        if(textEditingValue.text.trim().isEmpty) {
                            return const Iterable<BooruTagCounterDisplay<NormalTag>>.empty();
                        }

                        final active = _activeToken(textEditingValue);
                        final tagToSearch = active.text;
                        if(tagToSearch.isEmpty) {
                            return const Iterable<BooruTagCounterDisplay<NormalTag>>.empty();
                        }

                        if(allTags.isEmpty) await cacheTags();

                        final existingTags = <String>{
                            ..._tokens(textEditingValue.text.substring(0, active.start)),
                            ..._tokens(textEditingValue.text.substring(active.end)),
                        };
                        final normalizedSearch = tagToSearch.toLowerCase();

                        final matches = List<BooruTagCounterDisplay<NormalTag>>.from(allTags);
                        matches.retainWhere((display) {
                            final candidate = display.tag.text;
                            return candidate.toLowerCase().contains(normalizedSearch)
                                && !existingTags.contains(candidate)
                                && candidate != tagToSearch;
                        });
                        return matches;
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                            alignment: spawnAtBottom() ? Alignment.topLeft : Alignment.bottomLeft,
                            child: Material(
                                elevation: 4.0,
                                child: ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: 300, maxWidth: constraints.maxWidth),
                                    child: ListView.builder(
                                        itemCount: options.length,
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemBuilder: (context, index) => Builder(
                                            builder: (context) {
                                                final shouldHighlight = AutocompleteHighlightedOption.of(context) == index;
                                                if(shouldHighlight) {
                                                    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
                                                        Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 100));
                                                    });
                                                }
                                                final currentOption = options.elementAt(index);
                                                return ListTile(
                                                    title: Text(currentOption.tag.text),
                                                    onTap: () {
                                                        _pendingSelectionSource = controller.value;
                                                        onSelected(currentOption);
                                                    },
                                                    selected: shouldHighlight,
                                                    selectedColor: widget.style?.color,
                                                    selectedTileColor: widget.style?.color?.withValues(alpha: 0.1),
                                                    trailing: Text("${currentOption.callQuantity}"),
                                                );
                                            },
                                        ),
                                    ),
                                ),
                            ),
                        );
                    },
                    // RawAutocomplete briefly uses this display string internally, then
                    // _selectSuggestion restores the complete tag list synchronously.
                    displayStringForOption: (option) => option.tag.text,
                    onSelected: _selectSuggestion,
                    optionsViewOpenDirection: spawnAtBottom() ? OptionsViewOpenDirection.down : OptionsViewOpenDirection.up,
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                        final decoration = widget.decoration ?? const InputDecoration();
                        final label = decoration.labelText;
                        final field = TextFormField(
                            key: textboxKey,
                            controller: textController,
                            focusNode: focusNode,
                            decoration: decoration.copyWith(
                                labelText: null,
                                floatingLabelBehavior: FloatingLabelBehavior.never,
                            ),
                            keyboardType: TextInputType.text,
                            minLines: 1,
                            maxLines: 6,
                            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\n'))],
                            validator: widget.validator,
                            style: widget.style,
                            onFieldSubmitted: (value) {
                                _pendingSelectionSource = textController.value;
                                onFieldSubmitted();
                            },
                            onChanged: (value) {
                                _lastUserEditingValue = textController.value;
                                widget.onChanged?.call(value);
                            },
                        );
                        if(label == null || label.isEmpty) return field;
                        return ClassicFieldLabel(label: label, child: field);
                    },
                );
            },
        );
    }
}

class _ActiveToken {
    const _ActiveToken({required this.start, required this.end, required this.text});

    final int start;
    final int end;
    final String text;
}
