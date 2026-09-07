import 'package:flutter/material.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/listeners.dart';

class DownloadProgressDialog extends StatefulWidget {
    const DownloadProgressDialog({super.key});

    @override
    State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
    @override
    Widget build(context) {
        return const ClassicDialogFrame(
            title: 'Importing',
            icon: ClassicSpriteIcon(index: 32, size: 20),
            width: 520,
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        Text('LocalBooru is importing the selected content…', style: TextStyle(fontSize: 11, color: ClassicPalette.muted)),
                        SizedBox(height: 10),
                        LinearProgressIndicator(),
                    ],
                ),
            ),
        );
    }
}

Future<VirtualPreset> importImageFromURL(String url) async {
    final uri = Uri.parse(url);
    importListener.updateImportStatus(import: true);
    final isCollection = await determineIfCollection(uri);
    Future<VirtualPreset> future;
    if(isCollection) {
        future = VirtualPresetCollection.urlToPreset(url);
    } else {
        future = PresetImage.urlToPreset(url);
    }
    return await future.whenComplete(() => importListener.clear());
}
