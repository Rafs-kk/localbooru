import 'package:flutter/material.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/multi_image_display.dart';
import 'package:localbooru/theme/classic_deviantart.dart';

class GeneralCollectionManagerScreen extends StatefulWidget {
    const GeneralCollectionManagerScreen({
        super.key,
        this.displayImages,
        this.onCorelatedChanged,
        this.corelated,
        this.saveCollectionToggle,
        this.onSaveCollectionToggle,
        required this.collection,
        this.onErrorChange,
        this.onMultiCompress,
        this.progressMultiCompress,
        this.onManageImages,
    });

    final List<ImageProvider?>? displayImages;
    final void Function(bool value)? onCorelatedChanged;
    final bool? corelated;
    final void Function(bool value)? onSaveCollectionToggle;
    final bool? saveCollectionToggle;
    final void Function(bool value)? onErrorChange;
    final void Function()? onMultiCompress;
    final double? progressMultiCompress;
    final VoidCallback? onManageImages;
    final VirtualPresetCollection collection;

    @override
    State<GeneralCollectionManagerScreen> createState() => _GeneralCollectionManagerScreenState();
}

class _GeneralCollectionManagerScreenState extends State<GeneralCollectionManagerScreen> {
    int get _readyImageCount => widget.collection.pages?.where((image) => image.image != null).length ?? 0;

    @override
    Widget build(BuildContext context) {
        return LayoutBuilder(
            builder: (context, constraints) {
                final wide = constraints.maxWidth >= 930;
                final preview = _buildPreviewPanel();
                final options = _buildOptionsColumn();

                return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                    children: [
                        _ClassicSubmitNotice(
                            text: _readyImageCount == 0
                                ? 'Welcome to Bulk Submit! Add several deviations, then configure batch options before submitting.'
                                : 'Bulk Submit is preparing $_readyImageCount deviation${_readyImageCount == 1 ? '' : 's'} for your local collection.',
                        ),
                        const SizedBox(height: 12),
                        if (wide)
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Expanded(flex: 7, child: preview),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 330, child: options),
                                ],
                            )
                        else
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                    preview,
                                    const SizedBox(height: 14),
                                    options,
                                ],
                            ),
                    ],
                );
            },
        );
    }

    Widget _buildPreviewPanel() {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 7),
                    child: Text(
                        'Create Your Deviations',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ClassicPalette.ink),
                    ),
                ),
                Container(
                    constraints: const BoxConstraints(minHeight: 305),
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEAF6E4),
                        border: Border.all(color: const Color(0xFF8FAF79)),
                        borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                                _readyImageCount == 0 ? 'Add artwork to your batch' : 'Review the artwork in this batch',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ClassicPalette.ink),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                _readyImageCount == 0
                                    ? 'Use the Bulk Adding panel to choose images or import an existing deviation.'
                                    : 'Use the Bulk Adding panel to switch between files, add more artwork, or edit an existing deviation.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11.5, height: 1.35, color: ClassicPalette.muted),
                            ),
                            const SizedBox(height: 18),
                            if (widget.displayImages != null)
                                Center(
                                    child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxHeight: 190),
                                        child: AspectRatio(
                                            aspectRatio: 1,
                                            child: MultipleImage(images: widget.displayImages!),
                                        ),
                                    ),
                                ),
                            const SizedBox(height: 18),
                            if (widget.onManageImages != null)
                                ClassicBevelButton(
                                    label: _readyImageCount == 0 ? 'Choose files / manage images' : 'Manage images',
                                    leading: const ClassicSpriteIcon(index: 28, size: 16),
                                    accent: _readyImageCount == 0,
                                    onPressed: widget.onManageImages,
                                ),
                            const SizedBox(height: 10),
                            Text(
                                _readyImageCount == 0
                                    ? 'No artwork has been selected yet.'
                                    : '$_readyImageCount file${_readyImageCount == 1 ? '' : 's'} currently selected.',
                                style: const TextStyle(fontSize: 10.5, color: ClassicPalette.muted),
                            ),
                        ],
                    ),
                ),
            ],
        );
    }

    Widget _buildOptionsColumn() {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 7),
                    child: Text(
                        'Features',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ClassicPalette.ink),
                    ),
                ),
                ClassicPanel(
                    title: 'Batch options',
                    headerIcon: const ClassicSpriteIcon(index: 11, size: 18),
                    padding: EdgeInsets.zero,
                    child: Column(
                        children: [
                            if (widget.corelated != null)
                                _ClassicFeatureToggle(
                                    icon: const ClassicSpriteIcon(index: 28, size: 22),
                                    title: 'Relate all images together',
                                    subtitle: 'Link every image in the batch as an alternate or related deviation.',
                                    value: widget.corelated!,
                                    onChanged: widget.onCorelatedChanged,
                                ),
                            if (widget.corelated != null && widget.onMultiCompress != null)
                                const Divider(height: 1, color: ClassicPalette.border),
                            if (widget.onMultiCompress != null)
                                _ClassicFeatureAction(
                                    icon: const ClassicActionIcon('compress', size: 22),
                                    title: 'Compress all images',
                                    subtitle: widget.progressMultiCompress == null
                                        ? 'Compress every selected image in one pass.'
                                        : 'Compressing the selected batch…',
                                    progress: widget.progressMultiCompress,
                                    actionLabel: 'Compress',
                                    onPressed: widget.progressMultiCompress == null ? widget.onMultiCompress : null,
                                ),
                        ],
                    ),
                ),
                if (widget.saveCollectionToggle != null) ...[
                    const SizedBox(height: 12),
                    ClassicPanel(
                        title: 'Collection',
                        headerIcon: const ClassicSpriteIcon(index: 28, size: 18),
                        padding: EdgeInsets.zero,
                        child: Column(
                            children: [
                                _ClassicFeatureToggle(
                                    icon: const ClassicSpriteIcon(index: 28, size: 22),
                                    title: 'Create a collection',
                                    subtitle: 'Put every submitted image into a new LocalBooru collection.',
                                    value: widget.saveCollectionToggle!,
                                    onChanged: (value) {
                                        widget.onSaveCollectionToggle?.call(value);
                                        widget.onErrorChange?.call(value ? widget.collection.name?.isEmpty ?? true : false);
                                    },
                                ),
                                Container(
                                    padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
                                    decoration: const BoxDecoration(
                                        border: Border(top: BorderSide(color: ClassicPalette.border)),
                                    ),
                                    child: ClassicFieldLabel(
                                        label: 'Name of collection',
                                        enabled: widget.saveCollectionToggle ?? true,
                                        child: TextFormField(
                                            decoration: const InputDecoration(),
                                            enabled: widget.saveCollectionToggle ?? true,
                                            initialValue: widget.collection.name,
                                            validator: (value) => value != null && value.isNotEmpty ? null : 'Value is empty',
                                            onChanged: (value) {
                                                widget.collection.name = value;
                                                widget.onErrorChange?.call(value.isEmpty);
                                            },
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                ],
                const SizedBox(height: 12),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F2EF),
                        border: Border.all(color: const Color(0xFFC4CEC1)),
                        borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                        'When everything looks right, use Submit in the upper-right corner to save the whole batch.',
                        style: TextStyle(fontSize: 10.5, height: 1.3, color: ClassicPalette.muted),
                    ),
                ),
            ],
        );
    }
}

class _ClassicSubmitNotice extends StatelessWidget {
    const _ClassicSubmitNotice({required this.text});

    final String text;

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF0CB),
                border: Border.all(color: const Color(0xFFD9B95C)),
                borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
                text,
                style: const TextStyle(fontSize: 11, height: 1.25, color: Color(0xFF805A16)),
            ),
        );
    }
}

class _ClassicFeatureToggle extends StatelessWidget {
    const _ClassicFeatureToggle({
        required this.icon,
        required this.title,
        required this.subtitle,
        required this.value,
        required this.onChanged,
    });

    final Widget icon;
    final String title;
    final String subtitle;
    final bool value;
    final ValueChanged<bool>? onChanged;

    @override
    Widget build(BuildContext context) {
        return Material(
            color: ClassicPalette.panel,
            child: InkWell(
                onTap: onChanged == null ? null : () => onChanged!(!value),
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            SizedBox(width: 30, child: Align(alignment: Alignment.topLeft, child: icon)),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text(
                                            subtitle,
                                            style: const TextStyle(fontSize: 10.7, height: 1.25, color: ClassicPalette.muted),
                                        ),
                                    ],
                                ),
                            ),
                            const SizedBox(width: 7),
                            SizedBox(
                                width: 28,
                                height: 28,
                                child: Center(
                                    child: Checkbox(
                                        value: value,
                                        onChanged: onChanged == null ? null : (newValue) => onChanged!(newValue ?? false),
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}

class _ClassicFeatureAction extends StatelessWidget {
    const _ClassicFeatureAction({
        required this.icon,
        required this.title,
        required this.subtitle,
        required this.actionLabel,
        required this.onPressed,
        this.progress,
    });

    final Widget icon;
    final String title;
    final String subtitle;
    final String actionLabel;
    final VoidCallback? onPressed;
    final double? progress;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    SizedBox(width: 30, child: Align(alignment: Alignment.topLeft, child: icon)),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(
                                    subtitle,
                                    style: const TextStyle(fontSize: 10.7, height: 1.25, color: ClassicPalette.muted),
                                ),
                                if (progress != null) ...[
                                    const SizedBox(height: 7),
                                    LinearProgressIndicator(value: progress),
                                ],
                            ],
                        ),
                    ),
                    const SizedBox(width: 8),
                    ClassicBevelButton(
                        label: actionLabel,
                        leading: const ClassicActionIcon('compress', size: 16),
                        onPressed: onPressed,
                    ),
                ],
            ),
        );
    }
}
