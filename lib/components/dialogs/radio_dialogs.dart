import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/classic_rating_icon.dart';
import 'package:localbooru/components/counter.dart';
import 'package:localbooru/theme/classic_deviantart.dart';
import 'package:localbooru/utils/constants.dart';

class RatingChooserDialog extends StatefulWidget {
    const RatingChooserDialog({
        super.key,
        this.selected,
        this.hasNull = false,
        this.title = const Text('Rating'),
        this.onChanged,
    });

    final Rating? selected;
    final bool hasNull;
    final Widget title;
    final ValueChanged<Rating?>? onChanged;

    @override
    State<RatingChooserDialog> createState() => _RatingChooserDialogState();
}

class _RatingChooserDialogState extends State<RatingChooserDialog> {
    Rating? selected;

    @override
    void initState() {
        super.initState();
        selected = widget.selected;
    }

    void _select(Rating? value) {
        setState(() => selected = value);
        widget.onChanged?.call(value);
    }

    @override
    Widget build(BuildContext context) {
        return ClassicDialogFrame(
            title: 'Content Rating',
            icon: const ClassicRatingIcon(rating: null, size: 20),
            width: 360,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Choose the content rating for this deviation.', style: TextStyle(fontSize: 11, color: ClassicPalette.muted)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                        decoration: BoxDecoration(border: Border.all(color: ClassicPalette.border)),
                        child: Column(
                            children: [
                                for (final rating in [if(widget.hasNull) null, Rating.safe, Rating.questionable, Rating.explicit, Rating.illegal])
                                    _ClassicRadioRow<Rating?>(
                                        value: rating,
                                        groupValue: selected,
                                        onChanged: _select,
                                        child: Row(
                                            children: [
                                                ClassicRatingIcon(rating: rating, size: 22),
                                                const SizedBox(width: 8),
                                                Text(getRatingText(rating), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                            ],
                                        ),
                                    ),
                            ],
                        ),
                    ),
                ],
            ),
            actions: [
                ClassicBevelButton(label: 'Close', onPressed: () => Navigator.of(context).pop()),
            ],
        );
    }
}

class ThemeChangerDialog extends StatelessWidget {
    const ThemeChangerDialog({super.key, required this.theme});
    final String theme;

    @override
    Widget build(BuildContext context) {
        return ClassicDialogFrame(
            title: 'Theme',
            icon: const ClassicSpriteIcon(index: 39, size: 20),
            width: 360,
            child: const Text('The Classic DeviantArt interface now uses one fixed theme for visual consistency.', style: TextStyle(fontSize: 12)),
            actions: [ClassicBevelButton(label: 'Close', onPressed: Navigator.of(context).pop)],
        );
    }
}

final Map<String, String> avaiableCounters = {
    'squares': 'LocalBooru Classic / dA-era inspired',
    'baba': 'resucutie',
    'image-goobers': 'endercatcore',
    'signs': 'themtipguy, resucutie',
};

class CounterChangerDialog extends StatelessWidget {
    const CounterChangerDialog({super.key, required this.counter});
    final String counter;

    @override
    Widget build(BuildContext context) {
        return ClassicDialogFrame(
            title: 'Image Counter',
            icon: const ClassicSpriteIcon(index: 5, size: 20),
            width: 560,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    const Text('Choose the counter artwork used on the Browse home page.', style: TextStyle(fontSize: 11, color: ClassicPalette.muted)),
                    const SizedBox(height: 8),
                    Container(
                        decoration: BoxDecoration(border: Border.all(color: ClassicPalette.border)),
                        child: Column(
                            children: avaiableCounters.entries.map((counterType) {
                                return _ClassicRadioRow<String>(
                                    value: counterType.key,
                                    groupValue: counter,
                                    onChanged: (value) => Navigator.of(context).pop(value),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Wrap(
                                                spacing: 6,
                                                children: [
                                                    Text(counterType.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                                    Text('— ${counterType.value}', style: const TextStyle(fontSize: 10.5, color: ClassicPalette.muted)),
                                                ],
                                            ),
                                            const SizedBox(height: 5),
                                            StyleCounter(number: 1234567890, height: 28, display: counterType.key),
                                        ],
                                    ),
                                );
                            }).toList(),
                        ),
                    ),
                ],
            ),
            actions: [ClassicBevelButton(label: 'Close', onPressed: Navigator.of(context).pop)],
        );
    }
}

class _ClassicRadioRow<T> extends StatelessWidget {
    const _ClassicRadioRow({required this.value, required this.groupValue, required this.onChanged, required this.child});

    final T value;
    final T groupValue;
    final ValueChanged<T?> onChanged;
    final Widget child;

    @override
    Widget build(BuildContext context) {
        final selected = value == groupValue;
        return Material(
            color: selected ? const Color(0xFFD7E4C9) : ClassicPalette.panel,
            child: InkWell(
                onTap: () => onChanged(value),
                child: Container(
                    constraints: const BoxConstraints(minHeight: 45),
                    padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ClassicPalette.border))),
                    child: Row(
                        children: [
                            Radio<T>(value: value, groupValue: groupValue, onChanged: onChanged, visualDensity: const VisualDensity(horizontal: -3, vertical: -3)),
                            const SizedBox(width: 4),
                            Expanded(child: child),
                        ],
                    ),
                ),
            ),
        );
    }
}
