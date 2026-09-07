import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/utils/clipboard_extractor.dart';
import 'package:localbooru/views/image_manager/shell.dart';
import 'package:super_clipboard/super_clipboard.dart';

class ShortcutHandler extends StatelessWidget {
    const ShortcutHandler({super.key, required this.child, this.paste});

    final Widget child;

    final Action<PasteIntent> Function(BuildContext context)? paste;

    @override
    Widget build(BuildContext context) {
        return Shortcuts(
            shortcuts: {
                if(paste != null) SingleActivator(LogicalKeyboardKey.keyV, control: true): const PasteIntent()
            },
            child: Actions(
                actions: {
                    if(paste != null) PasteIntent: paste!(context)
                },
                child: Focus(
                    autofocus: true,
                    child:  child,
                ),
            )
        );
    }
}

class PasteIntent extends Intent {
  const PasteIntent();
}

abstract class PasteImageAction extends Action<PasteIntent> {
    /// Do not steal Ctrl+V from a focused text editor. Flutter's EditableText
    /// already provides the platform-standard copy/paste shortcuts; leaving this
    /// action disabled lets the key event continue to those built-in handlers.
    @override
    bool isEnabled(PasteIntent intent) => !_hasEditableTextFocus();

    bool _hasEditableTextFocus() {
        final focusContext = FocusManager.instance.primaryFocus?.context;
        if(focusContext == null) return false;

        return focusContext.widget is EditableText
            || focusContext.findAncestorWidgetOfExactType<EditableText>() != null
            || focusContext.findAncestorStateOfType<EditableTextState>() != null;
    }

    Future<List<File>?> obtainImages() async {
        try {
            final clipboard = SystemClipboard.instance;
            if(clipboard == null) return null;

            final reader = await clipboard.read();
            final types = await obtainValidFileTypeOnClipboard(reader);

            // Ctrl+V outside a text field is reserved for image submission, but
            // text-only clipboard contents must not open the Submit screen.
            if(types.isEmpty) return null;

            final images = await Future.wait(
                types.map((type) => getImageFromClipboard(reader: reader, fileType: type)),
            );
            return images.isEmpty ? null : images;
        } catch (_) {
            // Clipboard formats can change between probing and reading. Treat that
            // as a non-image paste rather than surfacing an asynchronous exception.
            return null;
        }
    }
}
class CallbackPasteImageAction extends PasteImageAction {
    CallbackPasteImageAction(this.callback);
    final void Function(PasteIntent intent, List<File> images) callback;

    @override
    void invoke(PasteIntent intent) async {
        final images = await super.obtainImages();
        if(images == null || images.isEmpty) return;
        callback(intent, images);
    }
}
class OpenImageAtImageManagerPasteAction extends PasteImageAction {
    OpenImageAtImageManagerPasteAction(this.context);

    final BuildContext context;

    @override
    void invoke(covariant PasteIntent intent) async {
        final images = await super.obtainImages();
        if(images == null || images.isEmpty) return;
        
        if(!context.mounted) return;
        context.push("/manage_image", extra: PresetListManageImageSendable(images.map((file) => PresetImage(
            image: file
        )).toList()));
    }
}
