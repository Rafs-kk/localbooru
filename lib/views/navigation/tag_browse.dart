import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/context_menu.dart';
import 'package:localbooru/components/image_grid_display.dart';
import 'package:localbooru/components/search_tag.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/views/image_manager/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_tools/sliver_tools.dart';

class GalleryViewer extends StatefulWidget {
    const GalleryViewer({super.key, required this.searcher, this.headerDisplay, this.index = 0, this.selectionMode = false, this.onSelect, this.onNextPage, this.selectedImages, this.displayBackButton = true, this.forceOrientation, this.actions, this.additionalMenuOptions});

    final int index;
    final FutureOr<SearchableInformation> Function(int index) searcher;
    final Widget Function(BuildContext context, Orientation orientation)? headerDisplay;
    final bool selectionMode;
    final bool displayBackButton;
    final Orientation? forceOrientation;
    final void Function(List<ImageID>)? onSelect;
    final void Function(int newIndex)? onNextPage;
    final List<Widget>? actions;
    final List<ImageID>? selectedImages;
    final List<PopupMenuEntry<dynamic>>? additionalMenuOptions;

    @override
    State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
    late Future<Map> _resultObtainFuture;

    final scrollToTop = GlobalKey();
    
    late int _currentIndex;

    List<ImageID> _selectedImages = [];

    @override
    void initState() {
        super.initState();
        _currentIndex = widget.index;
        _selectedImages = widget.selectedImages ?? [];
        updateImages();

        booruUpdateListener.addListener(updateImages);
    }

    @override
    void didUpdateWidget(covariant GalleryViewer oldWidget) {
        super.didUpdateWidget(oldWidget);
        if (oldWidget.searcher != widget.searcher || oldWidget.index != widget.index) {
            _currentIndex = widget.index;
            _selectedImages = widget.selectedImages ?? [];
            _resultObtainFuture = _obtainResults();
        }
    }

    @override
    void dispose() {
        booruUpdateListener.removeListener(updateImages);
        super.dispose();
    }

    void updateImages() {
        setState(() {
            _resultObtainFuture = _obtainResults();
        });
    }

    void openContextMenu(Offset offset, BooruImage image) {
        final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
        showMenu(
            context: context,
            position: RelativeRect.fromRect(
                Rect.fromLTWH(offset.dx, offset.dy, 10, 10),
                Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width, overlay.paintBounds.size.height),
            ),
            items: singleContextMenuItems(image)
        );
    }

    List<PopupMenuEntry> singleContextMenuItems(BooruImage image) => [
        PopupMenuItem(
            height: 36,
            child: Row(
                children: [
                    const ClassicActionIcon('all', size: 17),
                    const SizedBox(width: 7),
                    const Expanded(child: Text("Select")),
                    Text(
                        _selectedImages.contains(image.id) ? '✓' : '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ClassicPalette.link),
                    ),
                ],
            ),
            onTap: () => toggleImageSelection(image.id),
        ),
        const PopupMenuDivider(height: 1),
        ...imageShareItems(image),
        if(widget.additionalMenuOptions != null) ...[
            const PopupMenuDivider(height: 1),
            ...widget.additionalMenuOptions!
        ],
        const PopupMenuDivider(height: 1),
        ...imageManagementItems(image, context: context),
    ];

    List<PopupMenuEntry> multipleContextMenuItems(List<BooruImage> images) => [
        if(widget.additionalMenuOptions != null) ...[
            ...widget.additionalMenuOptions!,
            const PopupMenuDivider(height: 1),
        ],
        ...multipleImageManagementItems(images, context: context),
    ];

    void toggleImageSelection(ImageID imageID) {
        setState(() {
            if(_selectedImages.contains(imageID)) _selectedImages.remove(imageID);
            else _selectedImages.add(imageID);
        });
        if(widget.onSelect != null) widget.onSelect!(_selectedImages);
    }

    Future<Map> _obtainResults() async {
        final search = await widget.searcher(_currentIndex);

        return {
            "images": search.images,
            "indexLength": search.indexLength,
            "sharedPrefs": await SharedPreferences.getInstance()
        };
    }

    bool isInSelection() => widget.selectionMode || _selectedImages.isNotEmpty;

    @override
    Widget build(BuildContext context) {
        final List<Widget> actions = [
            ...(widget.actions ?? []),
            PopupMenuButton(
                tooltip: 'Gallery options',
                icon: const ClassicCustomIcon('menu', size: 18),
                padding: EdgeInsets.zero,
                itemBuilder: (context) {
                    return [
                        ...booruItems(),
                        if(widget.additionalMenuOptions != null) ...[
                            const PopupMenuDivider(height: 1),
                            ...widget.additionalMenuOptions!
                        ]
                    ];
                }
            )
        ];
        return FutureBuilder<Map>(
            future: _resultObtainFuture,
            builder: (context, snapshot) {
                if(snapshot.hasData) {
                    int pages = snapshot.data!["indexLength"];
                    SharedPreferences prefs = snapshot.data!["sharedPrefs"];
                
                    return OrientationBuilder(
                        builder: (context, containerOrientation) {
                            final Orientation orientation = widget.forceOrientation ?? containerOrientation;
                            return Scaffold(
                                body: CustomScrollView(
                                    slivers: [
                                        if(!widget.selectionMode) SliverAnimatedSwitcher(
                                            duration: kThemeAnimationDuration,
                                            child: !isInSelection()
                                                ? SliverAppBar(
                                                    key: const ValueKey("normal"),
                                                    floating: true,
                                                    snap: true,
                                                    pinned: isDesktop(),
                                                    forceMaterialTransparency: false,
                                                    backgroundColor: ClassicPalette.panelAlt,
                                                    elevation: 0,
                                                    titleSpacing: 0,
                                                    automaticallyImplyLeading: false,
                                                    leading: widget.displayBackButton ? const ClassicSafeBackButton(fallback: '/search') : null,
                                                    actions: [Padding(
                                                        padding: const EdgeInsets.only(right: 8),
                                                        child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                                                    )],
                                                    title: widget.headerDisplay != null ? widget.headerDisplay!(context, orientation) : null,
                                                )
                                                : SliverAppBar(
                                                    key: const ValueKey("elements selected"),
                                                    floating: true,
                                                    snap: true,
                                                    pinned: true,
                                                    // forceElevated: true,
                                                    automaticallyImplyLeading: false,
                                                    backgroundColor: ClassicPalette.selection,
                                                    leading: IconButton(
                                                        tooltip: 'Clear selection',
                                                        onPressed: () => setState(() => _selectedImages = []),
                                                        icon: const ClassicCustomIcon('clear_selection', size: 16),
                                                    ),
                                                    actions: [
                                                        IconButton(
                                                            icon: const ClassicActionIcon('edit', size: 18),
                                                            onPressed: () async {
                                                                final sendable = PresetListManageImageSendable(await Future.wait(_selectedImages.map((e) => PresetImage.fromExistingImage((snapshot.data!["images"] as List<BooruImage>).firstWhere((image) => image.id == e)))));
                                                                if(context.mounted) {
                                                                    context.push("/manage_image", extra: sendable);
                                                                    setState(() => _selectedImages = []);
                                                                }
                                                            },
                                                        ),
                                                        PopupMenuButton(
                                                            tooltip: 'Selected deviation actions',
                                                            icon: const ClassicCustomIcon('image_actions', size: 18),
                                                            padding: EdgeInsets.zero,
                                                            itemBuilder: (context) {
                                                            if(_selectedImages.length == 1) return singleContextMenuItems(snapshot.data!["images"].firstWhere((element) => element.id == _selectedImages[0]));
                                                            else if(_selectedImages.length > 1) return multipleContextMenuItems(snapshot.data!["images"].where((element) => _selectedImages.contains(element.id)).toList());
                                                            return [];
                                                        }, onSelected: (value) => setState(() => _selectedImages = []))
                                                    ],
                                                    title: Text("${_selectedImages.length} Selected")
                                                ),
                                        ),
                                        SliverToBoxAdapter(child: SizedBox(key:scrollToTop, height: 0.0)),
                                        if (pages == 0) const SliverFillRemaining(child: Center(child: Text('No deviations found.')))
                                        else ...[
                                            SliverPadding(
                                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                                                sliver: SliverRepoGrid(
                                                key: ValueKey("$_currentIndex"),
                                                images: snapshot.data!["images"],
                                                onPressed: (image) {
                                                    if(isInSelection()) toggleImageSelection(image.id);
                                                    else context.push("/view/${image.id}");
                                                },
                                                autoadjustColumns: prefs.getInt("grid_size") ?? settingsDefaults["grid_size"],
                                                dragOutside: !isMobile(),
                                                onContextMenu: openContextMenu,
                                                onLongPress: (image) => toggleImageSelection(image.id),
                                                selectedElements: _selectedImages,
                                                isSelection: isInSelection(),
                                                ),
                                            ),
                                            SliverToBoxAdapter(child: PageDisplay(
                                                currentPage: _currentIndex,
                                                pages: pages,
                                                onSelect: (selectedPage) {
                                                    if(widget.onNextPage != null) {
                                                        widget.onNextPage!(selectedPage);
                                                    } else {
                                                        _currentIndex = selectedPage;
                                                        updateImages();
                                                        Scrollable.ensureVisible(scrollToTop.currentContext!);
                                                    }
                                                },
                                            )),
                                        ],
                                    ]
                                ),
                            );
                        }
                    );
                } else if(snapshot.hasError) throw snapshot.error!;
                return const Center(child: CircularProgressIndicator());
            }
        );
    }
}


class SearchBarHeaderDelegate extends SliverPersistentHeaderDelegate {
    final double height;
    Function(String value) onSearch;
    final SearchTagController searchController;

    SearchBarHeaderDelegate({required this.onSearch, required this.searchController, this.height = 56.0});

    @override
    Widget build(context, double shrinkOffset, bool overlapsContent) {
        return Center(
            child: Container(
                padding: const EdgeInsets.all(8.0),
                constraints: const BoxConstraints(maxWidth: 1080),
                child: SearchTagBox(
                    onSearch: onSearch,
                    controller: searchController,
                    isFullScreen: false,
                ),
            ),
        );
    }

    @override
    double get maxExtent => height;

    @override
    double get minExtent => height;

    @override
    bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}

class PageDisplay extends StatefulWidget {
    const PageDisplay({super.key, this.height = 48.0, required this.currentPage, required this.pages, this.onSelect});
    final double height;
    final int pages;
    final int currentPage;
    final Function(int selectedPage)? onSelect;

    @override
    State<PageDisplay> createState() => _PageDisplayState();
}

class _PageDisplayState extends State<PageDisplay> {
    final controller = ScrollController();
    final jumpToKey = GlobalKey();

    @override
    void initState() {
        super.initState();
        SchedulerBinding.instance.addPostFrameCallback((_) {
            final jumpRenderBox = jumpToKey.currentContext!.findRenderObject() as RenderBox;
            double jumpTo = jumpRenderBox.localToGlobal(const Offset(-128, 0)).dx;
            if(controller.position.maxScrollExtent < jumpTo) jumpTo = controller.position.maxScrollExtent;
            if(jumpTo < 0) jumpTo = 0;
            controller.jumpTo(jumpTo < 0 ? 0 : jumpTo);
        });
    }

    final ButtonStyle indicatorStyle = TextButton.styleFrom(
        minimumSize: const Size.square(38),
        maximumSize: const Size.square(38),
        padding: const EdgeInsets.all(0),
    );

    @override
    Widget build(context) {
        return SizedBox(
            height: widget.height,
            child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
                ),
                child: Listener(
                    onPointerSignal: (event) {
                        if(event is! PointerScrollEvent) return;

                        controller.animateTo(controller.offset + (event.scrollDelta.dy * 4), duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
                    },
                    child: Center(
                        child: SingleChildScrollView(
                            controller: controller,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(widget.pages, (index) {
                                    final bool isCurrentPage = widget.currentPage == index;
                                    Widget icon = Text((index + 1).toString(), textAlign: TextAlign.center,);
                        
                                    void onPressed() {
                                        if(isCurrentPage) return;
                                        if(widget.onSelect != null) widget.onSelect!(index);
                                    }
                        
                                    return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: isCurrentPage
                                            ? FilledButton(key: jumpToKey, onPressed: onPressed, style: indicatorStyle, child: icon)
                                            : OutlinedButton(onPressed: onPressed, style: indicatorStyle, child: icon)
                                    );
                                }),
                            )
                        ),
                    ),
                )
            ),
        );
    }
}

class SearchBarOnGridList extends StatefulWidget {
    const SearchBarOnGridList({super.key, required this.onSearch, required this.desktopDisplay, this.initialText = ""});

    final void Function(String text) onSearch;
    final bool desktopDisplay;
    final String initialText;

    @override
    State<SearchBarOnGridList> createState() => _SearchBarOnGridListState();

}

class _SearchBarOnGridListState extends State<SearchBarOnGridList> {
    final SearchTagController _searchController = SearchTagController();

    @override
    void initState() {
        _searchController.text = widget.initialText;
        super.initState();
    }

    @override
    void didUpdateWidget(covariant SearchBarOnGridList oldWidget) {
        super.didUpdateWidget(oldWidget);
        if (oldWidget.initialText != widget.initialText && _searchController.text != widget.initialText) {
            _searchController.text = widget.initialText;
            _searchController.selection = TextSelection.collapsed(offset: _searchController.text.length);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: widget.desktopDisplay ? const EdgeInsets.symmetric(horizontal: 12, vertical: 7) : null,
            constraints: widget.desktopDisplay ? const BoxConstraints(maxWidth: 660, maxHeight: 48) : null,
            child: SearchTagBox(
                onSearch: (text) => widget.onSearch(text),
                controller: _searchController,
                actions: !widget.desktopDisplay ? [] : null,
                leading: widget.desktopDisplay ? null : const ClassicSafeBackButton(fallback: '/search'),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: widget.desktopDisplay ? const Color(0xFFF5F8F3) : Colors.transparent,
                elevation: !widget.desktopDisplay ? 0 : null,
                hint: "Search deviations...",
                classicStyle: widget.desktopDisplay,
            ),
        );
    }
}

class SearchableInformation {
    SearchableInformation({required this.images, required this.indexLength});
    
    List<BooruImage> images;
    int indexLength;
}