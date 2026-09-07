import 'package:flutter/material.dart';
import 'package:localbooru/theme/classic_deviantart.dart';

class DeleteImageDialogue extends StatelessWidget {
    const DeleteImageDialogue({super.key});

    @override
    Widget build(BuildContext context) {
        return ClassicDialogFrame(
            title: 'Confirm Delete',
            icon: const ClassicActionIcon('delete', size: 20),
            width: 430,
            child: const Text('Are you sure you want to delete this item? This action cannot be undone.', style: TextStyle(fontSize: 12, height: 1.3)),
            actions: [
                ClassicBevelButton(label: 'No', onPressed: Navigator.of(context).pop),
                ClassicBevelButton(label: 'Yes, Delete', leading: const ClassicActionIcon('delete', size: 15), onPressed: () => Navigator.of(context).pop(true)),
            ],
        );
    }
}

class UnsavedChangesDialogue extends StatelessWidget {
    const UnsavedChangesDialogue({super.key});

    @override
    Widget build(BuildContext context) {
        return ClassicDialogFrame(
            title: 'Unsaved Changes',
            icon: const ClassicSpriteIcon(index: 20, size: 20),
            width: 450,
            child: const Text('You have unsaved changes. Do you want to discard them and exit?', style: TextStyle(fontSize: 12, height: 1.3)),
            actions: [
                ClassicBevelButton(label: 'Keep Editing', onPressed: Navigator.of(context).pop),
                ClassicBevelButton(label: 'Discard', onPressed: () => Navigator.of(context).pop(true)),
            ],
        );
    }
}
