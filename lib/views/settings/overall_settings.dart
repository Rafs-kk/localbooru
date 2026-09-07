import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:localbooru/components/counter.dart';
import 'package:localbooru/components/dialogs/radio_dialogs.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:localbooru/utils/platform_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverallSettings extends StatefulWidget {
    const OverallSettings({super.key, required this.prefs});

    final SharedPreferences prefs;

    @override
    State<OverallSettings> createState() => _OverallSettingsState();
}

class _OverallSettingsState extends State<OverallSettings> {
    final _pageSizeValidator = GlobalKey<FormState>();
    final _pageSizeController = TextEditingController();
    final LocalAuthentication auth = LocalAuthentication();

    late double _gridSizeSliderValue;
    late double _autotagAccuracy;
    late double _thumbnailQuality;
    late bool _update;
    late bool _gifVideo;
    late bool _authLock;
    late bool _customFrame;
    late String _counter;

    bool isAuthLockOptionEnabled = false;

    bool isSettingModified(String setting) {
        return widget.prefs.get(setting) != null && widget.prefs.get(setting) != settingsDefaults[setting];
    }

    void resetProp(String setting, {Function(dynamic)? modifier}) {
        widget.prefs.remove(setting);
        setState(() {
            if(modifier != null) modifier(settingsDefaults[setting]);
        });
    }

    Widget resetButton(String setting, VoidCallback onPressed) {
        if(!isSettingModified(setting)) return const SizedBox.shrink();
        return IconButton(
            tooltip: 'Restore default',
            onPressed: onPressed,
            icon: const ClassicSpriteIcon(index: 38, size: 17),
        );
    }

    @override
    void initState() {
        super.initState();
        _gridSizeSliderValue = (widget.prefs.getInt("grid_size") ?? settingsDefaults["grid_size"]).toDouble();
        _autotagAccuracy = widget.prefs.getDouble("autotag_accuracy") ?? settingsDefaults["autotag_accuracy"];
        _thumbnailQuality = widget.prefs.getDouble("thumbnail_quality") ?? settingsDefaults["thumbnail_quality"];
        _pageSizeController.text = (widget.prefs.getInt("page_size") ?? settingsDefaults["page_size"]).toString();
        _update = widget.prefs.getBool("update") ?? settingsDefaults["update"];
        _gifVideo = widget.prefs.getBool("gif_video") ?? settingsDefaults["gif_video"];
        _counter = widget.prefs.getString("counter") ?? settingsDefaults["counter"];
        _authLock = widget.prefs.getBool("auth_lock") ?? settingsDefaults["auth_lock"];
        _customFrame = widget.prefs.getBool("custom_frame") ?? settingsDefaults["custom_frame"];

        LocalAuthentication().isDeviceSupported().then((value) => setState(() {
            isAuthLockOptionEnabled = value && isMobile();
        }));
    }

    @override
    void dispose() {
        _pageSizeController.dispose();
        super.dispose();
    }

    Future<void> onChangeCounter() async {
        final choosenCounter = await showDialog<String>(
            context: context,
            builder: (_) => CounterChangerDialog(counter: widget.prefs.getString("counter") ?? settingsDefaults["counter"])
        );
        if(choosenCounter == null) return;
        widget.prefs.setString("counter", choosenCounter);
        setState(() => _counter = choosenCounter);
        counterListener.update();
    }

    @override
    Widget build(BuildContext context) {
        return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
                const _ClassicSettingsIntro(),
                const SizedBox(height: 12),
                _ClassicSettingsGroup(
                    title: 'Browsing',
                    iconIndex: 5,
                    children: [
                        SliderListTile(
                            title: Row(
                                children: [
                                    const Text("Grid size", style: TextStyle(fontWeight: FontWeight.w700)),
                                    resetButton("grid_size", () => resetProp("grid_size", modifier: (v) => _gridSizeSliderValue = v.toDouble())),
                                ],
                            ),
                            leading: const ClassicSpriteIcon(index: 5, size: 22),
                            subtitle: const Text("Set how many columns should be displayed dynamically"),
                            extremeTips: const [Text("Less elements"), Text("More elements")],
                            value: _gridSizeSliderValue,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: (value) async {
                                setState(() => _gridSizeSliderValue = value);
                                widget.prefs.setInt("grid_size", value.ceil());
                            },
                        ),
                        _ClassicSettingRow(
                            leading: const ClassicSpriteIcon(index: 18, size: 22),
                            title: Row(
                                children: [
                                    const Text("Page size", style: TextStyle(fontWeight: FontWeight.w700)),
                                    resetButton("page_size", () => resetProp("page_size", modifier: (v) => _pageSizeController.text = v.toString())),
                                ],
                            ),
                            subtitle: const Text("How many images per page should be displayed"),
                            trailing: Form(
                                key: _pageSizeValidator,
                                child: SizedBox(
                                    width: 92,
                                    height: 29,
                                    child: TextFormField(
                                        controller: _pageSizeController,
                                        textAlign: TextAlign.center,
                                        validator: (value) {
                                            if(value == null || value.isEmpty) return "Cannot be empty";
                                            if(int.parse(value) > 100) return "Too big";
                                            return null;
                                        },
                                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]+'))],
                                        onChanged: (value) {
                                            _pageSizeValidator.currentState!.validate();
                                            if(value.isEmpty || int.parse(value) > 100) return;
                                            setState(() {});
                                            widget.prefs.setInt("page_size", int.parse(value));
                                        },
                                    ),
                                ),
                            ),
                        ),
                        SliderListTile(
                            title: Row(
                                children: [
                                    const Text("Thumbnail quality", style: TextStyle(fontWeight: FontWeight.w700)),
                                    resetButton("thumbnail_quality", () => resetProp("thumbnail_quality", modifier: (v) => _thumbnailQuality = v)),
                                ],
                            ),
                            leading: const ClassicSpriteIcon(index: 29, size: 22),
                            subtitle: const Text("Higher values improve browse thumbnails but consume more memory"),
                            extremeTips: const [Text("0.5x displayed"), Text("3x displayed")],
                            value: _thumbnailQuality,
                            min: 0.5,
                            max: 3,
                            divisions: 5,
                            label: "$_thumbnailQuality",
                            onChanged: (value) async {
                                setState(() => _thumbnailQuality = value);
                                widget.prefs.setDouble("thumbnail_quality", value);
                            },
                        ),
                    ],
                ),
                const SizedBox(height: 12),
                _ClassicSettingsGroup(
                    title: 'Tags',
                    iconIndex: 42,
                    children: [
                        SliderListTile(
                            title: Row(
                                children: [
                                    const Text("Autotag accuracy", style: TextStyle(fontWeight: FontWeight.w700)),
                                    resetButton("autotag_accuracy", () => resetProp("autotag_accuracy", modifier: (v) => _autotagAccuracy = v)),
                                ],
                            ),
                            leading: const ClassicSpriteIcon(index: 42, size: 22),
                            subtitle: const Text("How strict the automatic tag suggestions should be"),
                            extremeTips: const [Text("Less accurate"), Text("More accurate")],
                            value: _autotagAccuracy,
                            min: 0,
                            max: 1,
                            label: "${(_autotagAccuracy*100).round()}%",
                            onChanged: (value) async {
                                setState(() => _autotagAccuracy = value);
                                widget.prefs.setDouble("autotag_accuracy", value);
                            },
                        ),
                    ],
                ),
                const SizedBox(height: 12),
                _ClassicSettingsGroup(
                    title: 'Appearance',
                    iconIndex: 39,
                    children: [
                        _ClassicSettingRow(
                            leading: const ClassicSpriteIcon(index: 39, size: 22),
                            title: const Text('Classic DeviantArt interface', style: TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: const Text('Fixed classic theme — intentionally kept consistent across the application'),
                            trailing: const Text('Active', style: TextStyle(color: ClassicPalette.muted, fontWeight: FontWeight.w700)),
                        ),
                        if(hasWindowFrameNavigation()) _ClassicSwitchSetting(
                            leading: const ClassicSpriteIcon(index: 16, size: 22),
                            title: "Custom window frame",
                            subtitle: "Show LocalBooru's custom desktop window frame",
                            value: _customFrame,
                            onChanged: (value) {
                                widget.prefs.setBool("custom_frame", value);
                                setState(() => _customFrame = value);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restart the app to take effect")));
                            },
                        ),
                        _ClassicSettingRow(
                            leading: StyleCounter(number: Random().nextInt(10), height: 24, display: _counter),
                            title: const Text("Counter", style: TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(_counter),
                            trailing: const Text('Choose ›', style: TextStyle(color: ClassicPalette.link, fontWeight: FontWeight.w700)),
                            onTap: onChangeCounter,
                        ),
                    ],
                ),
                const SizedBox(height: 12),
                _ClassicSettingsGroup(
                    title: 'Behavior',
                    iconIndex: 11,
                    children: [
                        _ClassicSwitchSetting(
                            leading: const ClassicSpriteIcon(index: 3, size: 22),
                            title: "Display GIFs as videos",
                            subtitle: "Add video controls when GIF media is displayed",
                            value: _gifVideo,
                            onChanged: (value) {
                                widget.prefs.setBool("gif_video", value);
                                setState(() => _gifVideo = value);
                            },
                        ),
                        if(isAuthLockOptionEnabled) _ClassicSwitchSetting(
                            leading: const ClassicSpriteIcon(index: 23, size: 22),
                            title: "Enable biometric hideout",
                            subtitle: "Hide content behind authentication after the app enters the background",
                            value: _authLock,
                            onChanged: (value) async {
                                if(value) {
                                    try {
                                        final didAuthenticate = await auth.authenticate(localizedReason: "Biometric check before enabling");
                                        if(didAuthenticate) widget.prefs.setBool("auth_lock", true);
                                    } on PlatformException catch (error) {
                                        final String message = switch(error.code) {
                                            auth_error.otherOperatingSystem => "This system shouldn't have any support for authentication lock",
                                            auth_error.notAvailable || auth_error.notEnrolled || auth_error.passcodeNotSet => "You don't have any auth system avaiable",
                                            auth_error.lockedOut => "You tried too many times. Please wait till your system allows",
                                            _ => error.message!
                                        };
                                        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                                    }
                                } else {
                                    widget.prefs.setBool("auth_lock", false);
                                }
                                setState(() => _authLock = widget.prefs.getBool("auth_lock")!);
                            },
                        ),
                    ],
                ),
                const SizedBox(height: 12),
                _ClassicSettingsGroup(
                    title: 'Other',
                    iconIndex: 38,
                    children: [
                        _ClassicSwitchSetting(
                            leading: const ClassicSpriteIcon(index: 38, size: 22),
                            title: "Prompt for updates",
                            subtitle: "Check for new LocalBooru versions and show an update prompt",
                            value: _update,
                            onChanged: (value) {
                                widget.prefs.setBool("update", value);
                                setState(() => _update = value);
                            },
                        ),
                    ],
                ),
            ],
        );
    }
}

class _ClassicSettingsIntro extends StatelessWidget {
    const _ClassicSettingsIntro();

    @override
    Widget build(BuildContext context) {
        return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text('Application Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('Local collection display, tagging and program behavior.', style: TextStyle(fontSize: 11, color: ClassicPalette.muted)),
            ],
        );
    }
}

class _ClassicSettingsGroup extends StatelessWidget {
    const _ClassicSettingsGroup({required this.title, required this.iconIndex, required this.children});

    final String title;
    final int iconIndex;
    final List<Widget> children;

    @override
    Widget build(BuildContext context) {
        return Container(
            decoration: BoxDecoration(
                color: ClassicPalette.panel,
                border: Border.all(color: ClassicPalette.border),
                borderRadius: BorderRadius.circular(5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFC9D8C6), ClassicPalette.panelHeader],
                            ),
                            border: Border(bottom: BorderSide(color: ClassicPalette.border)),
                        ),
                        child: Row(
                            children: [
                                ClassicSpriteIcon(index: iconIndex, size: 20),
                                const SizedBox(width: 7),
                                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            ],
                        ),
                    ),
                    for(int i = 0; i < children.length; i++) ...[
                        children[i],
                        if(i < children.length - 1) const Divider(height: 1, color: ClassicPalette.border),
                    ],
                ],
            ),
        );
    }
}

class _ClassicSettingRow extends StatelessWidget {
    const _ClassicSettingRow({required this.leading, required this.title, this.subtitle, this.trailing, this.onTap, this.extra});

    final Widget leading;
    final Widget title;
    final Widget? subtitle;
    final Widget? trailing;
    final VoidCallback? onTap;
    final Widget? extra;

    @override
    Widget build(BuildContext context) {
        return InkWell(
            onTap: onTap,
            child: Container(
                color: ClassicPalette.panel,
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        SizedBox(width: 34, child: Align(alignment: Alignment.topLeft, child: leading)),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    DefaultTextStyle.merge(style: const TextStyle(fontSize: 12.5), child: title),
                                    if(subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        DefaultTextStyle.merge(style: const TextStyle(fontSize: 11, color: ClassicPalette.muted, height: 1.2), child: subtitle!),
                                    ],
                                    if(extra != null) ...[
                                        const SizedBox(height: 7),
                                        extra!,
                                    ],
                                ],
                            ),
                        ),
                        if(trailing != null) ...[
                            const SizedBox(width: 12),
                            Align(alignment: Alignment.centerRight, child: trailing!),
                        ],
                    ],
                ),
            ),
        );
    }
}

class _ClassicSwitchSetting extends StatelessWidget {
    const _ClassicSwitchSetting({required this.leading, required this.title, required this.subtitle, required this.value, required this.onChanged});

    final Widget leading;
    final String title;
    final String subtitle;
    final bool value;
    final ValueChanged<bool> onChanged;

    @override
    Widget build(BuildContext context) {
        return _ClassicSettingRow(
            leading: leading,
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle),
            trailing: Checkbox(
                value: value,
                onChanged: (newValue) {
                    if(newValue != null) onChanged(newValue);
                },
            ),
            onTap: () => onChanged(!value),
        );
    }
}

class SliderListTile extends StatelessWidget {
    const SliderListTile({super.key, this.title, this.leading, required this.value, this.min = 0, this.max = 1, this.label, this.onChanged, this.subtitle, this.extremeTips, this.divisions});

    final Widget? title;
    final Widget? subtitle;
    final List<Widget>? extremeTips;
    final Widget? leading;
    final double value;
    final double min;
    final double max;
    final int? divisions;
    final String? label;
    final Function(double)? onChanged;

    @override
    Widget build(BuildContext context) {
        return _ClassicSettingRow(
            leading: leading ?? const ClassicSpriteIcon(index: 5, size: 22),
            title: title ?? const SizedBox.shrink(),
            subtitle: subtitle,
            extra: Column(
                children: [
                    if(extremeTips != null) DefaultTextStyle.merge(
                        style: const TextStyle(fontSize: 10, color: ClassicPalette.muted),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: extremeTips!),
                    ),
                    SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            overlayShape: SliderComponentShape.noOverlay,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            activeTrackColor: ClassicPalette.link,
                            inactiveTrackColor: ClassicPalette.border,
                            thumbColor: ClassicPalette.link,
                            showValueIndicator: ShowValueIndicator.onDrag,
                        ),
                        child: Slider(
                            value: value,
                            min: min,
                            max: max,
                            label: label,
                            divisions: divisions,
                            onChanged: onChanged,
                        ),
                    ),
                ],
            ),
        );
    }
}
