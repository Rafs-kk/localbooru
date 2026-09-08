import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:path/path.dart' as p;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class AddImageDropRegion extends StatefulWidget {
    const AddImageDropRegion({
        super.key,
        required this.child,
        this.onFilesDropped,
    });

    final Widget child;
    final ValueChanged<List<File>>? onFilesDropped;

    @override
    State<AddImageDropRegion> createState() => _AddImageDropRegionState();
}

class _AddImageDropRegionState extends State<AddImageDropRegion> {
    bool _isDragAndDrop = false;

    SimpleFileFormat? _findFileFormat(DataReader reader) {
        final sentFormats = reader.getFormats(Formats.standardFormats);

        // Prefer an actual image/video representation when the drag source
        // exposes more than one file format.
        for(final format in sentFormats) {
            if(format is! SimpleFileFormat) continue;
            final mimeTypes = format.mimeTypes ?? const <String>[];
            if(mimeTypes.any((mime) => mime.startsWith('image/') || mime.startsWith('video/'))) {
                return format;
            }
        }

        return null;
    }

    String _fileExtension(SimpleFileFormat format, String? fileName) {
        final fromName = p.extension(fileName ?? '').replaceFirst('.', '');
        if(fromName.isNotEmpty) return fromName;

        final mimeTypes = format.mimeTypes;
        if(mimeTypes != null && mimeTypes.isNotEmpty && mimeTypes.first.contains('/')) {
            return mimeTypes.first.split('/').last.split('+').first;
        }
        return 'bin';
    }

    void _showUnsupportedDropMessage() {
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('That drop does not contain a supported image or video file.')),
        );
    }

    @override
    Widget build(BuildContext context) {
        // A null callback means this wrapper is intentionally inert. This also
        // keeps older routing.dart call sites source-compatible while ensuring
        // drag-and-drop is active only where Submit provides a handler.
        if(widget.onFilesDropped == null) return widget.child;

        return DropRegion(
            formats: Formats.standardFormats,
            child: Stack(
                children: [
                    widget.child,
                    Positioned.fill(
                        child: AnimatedOpacity(
                            opacity: _isDragAndDrop ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 100),
                            child: IgnorePointer(
                                child: Container(
                                    margin: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                        color: const Color(0xF2E8F1E2),
                                        border: Border.all(color: ClassicPalette.accentDark, width: 2),
                                        borderRadius: BorderRadius.circular(9),
                                        boxShadow: const [
                                            BoxShadow(color: Color(0x88FFFFFF), offset: Offset(0, 1)),
                                        ],
                                    ),
                                    child: Center(
                                        child: Container(
                                            width: double.infinity,
                                            constraints: const BoxConstraints(maxWidth: 390),
                                            margin: const EdgeInsets.all(14),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                                color: ClassicPalette.panel,
                                                border: Border.all(color: ClassicPalette.borderDark),
                                                borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                                children: [
                                                    ClassicCustomIcon('add_image', size: 30),
                                                    SizedBox(width: 11),
                                                    Expanded(
                                                        child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                                Text(
                                                                    'Drop artwork here',
                                                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                                                ),
                                                                SizedBox(height: 2),
                                                                Text(
                                                                    'Release to add it to this submission.',
                                                                    style: TextStyle(fontSize: 10.5, color: ClassicPalette.muted),
                                                                ),
                                                            ],
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                ],
            ),
            onDropOver: (event) {
                if(event.session.items.isEmpty) return DropOperation.none;
                final item = event.session.items.first;

                // Internal LocalBooru gallery drags are for dragging artwork out
                // of the app, not for creating another submission.
                if(item.localData is Map) {
                    if(_isDragAndDrop) setState(() => _isDragAndDrop = false);
                    return DropOperation.none;
                }
                if(!event.session.allowedOperations.contains(DropOperation.copy)) {
                    if(_isDragAndDrop) setState(() => _isDragAndDrop = false);
                    return DropOperation.none;
                }

                if(!_isDragAndDrop) setState(() => _isDragAndDrop = true);
                return DropOperation.copy;
            },
            onDropLeave: (_) {
                if(mounted && _isDragAndDrop) setState(() => _isDragAndDrop = false);
            },
            onPerformDrop: (event) async {
                if(mounted && _isDragAndDrop) setState(() => _isDragAndDrop = false);

                final requests = <(DataReader, SimpleFileFormat)>[];
                for(final item in event.session.items) {
                    if(item.localData is Map) continue;
                    final reader = item.dataReader!;
                    final insertedFormat = _findFileFormat(reader);
                    if(insertedFormat != null) requests.add((reader, insertedFormat));
                }

                if(requests.isEmpty) {
                    _showUnsupportedDropMessage();
                    return;
                }

                // getFile uses callbacks by design. Start every request before
                // onPerformDrop returns, then cache each file stream in the
                // background and deliver the completed files in drop order.
                final droppedFiles = List<File?>.filled(requests.length, null);
                var completed = 0;
                var hadReadError = false;

                void finishOne() {
                    completed++;
                    if(completed != requests.length || !mounted) return;

                    final files = droppedFiles.whereType<File>().toList(growable: false);
                    if(files.isNotEmpty) widget.onFilesDropped!(files);
                    if(hadReadError || files.length != requests.length) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('One or more dropped files could not be read.')),
                        );
                    }
                }

                for(var index = 0; index < requests.length; index++) {
                    final (reader, insertedFormat) = requests[index];
                    reader.getFile(insertedFormat, (file) async {
                        try {
                            final fileExtension = _fileExtension(insertedFormat, file.fileName);
                            final cacheKey = 'submit-drag-${DateTime.now().microsecondsSinceEpoch}-$index-${file.fileName ?? 'file'}-${file.fileSize}';
                            final draggedFile = await DefaultCacheManager().putFileStream(
                                cacheKey,
                                file.getStream(),
                                fileExtension: fileExtension,
                            );
                            droppedFiles[index] = draggedFile;
                        } catch (error, stackTrace) {
                            hadReadError = true;
                            debugPrint('Error caching dropped file: $error');
                            debugPrintStack(stackTrace: stackTrace);
                        } finally {
                            finishOne();
                        }
                    }, onError: (error) {
                        hadReadError = true;
                        debugPrint('Error reading dropped file: $error');
                        finishOne();
                    });
                }
            },
        );
    }
}
