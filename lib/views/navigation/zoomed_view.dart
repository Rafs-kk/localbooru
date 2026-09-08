import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/components/window_frame.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewZoom extends StatefulWidget {
    const ImageViewZoom(this.image, {super.key});

    final BooruImage image;

    @override
    State<ImageViewZoom> createState() => _ImageViewZoomState();
}

class _ImageViewZoomState extends State<ImageViewZoom> {
    final PhotoViewController controller = PhotoViewController();

    @override
    void dispose() {
        controller.dispose();
        super.dispose();
    }

    void zoom(double scaleFactor) {
        final currentScale = controller.scale ?? 1.0;
        final nextScale = (currentScale * scaleFactor).clamp(0.05, 10.0).toDouble();
        controller.updateMultiple(
            scale: nextScale,
            position: Offset(
                controller.position.dx * scaleFactor,
                controller.position.dy * scaleFactor,
            ),
        );
    }

    void fitImage() {
        controller.reset();
    }

    void actualSize() {
        controller.updateMultiple(
            scale: 1.0,
            position: Offset.zero,
        );
    }

    Widget _windowCaption() {
        return Container(
            height: 32,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ClassicPalette.headerTop, ClassicPalette.headerBottom],
                ),
                border: Border(
                    bottom: BorderSide(color: ClassicPalette.headerBorder),
                ),
            ),
            child: Theme(
                data: ThemeData.dark(),
                child: const WindowFrameAppBar(
                    title: Row(
                        children: [
                            ClassicSpriteIcon(index: 0, size: 16),
                            SizedBox(width: 7),
                            Text(
                                'LocalBooru Image Preview',
                                style: TextStyle(
                                    fontFamily: 'Arial',
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }

    Widget _viewerToolbar(BuildContext context, {required bool compact}) {
        return Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE3ECE0), ClassicPalette.panelHeader],
                ),
                border: Border(
                    bottom: BorderSide(color: ClassicPalette.borderDark),
                ),
            ),
            child: Row(
                children: [
                    ClassicBevelButton(
                        label: compact ? 'Back' : 'Back to deviation',
                        leading: const ClassicNavArrow.left(size: 12),
                        onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 10),
                    const ClassicSpriteIcon(index: 0, size: 18),
                    const SizedBox(width: 7),
                    Expanded(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    widget.image.filename,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontFamily: 'Arial',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: ClassicPalette.ink,
                                    ),
                                ),
                                if (!compact)
                                    const Text(
                                        'Image Preview',
                                        style: TextStyle(
                                            fontFamily: 'Arial',
                                            fontSize: 9.5,
                                            color: ClassicPalette.muted,
                                        ),
                                    ),
                            ],
                        ),
                    ),
                    const SizedBox(width: 8),
                    if (!compact) ...[
                        ClassicBevelButton(
                            label: 'Fit',
                            onPressed: fitImage,
                        ),
                        const SizedBox(width: 4),
                        ClassicBevelButton(
                            label: '100%',
                            onPressed: actualSize,
                        ),
                        const SizedBox(width: 6),
                    ],
                    _ClassicViewerIconButton(
                        tooltip: 'Zoom in',
                        assetPath: 'assets/classic_deviantart/custom/viewer_zoom_in.png',
                        onPressed: () => zoom(1.25),
                    ),
                    const SizedBox(width: 4),
                    _ClassicViewerIconButton(
                        tooltip: 'Zoom out',
                        assetPath: 'assets/classic_deviantart/custom/viewer_zoom_out.png',
                        onPressed: () => zoom(0.8),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton(
                        tooltip: 'Image actions',
                        padding: EdgeInsets.zero,
                        itemBuilder: (context) => imageShareItems(widget.image),
                        child: const _ClassicViewerMenuButton(),
                    ),
                ],
            ),
        );
    }

    Widget _viewerCanvas() {
        return Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            decoration: BoxDecoration(
                color: ClassicPalette.page,
                border: Border.all(color: ClassicPalette.borderDark),
                boxShadow: const [
                    BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 2,
                        offset: Offset(1, 2),
                    ),
                ],
            ),
            child: ClipRect(
                child: Listener(
                    onPointerSignal: (event) {
                        if (event is! PointerScrollEvent) return;
                        zoom(event.scrollDelta.dy.isNegative ? 1.15 : 0.87);
                    },
                    child: PhotoView(
                        imageProvider: FileImage(widget.image.getImage()),
                        heroAttributes: const PhotoViewHeroAttributes(tag: 'detailed'),
                        controller: controller,
                        initialScale: PhotoViewComputedScale.contained,
                        minScale: PhotoViewComputedScale.contained * 0.25,
                        maxScale: PhotoViewComputedScale.covered * 8.0,
                        basePosition: Alignment.center,
                        filterQuality: FilterQuality.medium,
                        backgroundDecoration: const BoxDecoration(
                            color: ClassicPalette.page,
                        ),
                        loadingBuilder: (context, progress) => const Center(
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ),
                    ),
                ),
            ),
        );
    }

    Widget _statusBar() {
        return Container(
            height: 30,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: const BoxDecoration(
                color: Color(0xFFC9D7C6),
                border: Border(
                    left: BorderSide(color: ClassicPalette.borderDark),
                    right: BorderSide(color: ClassicPalette.borderDark),
                    bottom: BorderSide(color: ClassicPalette.borderDark),
                ),
            ),
            child: Row(
                children: [
                    const ClassicSpriteIcon(index: 2, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(
                            widget.image.filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Arial',
                                fontSize: 10,
                                color: ClassicPalette.muted,
                            ),
                        ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                        'Mouse wheel: zoom  •  Drag: pan  •  Esc: close',
                        style: TextStyle(
                            fontFamily: 'Arial',
                            fontSize: 10,
                            color: ClassicPalette.muted,
                        ),
                    ),
                ],
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return Theme(
            data: buildClassicTheme(),
            child: Builder(
                builder: (context) => CallbackShortcuts(
                    bindings: {
                        const SingleActivator(LogicalKeyboardKey.escape): () => context.pop(),
                        const SingleActivator(LogicalKeyboardKey.add): () => zoom(1.25),
                        const SingleActivator(LogicalKeyboardKey.numpadAdd): () => zoom(1.25),
                        const SingleActivator(LogicalKeyboardKey.minus): () => zoom(0.8),
                        const SingleActivator(LogicalKeyboardKey.numpadSubtract): () => zoom(0.8),
                    },
                    child: Focus(
                        autofocus: true,
                        child: Scaffold(
                            backgroundColor: ClassicPalette.pageDeep,
                            appBar: PreferredSize(
                                preferredSize: Size.fromHeight(isDesktop() ? 78 : 46),
                                child: LayoutBuilder(
                                    builder: (context, constraints) {
                                        final compact = MediaQuery.sizeOf(context).width < 760;
                                        if (isDesktop()) {
                                            return Column(
                                                children: [
                                                    _windowCaption(),
                                                    _viewerToolbar(context, compact: compact),
                                                ],
                                            );
                                        }
                                        return _viewerToolbar(context, compact: compact);
                                    },
                                ),
                            ),
                            body: Column(
                                children: [
                                    Expanded(child: _viewerCanvas()),
                                    _statusBar(),
                                ],
                            ),
                        ),
                    ),
                ),
            ),
        );
    }
}

class _ClassicViewerIconButton extends StatelessWidget {
    const _ClassicViewerIconButton({
        required this.tooltip,
        required this.assetPath,
        required this.onPressed,
    });

    final String tooltip;
    final String assetPath;
    final VoidCallback onPressed;

    @override
    Widget build(BuildContext context) {
        return Tooltip(
            message: tooltip,
            child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [ClassicPalette.buttonTop, ClassicPalette.buttonBottom],
                        ),
                        border: Border.all(color: ClassicPalette.borderDark),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                            BoxShadow(
                                color: Colors.white70,
                                offset: Offset(0, 1),
                                blurRadius: 0,
                            ),
                        ],
                    ),
                    child: Image.asset(
                        assetPath,
                        width: 20,
                        height: 20,
                        filterQuality: FilterQuality.medium,
                        isAntiAlias: true,
                    ),
                ),
            ),
        );
    }
}

class _ClassicViewerMenuButton extends StatelessWidget {
    const _ClassicViewerMenuButton();

    @override
    Widget build(BuildContext context) {
        return Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ClassicPalette.buttonTop, ClassicPalette.buttonBottom],
                ),
                border: Border.all(color: ClassicPalette.borderDark),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                    BoxShadow(
                        color: Colors.white70,
                        offset: Offset(0, 1),
                        blurRadius: 0,
                    ),
                ],
            ),
            child: const ClassicCustomIcon('image_actions', size: 18),
        );
    }
}
