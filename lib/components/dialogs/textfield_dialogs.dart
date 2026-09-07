import 'package:flutter/material.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:string_validator/string_validator.dart';

class InsertURLDialog extends StatefulWidget {
    const InsertURLDialog({super.key});

    @override
    State<InsertURLDialog> createState() => _InsertURLDialogState();
}

class _InsertURLDialogState extends State<InsertURLDialog> {
    final TextEditingController controller = TextEditingController();

    void importFromService() => Navigator.of(context).pop(controller.text);
    bool allowedToSend() => controller.text.isNotEmpty && isURL(controller.text);

    @override
    void dispose() {
        controller.dispose();
        super.dispose();
    }

    @override
    Widget build(context) {
        final website = getWebsiteByURL(Uri.parse(controller.text));
        return ClassicDialogFrame(
            title: 'Import from service',
            icon: const ClassicSpriteIcon(index: 38, size: 20),
            width: 650,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                    const Text('Paste a supported page or image address below.', style: TextStyle(fontSize: 11, color: ClassicPalette.muted)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: controller,
                        decoration: InputDecoration(
                            prefixIcon: website != null ? Padding(padding: const EdgeInsets.all(6), child: getWebsiteIcon(website)) : null,
                            hintText: 'Link to import from',
                        ),
                        onSubmitted: (_) { if (allowedToSend()) importFromService(); },
                        onChanged: (_) => setState(() {}),
                    ),
                    if (isMobile()) ...[
                        const SizedBox(height: 10),
                        const Text('Tip: You can also share a supported link directly to LocalBooru.', style: TextStyle(fontSize: 10.5, color: ClassicPalette.muted)),
                    ],
                ],
            ),
            actions: [
                ClassicBevelButton(label: 'Close', onPressed: Navigator.of(context).pop),
                ClassicBevelButton(label: 'Import', accent: true, onPressed: allowedToSend() ? importFromService : null),
            ],
        );
    }
}

class AddCollectionDialog extends StatefulWidget {
    const AddCollectionDialog({super.key});

    @override
    State<AddCollectionDialog> createState() => _AddCollectionDialogState();
}

class _AddCollectionDialogState extends State<AddCollectionDialog> {
    final TextEditingController controller = TextEditingController();

    void send() => Navigator.of(context).pop(controller.text.trim());
    bool allowedToSend() => controller.text.trim().isNotEmpty;

    @override
    void dispose() {
        controller.dispose();
        super.dispose();
    }

    @override
    Widget build(context) {
        return ClassicDialogFrame(
            title: 'Create a New Collection',
            icon: const ClassicActionIcon('collection', size: 20),
            width: 560,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                    Container(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        decoration: BoxDecoration(
                            color: const Color(0xFFD7E2D4),
                            border: Border.all(color: ClassicPalette.border),
                        ),
                        child: const Text(
                            'Collections work like classic DeviantArt favourites folders: give this folder a name now, then add and arrange deviations inside it.',
                            style: TextStyle(fontSize: 11, height: 1.25),
                        ),
                    ),
                    const SizedBox(height: 10),
                    ClassicFieldLabel(
                        label: 'Collection name',
                        child: TextField(
                            autofocus: true,
                            controller: controller,
                            decoration: const InputDecoration(hintText: 'Untitled Collection'),
                            onSubmitted: (_) { if (allowedToSend()) send(); },
                            onChanged: (_) => setState(() {}),
                        ),
                    ),
                ],
            ),
            actions: [
                ClassicBevelButton(label: 'Close', onPressed: Navigator.of(context).pop),
                ClassicBevelButton(label: 'Create', leading: const ClassicActionIcon('collection', size: 15), accent: true, onPressed: allowedToSend() ? send : null),
            ],
        );
    }
}
