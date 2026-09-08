import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoView extends StatefulWidget {
    const VideoView(
        this.path, {
        super.key,
        this.showControls = true,
        this.soundOnStart = true,
        this.playOnStart = true,
    });

    final String path;
    final bool showControls;
    final bool soundOnStart;
    final bool playOnStart;

    @override
    State<VideoView> createState() => VideoViewState();
}

class VideoViewState extends State<VideoView> {
    late VideoPlayerController _videoController;

    bool _isLoaded = false;
    bool _pausedByVisibility = false;
    String? _loadError;
    double _lastAudibleVolume = 1.0;

    static const List<double> _playbackSpeeds = [
        0.25,
        0.5,
        0.75,
        1.0,
        1.25,
        1.5,
        1.75,
        2.0,
    ];

    @override
    void initState() {
        super.initState();
        _createController();
    }

    void _createController() {
        final controller = VideoPlayerController.file(File(widget.path));
        _videoController = controller;
        controller.addListener(_onVideoChanged);
        _initializeController(controller);
    }

    Future<void> _initializeController(VideoPlayerController controller) async {
        try {
            await controller.initialize();
            if (!mounted || !identical(controller, _videoController)) return;

            await controller.setLooping(true);

            if (!widget.soundOnStart) {
                await controller.setVolume(0);
            }

            if (widget.playOnStart) {
                await controller.play();
            }

            if (!mounted || !identical(controller, _videoController)) return;
            setState(() {
                _isLoaded = true;
                _loadError = null;
            });
        } catch (error) {
            if (!mounted || !identical(controller, _videoController)) return;
            setState(() {
                _loadError = error.toString();
            });
        }
    }

    void _onVideoChanged() {
        if (!mounted || !_isLoaded) return;
        setState(() {});
    }

    @override
    void didUpdateWidget(covariant VideoView oldWidget) {
        super.didUpdateWidget(oldWidget);

        if (oldWidget.path != widget.path) {
            _videoController.removeListener(_onVideoChanged);
            _videoController.dispose();
            _isLoaded = false;
            _loadError = null;
            _pausedByVisibility = false;
            _lastAudibleVolume = 1.0;
            _createController();
        }
    }

    @override
    void dispose() {
        _videoController.removeListener(_onVideoChanged);
        _videoController.dispose();
        super.dispose();
    }

    Future<void> _togglePlayback() async {
        if (!_isLoaded) return;

        if (_videoController.value.isPlaying) {
            _pausedByVisibility = false;
            await _videoController.pause();
        } else {
            await _videoController.play();
        }
    }

    Future<void> _toggleMute() async {
        if (!_isLoaded) return;

        final volume = _videoController.value.volume;
        if (volume > 0) {
            _lastAudibleVolume = volume;
            await _videoController.setVolume(0);
        } else {
            await _videoController.setVolume(
                _lastAudibleVolume <= 0 ? 1.0 : _lastAudibleVolume,
            );
        }
    }

    Future<void> _seekTo(double milliseconds) async {
        if (!_isLoaded) return;
        final duration = _videoController.value.duration;
        if (duration.inMilliseconds <= 0) return;

        final target = milliseconds
            .round()
            .clamp(0, duration.inMilliseconds)
            .toInt();
        await _videoController.seekTo(Duration(milliseconds: target));
    }

    Future<void> _setPlaybackSpeed(double speed) async {
        if (!_isLoaded) return;
        await _videoController.setPlaybackSpeed(speed);
    }

    void _handleVisibility(VisibilityInfo info) {
        if (!_isLoaded) return;

        if (info.visibleFraction == 0) {
            if (_videoController.value.isPlaying) {
                _pausedByVisibility = true;
                _videoController.pause();
            }
            return;
        }

        if (_pausedByVisibility) {
            _pausedByVisibility = false;
            _videoController.play();
        }
    }

    String _formatDuration(Duration duration) {
        final totalSeconds = math.max(0, duration.inSeconds).toInt();
        final hours = totalSeconds ~/ 3600;
        final minutes = (totalSeconds % 3600) ~/ 60;
        final seconds = totalSeconds % 60;

        if (hours > 0) {
            return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        }

        return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }

    String _formatSpeed(double speed) {
        if (speed == speed.roundToDouble()) {
            return '${speed.toInt()}x';
        }

        final text = speed.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
        return '${text}x';
    }

    @override
    Widget build(BuildContext context) {
        final value = _videoController.value;
        final aspectRatio = _isLoaded && value.aspectRatio > 0
            ? value.aspectRatio
            : 16 / 9;

        return VisibilityDetector(
            key: ValueKey('classic-video-${widget.path}'),
            onVisibilityChanged: _handleVisibility,
            child: LayoutBuilder(
                builder: (context, constraints) {
                    final mediaSize = MediaQuery.sizeOf(context);
                    final maxWidth = constraints.hasBoundedWidth
                        ? constraints.maxWidth
                        : mediaSize.width;
                    final maxHeight = constraints.hasBoundedHeight
                        ? constraints.maxHeight
                        : mediaSize.height * .65;
                    final controlsHeight = widget.showControls ? 36.0 : 0.0;
                    final availableVideoHeight = math.max(1.0, maxHeight - controlsHeight).toDouble();

                    var playerWidth = math.max(1.0, maxWidth).toDouble();
                    var videoHeight = playerWidth / aspectRatio;

                    if (videoHeight > availableVideoHeight) {
                        videoHeight = availableVideoHeight;
                        playerWidth = videoHeight * aspectRatio;
                    }

                    final playerHeight = videoHeight + controlsHeight;

                    return Center(
                        child: SizedBox(
                            width: playerWidth,
                            height: playerHeight,
                            child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                        color: const Color(0xFF6E746F),
                                        width: 1,
                                    ),
                                ),
                                child: Column(
                                    children: [
                                        Expanded(child: _buildVideoSurface()),
                                        if (widget.showControls)
                                            _buildClassicControls(),
                                    ],
                                ),
                            ),
                        ),
                    );
                },
            ),
        );
    }

    Widget _buildVideoSurface() {
        if (_loadError != null) {
            return Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                    decoration: BoxDecoration(
                        color: const Color(0xFFD7DCD5),
                        border: Border.all(color: const Color(0xFF818881)),
                    ),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            const Text(
                                'Could not play this video.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xFF2D342F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                                _loadError!,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Color(0xFF687069),
                                    fontSize: 9,
                                ),
                            ),
                        ],
                    ),
                ),
            );
        }

        if (!_isLoaded) {
            return Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: const Text(
                    'Loading video...',
                    style: TextStyle(
                        color: Color(0xFFD7DDD8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                    ),
                ),
            );
        }

        return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayback,
                child: ColoredBox(
                    color: Colors.black,
                    child: Center(
                        child: AspectRatio(
                            aspectRatio: _videoController.value.aspectRatio,
                            child: VideoPlayer(_videoController),
                        ),
                    ),
                ),
            ),
        );
    }

    Widget _buildClassicControls() {
        final value = _videoController.value;
        final duration = value.duration;
        final position = value.position;
        final durationMs = math.max(1, duration.inMilliseconds).toDouble();
        final positionMs = position.inMilliseconds
            .clamp(0, math.max(1, duration.inMilliseconds))
            .toDouble();

        return Container(
            height: 36,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                        Color(0xFFF5F6F3),
                        Color(0xFFD4D8D2),
                        Color(0xFFB9BFB8),
                    ],
                    stops: [0.0, .48, 1.0],
                ),
                border: Border(
                    top: BorderSide(color: Color(0xFF7C837D)),
                ),
            ),
            child: Row(
                children: [
                    _ClassicPlayerButton(
                        tooltip: value.isPlaying ? 'Pause' : 'Play',
                        icon: value.isPlaying ? Icons.pause : Icons.play_arrow,
                        onPressed: _isLoaded ? _togglePlayback : null,
                    ),
                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: SliderTheme(
                                data: SliderThemeData(
                                    trackHeight: 5,
                                    activeTrackColor: ClassicPalette.accentDark,
                                    inactiveTrackColor: const Color(0xFFA7ADA7),
                                    disabledActiveTrackColor: ClassicPalette.accentDark,
                                    disabledInactiveTrackColor: const Color(0xFFA7ADA7),
                                    thumbColor: const Color(0xFF747B75),
                                    disabledThumbColor: const Color(0xFF747B75),
                                    overlayColor: Colors.transparent,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                        elevation: 1,
                                        pressedElevation: 1,
                                    ),
                                    overlayShape: SliderComponentShape.noOverlay,
                                    trackShape: const RoundedRectSliderTrackShape(),
                                ),
                                child: Slider(
                                    min: 0,
                                    max: durationMs,
                                    value: positionMs,
                                    onChanged: _isLoaded && duration.inMilliseconds > 0
                                        ? _seekTo
                                        : null,
                                ),
                            ),
                        ),
                    ),
                    Container(
                        constraints: const BoxConstraints(minWidth: 82),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        child: Text(
                            '${_formatDuration(position)} / ${_formatDuration(duration)}',
                            style: const TextStyle(
                                color: Color(0xFF303631),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                            ),
                        ),
                    ),
                    Container(
                        width: 1,
                        height: 24,
                        color: const Color(0xFF969D97),
                    ),
                    _ClassicPlayerButton(
                        tooltip: value.volume > 0 ? 'Mute' : 'Unmute',
                        icon: value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                        onPressed: _isLoaded ? _toggleMute : null,
                    ),
                    Container(
                        width: 1,
                        height: 24,
                        color: const Color(0xFF969D97),
                    ),
                    PopupMenuButton<double>(
                        tooltip: 'Playback speed',
                        padding: EdgeInsets.zero,
                        onSelected: _setPlaybackSpeed,
                        itemBuilder: (context) => _playbackSpeeds.map((speed) {
                            return PopupMenuItem<double>(
                                value: speed,
                                height: 30,
                                child: Row(
                                    children: [
                                        SizedBox(
                                            width: 18,
                                            child: speed == value.playbackSpeed
                                                ? const Text(
                                                    '✓',
                                                    style: TextStyle(
                                                        color: ClassicPalette.link,
                                                        fontWeight: FontWeight.w800,
                                                    ),
                                                )
                                                : null,
                                        ),
                                        Text(
                                            _formatSpeed(speed),
                                            style: const TextStyle(fontSize: 11),
                                        ),
                                    ],
                                ),
                            );
                        }).toList(),
                        child: Container(
                            height: 35,
                            constraints: const BoxConstraints(minWidth: 42),
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            decoration: const BoxDecoration(
                                border: Border(
                                    left: BorderSide(color: Color(0xFFEFF1EE)),
                                ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                                _formatSpeed(value.playbackSpeed),
                                style: const TextStyle(
                                    color: Color(0xFF303631),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                ),
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}

class _ClassicPlayerButton extends StatelessWidget {
    const _ClassicPlayerButton({
        required this.tooltip,
        required this.icon,
        required this.onPressed,
    });

    final String tooltip;
    final IconData icon;
    final VoidCallback? onPressed;

    @override
    Widget build(BuildContext context) {
        final enabled = onPressed != null;

        return Tooltip(
            message: tooltip,
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                    onTap: onPressed,
                    child: Opacity(
                        opacity: enabled ? 1 : .45,
                        child: Container(
                            width: 35,
                            height: 35,
                            decoration: const BoxDecoration(
                                border: Border(
                                    right: BorderSide(color: Color(0xFF969D97)),
                                ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                                icon,
                                size: 18,
                                color: Color(0xFF303631),
                            ),
                        ),
                    ),
                ),
            ),
        );
    }
}
