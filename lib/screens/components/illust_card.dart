import 'package:flutter/material.dart';
import 'package:pansy/screens/components/image_size_abel.dart';
import 'package:pansy/screens/components/pixiv_image.dart';
import 'package:pansy/src/rust/pixirust/entities.dart';

class IllustCard extends StatelessWidget {
  final Illust illust;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const IllustCard({
    Key? key,
    required this.illust,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        (theme.textTheme.bodyMedium?.color ?? Colors.black).withAlpha(230);

    return Card(
      margin: const EdgeInsets.all(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = width * illust.height / illust.width;
              return SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    ScalePixivImage(
                      url: illust.imageUrls.medium,
                      originSize: Size(
                        illust.width.toDouble(),
                        illust.height.toDouble(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: imageSizeLabel(illust.metaPages.length),
                      ),
                    ),
                  ],
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    illust.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    illust.user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.favorite_border,
                          size: 14, color: textColor.withAlpha(160)),
                      const SizedBox(width: 4),
                      Text(
                        illust.totalBookmarks.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withAlpha(160),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.remove_red_eye_outlined,
                          size: 14, color: textColor.withAlpha(160)),
                      const SizedBox(width: 4),
                      Text(
                        illust.totalView.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withAlpha(160),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

