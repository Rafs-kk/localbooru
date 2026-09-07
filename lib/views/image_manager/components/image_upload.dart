import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/components/fileinfo.dart';
import 'package:localbooru/components/video_view.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/clipboard_extractor.dart';
import 'package:mime/mime.dart';
import 'package:super_clipboard/super_clipboard.dart';

class ImageUploadForm extends StatelessWidget {
    const ImageUploadForm({super.key, required this.onChanged, this.onCompressed, required this.validator, this.currentValue = "", this.orientation = Orientation.portrait});

    final ValueChanged<List<File>> onChanged;
    final ValueChanged<String>? onCompressed;
    final FormFieldValidator<String> validator;
    final String currentValue;
    final Orientation orientation;

    Future<void> _pick(BuildContext context, FormFieldState<String> state) async {
        final files = await selectFileModal(context: context);
        if(files == null || files.isEmpty) return;
        state.didChange(files.first.path);
        onChanged(files);
    }

    @override
    Widget build(BuildContext context) {
        return FormField<String>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            initialValue: currentValue,
            validator: validator,
            builder: (FormFieldState<String> state) {
                final borderColor = state.hasError ? Theme.of(context).colorScheme.error : ClassicPalette.borderDark;

                if(currentValue.isEmpty) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            InkWell(
                                onTap: () => _pick(context, state),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                    constraints: const BoxConstraints(minHeight: 205),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFE8F1E2),
                                        border: Border.all(color: borderColor),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [BoxShadow(color: Color(0x66FFFFFF), offset: Offset(0, 1), blurRadius: 0)],
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            const Text('Drag and drop your art here', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 10),
                                            const Text('or', style: TextStyle(fontSize: 11, color: ClassicPalette.muted)),
                                            const SizedBox(height: 12),
                                            ClassicBevelButton(
                                                label: 'Choose a file to add',
                                                leading: const ClassicActionIcon('submit', size: 17),
                                                accent: true,
                                                onPressed: () => _pick(context, state),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text('You can also paste an image from the clipboard.', style: TextStyle(fontSize: 10.5, color: ClassicPalette.muted)),
                                        ],
                                    ),
                                ),
                            ),
                            if(state.hasError) Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 11)),
                            ),
                        ],
                    );
                }

                final preview = Container(
                    constraints: const BoxConstraints(minHeight: 220, maxHeight: 420),
                    decoration: BoxDecoration(
                        color: const Color(0xFFCEDBCB),
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                        onTap: () => _pick(context, state),
                        child: Builder(
                            builder: (context) {
                                final mime = lookupMimeType(currentValue);
                                if(mime != null && mime.startsWith('video/')) {
                                    return IgnorePointer(child: VideoView(currentValue, showControls: false, soundOnStart: false));
                                }
                                return Image(
                                    image: ResizeImage(FileImage(File(currentValue)), height: 420),
                                    fit: BoxFit.contain,
                                );
                            },
                        ),
                    ),
                );

                final info = ClassicPanel(
                    title: 'Selected File',
                    icon: Icons.image_outlined,
                    padding: const EdgeInsets.all(9),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            FileInfo(
                                File(currentValue),
                                onCompressed: (compressed) {
                                    if(onCompressed != null) onCompressed!(compressed.path);
                                    state.didChange(compressed.path);
                                },
                            ),
                            const SizedBox(height: 8),
                            ClassicBevelButton(
                                label: 'Choose another file',
                                leading: const ClassicActionIcon('submit', size: 17),
                                onPressed: () => _pick(context, state),
                            ),
                        ],
                    ),
                );

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        if(orientation == Orientation.landscape)
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Expanded(child: preview),
                                    const SizedBox(width: 12),
                                    SizedBox(width: 270, child: info),
                                ],
                            )
                        else ...[
                            preview,
                            const SizedBox(height: 10),
                            info,
                        ],
                        if(state.hasError) Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 11)),
                        ),
                    ],
                );
            },
        );
    }
}

Future<List<File>?> selectFileModal({required BuildContext context}) async {
    final output = await showDialog<_PickerType>(
        context: context,
        builder: (context) => ClassicDialogFrame(
            title: 'Choose Artwork',
            icon: Image.asset(
                'assets/classic_deviantart/custom/submit_arrow.png',
                width: 20,
                height: 20,
                filterQuality: FilterQuality.medium,
                isAntiAlias: true,
            ),
            width: 470,
            contentPadding: const EdgeInsets.all(8),
            child: Container(
                decoration: BoxDecoration(border: Border.all(color: ClassicPalette.border)),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        ListTile(
                            title: const Text('Select a file', style: TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: const Text('Choose one or more images or videos from disk'),
                            leading: const ClassicSpriteIcon(index: 32, size: 23),
                            onTap: () => Navigator.pop(context, _PickerType.file),
                        ),
                        const Divider(height: 1),
                        ListTile(
                            title: const Text('Copy from clipboard', style: TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: const Text('Use an image currently stored on the clipboard'),
                            leading: const ClassicSpriteIcon(index: 13, size: 24),
                            onTap: () => Navigator.pop(context, _PickerType.clipboard),
                        ),
                    ],
                ),
            ),
            actions: [ClassicBevelButton(label: 'Close', onPressed: Navigator.of(context).pop)],
        ),
    );
    if(output == null) return null;
    if(output == _PickerType.clipboard) {
        final clipboard = SystemClipboard.instance;
        if(clipboard == null) return null;
        final reader = await clipboard.read();
        final types = await obtainValidFileTypeOnClipboard(reader);
        return await Future.wait(types.map((type) => getImageFromClipboard(reader: reader, fileType: type)));
    }
    if(output == _PickerType.file) return await openFilePicker();
    return null;
}

Future<List<File>?> openFilePicker() async {
    FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true);
    return pickerResult?.files.map((file) => File(file.path!)).toList();
}

enum _PickerType {file, clipboard}
