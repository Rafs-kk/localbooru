import 'package:flutter/material.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/listeners.dart';

class DesktopHousing extends StatefulWidget {
    const DesktopHousing({super.key, required this.child, required this.routeUri, this.roundedCorners = false});

    final Widget child;
    final Uri routeUri;
    final bool roundedCorners;

    @override
    State<DesktopHousing> createState() => _DesktopHousingState();
}

class _DesktopHousingState extends State<DesktopHousing> {
    double _importProgress = 0;

    @override
    void initState() {
        importListener.addListener(handleProgressDisplay);
        super.initState();
    }

    @override
    void dispose() {
        importListener.removeListener(handleProgressDisplay);
        super.dispose();
    }

    void handleProgressDisplay() {
        setState(() => _importProgress = importListener.progress);
    }

    @override
    Widget build(context) {
        final path = widget.routeUri.path;
        final showSidebar = path == '/home' || path.startsWith('/search') || path.startsWith('/collections');
        return Stack(
            children: [
                Column(
                    children: [
                        ClassicTopBar(routeUri: widget.routeUri),
                        Expanded(
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                    if (showSidebar) ClassicSidebar(routeUri: widget.routeUri),
                                    Expanded(
                                        child: Container(
                                            clipBehavior: widget.roundedCorners ? Clip.antiAlias : Clip.none,
                                            decoration: widget.roundedCorners ? const BoxDecoration(
                                                borderRadius: BorderRadius.only(topLeft: Radius.circular(6)),
                                            ) : null,
                                            child: widget.child
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
                if(importListener.isImporting) Positioned(
                    top: 41,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(value: _importProgress == 0 ? null : _importProgress, minHeight: 2)
                ),
            ],
        );
    }
}

class MobileHousing extends StatefulWidget {
    const MobileHousing({super.key, required this.child});

    final Widget child;
    @override
    State<MobileHousing> createState() => _MobileHousingState();
}

class _MobileHousingState extends State<MobileHousing> {
    double _importProgress = 0;

    @override
    void initState() {
        importListener.addListener(handleProgressDisplay);
        super.initState();
    }

    @override
    void dispose() {
        importListener.removeListener(handleProgressDisplay);
        super.dispose();
    }

    void handleProgressDisplay() {
        setState(() => _importProgress = importListener.progress);
    }

    @override
    Widget build(context) {
        return Stack(
            children: [
                widget.child,
                if(importListener.isImporting) Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                        child: LinearProgressIndicator(value: _importProgress == 0 ? null : _importProgress, minHeight: 2)
                    ),
                )
            ],
        );
    }
}
