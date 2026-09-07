import 'package:flutter/material.dart';
import 'package:localbooru/api/index.dart';
import 'package:localbooru/components/builders.dart';
import 'package:localbooru/components/image_grid_display.dart';
import 'package:localbooru/theme/classic_deviantart.dart';

class RelatedImagesCard extends StatelessWidget {
    const RelatedImagesCard({super.key, required this.relatedImages, this.onRemove, this.onAddButtonPress, this.showBlockWarning = false});

    final List<ImageID> relatedImages;
    final bool showBlockWarning; //unused
    final Function(ImageID imageID)? onRemove;
    final Function()? onAddButtonPress;

    @override
    Widget build(BuildContext context) {
        return Card(
            clipBehavior: Clip.antiAlias,
            child: Stack(
                children: [
                    Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        width: double.infinity,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                BooruLoader(
                                    builder: (context, booru) => Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                                ...relatedImages.map((e) => Padding(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: SizedBox(
                                                        width: 80,
                                                        height: 80,
                                                        child: BooruImageLoader(
                                                            key: ValueKey(e),
                                                            booru: booru,
                                                            id: e,
                                                            builder: (context, relatedImage) => ClipRRect(
                                                                borderRadius: const BorderRadius.all(Radius.circular(4)),
                                                                clipBehavior: Clip.antiAlias,
                                                                child: MouseRegion(
                                                                    cursor: WidgetStateMouseCursor.clickable,
                                                                    child: GestureDetector(
                                                                        onTap: () {
                                                                            if(onRemove != null) onRemove!(e);
                                                                        },
                                                                        child: Stack(
                                                                            fit: StackFit.expand,
                                                                            children: [
                                                                                ImageGrid(
                                                                                    image: relatedImage,
                                                                                    resizeSize: 160,
                                                                                ),
                                                                                Positioned.fill(
                                                                                    child: ColoredBox(
                                                                                        color: Colors.black.withValues(alpha: 0.42),
                                                                                        child: const Center(
                                                                                            child: ClassicActionIcon('delete', size: 24),
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                            ],
                                                                        ),
                                                                    ),
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                )),
                                                ClassicBevelButton(
                                                    label: 'Add deviation',
                                                    leading: const ClassicCustomIcon('related_source_add', size: 16),
                                                    onPressed: onAddButtonPress,
                                                ),
                                            ],
                                        ),
                                    ),
                                )
                            ],
                        ),
                    ),
                    if(showBlockWarning) Positioned.fill(
                        child: Container(
                            color: Colors.black.withOpacity(0.7),
                            padding: const EdgeInsets.all(16),
                            child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Text("Correlation is enabled", textAlign: TextAlign.center, style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white
                                    ),),
                                    SizedBox(height: 8,),
                                    Text("You enabled the option to all images that are bulk added to automatically correlate with each other", textAlign: TextAlign.center, style: TextStyle(
                                        color: Colors.white
                                    ),),
                                ],
                            ),
                        )
                    ),
                ],
            )
        );
    }
}