import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';

/// Compact rating badges matching the classic 2010-era icon set.
class ClassicRatingIcon extends StatelessWidget {
  const ClassicRatingIcon({super.key, required this.rating, this.size = 24});

  final Rating? rating;
  final double size;

  String get _assetName => switch (rating) {
        Rating.safe => 'safe',
        Rating.questionable => 'questionable',
        Rating.explicit => 'explicit',
        Rating.illegal => 'borderline',
        _ => 'none',
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/classic_deviantart/ratings/$_assetName.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        isAntiAlias: true,
      ),
    );
  }
}
