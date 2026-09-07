import 'package:flutter/material.dart';
import 'package:localbooru/theme/classic_deviantart.dart';

class ListStringTextInput extends StatefulWidget {
    const ListStringTextInput({super.key, required this.onChanged, this.defaultValue = const [], this.canBeEmpty = false, this.formValidator, this.addButtonLabel = "Add"});

    final Function(List<String>) onChanged;
    final List<String> defaultValue;
    final FormFieldValidator<String>? formValidator;
    final bool canBeEmpty;
    final String addButtonLabel;

    @override
    State<ListStringTextInput> createState() => _ListStringTextInputState();
}
class _ListStringTextInputState extends State<ListStringTextInput> {
    List<String> _currentValue = [];
    List<TextEditingController> _editControllers = [];

    final ScrollController _scrollController = ScrollController();

    @override
    void initState() {
        super.initState();
        _currentValue = List.from(widget.defaultValue); //attempt at making list changable
        Future.delayed(const Duration(milliseconds: 1), _updateList);
    }

    void _updateList() {
        for (final (index, textController) in _editControllers.indexed) {
            textController.text = _currentValue[index];
        }
    }

    void _uploadChanges() {
        // _uploadChanges();
        widget.onChanged(_currentValue);
    }

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: Scrollbar(
                        thumbVisibility: true,
                        controller: _scrollController,
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _currentValue.length,
                            controller: _scrollController,
                            itemBuilder: (BuildContext context, index) {
                                if((_editControllers.length - 1) < index) _editControllers.add(TextEditingController());

                                final controller = _editControllers[index];

                                return TextFormField(
                                    controller: controller,
                                    decoration: (widget.canBeEmpty || index != 0) ? InputDecoration(suffixIcon: IconButton(onPressed: () => setState(() {
                                        controller.dispose();
                                        _currentValue.removeAt(index);
                                        _editControllers.removeAt(index);
                                        _uploadChanges();
                                    }), icon: const ClassicActionIcon('delete', size: 16))) : null,
                                    validator: widget.formValidator,
                                    onChanged: (value) {
                                        setState(() => _currentValue[index] = value);
                                        _uploadChanges();
                                    },
                                    
                                );
                            }
                        ),
                    )
                ),
                const SizedBox(height: 12),
                ClassicBevelButton(
                    label: widget.addButtonLabel,
                    leading: const ClassicCustomIcon('related_source_add', size: 16),
                    onPressed: () {
                        setState(() => _currentValue.add(""));
                        _uploadChanges();
                        Future.delayed(const Duration(milliseconds: 10), () {
                            if (!_scrollController.hasClients) return;
                            _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.fastOutSlowIn,
                            );
                        });
                    },
                ),
            ],
        );
    }
}