import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/components/dialogs/confirm_dialogs.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/views/image_manager/shell.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import "package:vector_math/vector_math_64.dart";

/// Turns source strings such as `google.com` into URLs that desktop platforms
/// can actually hand to the user's browser. Existing schemes are preserved.
Uri? normalizeExternalUri(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) return null;

    final parsed = Uri.tryParse(value);
    final scheme = parsed?.scheme.toLowerCase() ?? '';
    const externallyUsefulSchemes = {'http', 'https', 'ftp', 'ftps', 'file', 'mailto'};
    final normalized = value.startsWith('//')
        ? 'https:$value'
        : externallyUsefulSchemes.contains(scheme)
            ? value
            : 'https://$value';

    return Uri.tryParse(normalized);
}

Future<bool> openExternalUrl(String rawUrl) async {
    final uri = normalizeExternalUri(rawUrl);
    if (uri == null) return false;

    try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
        return false;
    }
}

List<PopupMenuEntry> booruItems() {
    return [
        PopupMenuItem(
            height: 36,
            child: const Row(
                children: [
                    ClassicSpriteIcon(index: 38, size: 17),
                    SizedBox(width: 7),
                    Text("Refresh"),
                ],
            ),
            onTap: () => booruUpdateListener.update(),
        ),
        PopupMenuItem(
            height: 36,
            child: const Row(
                children: [
                    ClassicCustomIcon('select_booru_folder', size: 17),
                    SizedBox(width: 7),
                    Text("Open booru location"),
                ],
            ),
            onTap: () async  {
                final Booru booru = await getCurrentBooru();
                await launchUrlString("file://${booru.path}");
            },
        )
    ];
}

List<PopupMenuEntry> imageShareItems(BooruImage image) {
    return [
        PopupMenuItem(
            height: 36,
            child: const Row(
                children: [
                    ClassicSpriteIcon(index: 0, size: 17),
                    SizedBox(width: 7),
                    Text("Open image in image viewer"),
                ],
            ),
            onTap: () => OpenFile.open(image.path),
        ),
        PopupMenuItem(
            height: 36,
            child: const Row(
                children: [
                    ClassicSpriteIcon(index: 9, size: 17),
                    SizedBox(width: 7),
                    Text("Copy image to clipboard"),
                ],
            ),
            onTap: () async {
                final item = DataWriterItem();
                item.add(Formats.png(await File(image.path).readAsBytes()));
                await SystemClipboard.instance?.write([item]);
            },
        ),
        PopupMenuItem(
            height: 36,
            child: const Row(
                children: [
                    ClassicActionIcon('share', size: 17),
                    SizedBox(width: 7),
                    Text("Share image"),
                ],
            ),
            onTap: () async => await Share.shareXFiles([XFile(image.path)]),
        )
    ];
}

List<PopupMenuEntry> imageManagementItems(BooruImage image, {required BuildContext context, bool doulbeExitOnDelete = false, bool includeEdit = true}) {
    return [
        if(includeEdit) PopupMenuItem(
            height: 36,
            child: const Row(
                children: [
                    ClassicActionIcon('edit', size: 18),
                    SizedBox(width: 7),
                    Text("Edit image metadata"),
                ],
            ),
            onTap: () async => context.push("/manage_image", extra: PresetManageImageSendable(await PresetImage.fromExistingImage(image)))
        ),
        PopupMenuItem(
            height: 36,
            child: Row(
                children: [
                    const ClassicActionIcon('delete', size: 18),
                    const SizedBox(width: 7),
                    Text("Delete image", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
            ),
            onTap: () async {
                final res = await showDialog<bool>(context: context,
                    builder: (context) => const DeleteImageDialogue()
                );
                if(res == true) {
                    if(context.mounted && doulbeExitOnDelete) context.pop(); //second to close viewer
                    await removeImage(image.id);
                }
            }
        ),
    ];
}

List<PopupMenuEntry> multipleImageManagementItems(List<BooruImage> images, {required BuildContext context}) {
    return [
        PopupMenuItem(
            height: 36,
            child: Row(children: [const ClassicActionIcon('delete', size: 18), const SizedBox(width: 7), Text("Delete images", style: TextStyle(color: Theme.of(context).colorScheme.error))]),
            onTap: () async {
                final res = await showDialog<bool>(context: context,
                    builder: (context) => const DeleteImageDialogue()
                );
                if(res == true) {
                    for(final image in images) {
                        await removeImage(image.id, notify: false);
                        booruUpdateListener.update();
                    }
                }
            }
        ),
    ];
}

List<PopupMenuEntry> urlItems(String url) {
    return [
        PopupMenuItem(
            child: const Text("Open URL"),
            onTap: () => openExternalUrl(url),
        ),
        PopupMenuItem(
            child: const Text("Copy URL"),
            onTap: () async {
                final item = DataWriterItem();
                item.add(Formats.plainText(url));
                await SystemClipboard.instance?.write([item]);
            },
        ),
        PopupMenuItem(
            child: const Text("Share URL"),
            onTap: () async => await Share.share(url),
        ),
    ];
}

List<PopupMenuEntry> tagItems(String tag, BuildContext context) {
    return [
        PopupMenuItem(
            child: const Text("Search"),
            onTap: () async {
                final res = await showDialog<String>(context: context,
                    builder: (context) => ServiceActionsDialogue(tag: tag, title: "Search on",)
                );
                switch (res) {
                    case "Danbooru": launchUrlString("https://danbooru.donmai.us/posts?tags=$tag");
                    case "e926": launchUrlString("https://e926.net/posts?tags=$tag");
                    case "e621": launchUrlString("https://e621.net/posts?tags=$tag");
                    case "Gelbooru": launchUrlString("https://gelbooru.com/index.php?page=post&s=list&tags=$tag");
                }
            }
        ),
        PopupMenuItem(
            child: const Text("More information about"),
            onTap: () async {
                final res = await showDialog<String>(context: context,
                    builder: (context) => ServiceActionsDialogue(tag: tag, title: "Open wiki",)
                );
                switch (res) {
                    case "Danbooru": 
                        final booru = await getCurrentBooru();
                        final tagType = await booru.getTagType(tag);
                        if(tagType == "artist") {
                            launchUrlString("https://danbooru.donmai.us/artists/show_or_new?name=$tag");
                        } else {
                            launchUrlString("https://danbooru.donmai.us/wiki_pages/$tag");
                        }
                    case "e926": launchUrlString("https://e926.net/wiki_pages/show_or_new?title=$tag");
                    case "e621": launchUrlString("https://e621.net/wiki_pages/show_or_new?title=$tag");
                    case "Gelbooru": launchUrlString("https://gelbooru.com/index.php?page=wiki&s=list&search=$tag");
                }
            }
        ),
    ];
}
class ServiceActionsDialogue extends StatelessWidget {
    const ServiceActionsDialogue({super.key, required this.tag, this.title = 'Select a service'});

    final String tag;
    final String title;

    @override
    Widget build(BuildContext context) {
        final services = [
            ['Danbooru', 'https://danbooru.donmai.us'],
            ['e621', 'https://e621.net'],
            ['e926', 'https://e926.net'],
            ['Gelbooru', 'https://gelbooru.com'],
        ];
        return ClassicDialogFrame(
            title: title,
            icon: const ClassicSpriteIcon(index: 38, size: 20),
            width: 420,
            contentPadding: const EdgeInsets.all(8),
            child: Container(
                decoration: BoxDecoration(border: Border.all(color: ClassicPalette.border)),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        for (int i = 0; i < services.length; i++) ...[
                            ListTile(
                                leading: getWebsiteIcon(getWebsiteByURL(Uri.parse(services[i][1]))!) ?? const ClassicSpriteIcon(index: 20, size: 20),
                                title: Text(services[i][0], style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(tag, maxLines: 1, overflow: TextOverflow.ellipsis),
                                onTap: () => Navigator.of(context).pop(services[i][0]),
                            ),
                            if (i < services.length - 1) const Divider(height: 1),
                        ],
                    ],
                ),
            ),
            actions: [ClassicBevelButton(label: 'Close', onPressed: Navigator.of(context).pop)],
        );
    }
}

// Retained for the other classic context-menu call sites that position their
// menus relative to a specific render box. Source links use overlay-local
// coordinates directly because their panel is offset from the app origin.
Offset getOffsetRelativeToBox({required Offset offset, required RenderObject renderObject}) {
    return globalToLocal(renderObject, offset);
}

Offset globalToLocal(RenderObject object, Offset point, {RenderObject? ancestor}) {
    final Matrix4 transform = object.getTransformTo(ancestor);
    final double det = transform.invert();
    if (det == 0.0) {
        return Offset.zero;
    }
    final Vector3 n = Vector3(0.0, 0.0, 1.0);
    final Vector3 i = transform.perspectiveTransform(Vector3(0.0, 0.0, 0.0));
    final Vector3 d = transform.perspectiveTransform(Vector3(0.0, 0.0, 1.0)) - i;
    final Vector3 s = transform.perspectiveTransform(Vector3(point.dx, point.dy, 0.0));
    final Vector3 p = s - d * (n.dot(s) / n.dot(d));
    return Offset(p.x, p.y);
}