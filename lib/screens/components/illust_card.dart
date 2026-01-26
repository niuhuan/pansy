import 'package:flutter/material.dart';
import 'package:pansy/basic/format_utils.dart';
import 'package:pansy/screens/components/image_size_abel.dart';
import 'package:pansy/screens/components/pixiv_image.dart';
import 'package:pansy/src/rust/pixirust/entities.dart';

class IllustCard extends StatefulWidget {
  final Illust illust;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool onlyShowImages;

  const IllustCard({
    super.key,
    required this.illust,
    this.onTap,
    this.onLongPress,
    this.onlyShowImages = false,
  });

  @override
  State<IllustCard> createState() => _IllustCardState();
}

class _IllustCardState extends State<IllustCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        (theme.textTheme.bodyMedium?.color ?? Colors.black).withAlpha(230);

    return Card(
        margin: const EdgeInsets.all(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = width * widget.illust.height / widget.illust.width;
              return SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    ScalePixivImage(
                      url: widget.illust.imageUrls.medium,
                      originSize: Size(
                        widget.illust.width.toDouble(),
                        widget.illust.height.toDouble(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: imageSizeLabel(widget.illust.metaPages.length),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (!widget.onlyShowImages)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.illust.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.illust.user.name,
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
                        Icon(
                          Icons.favorite_border,
                          size: 14,
                          color: textColor.withAlpha(160),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatNumber(widget.illust.totalBookmarks),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withAlpha(160),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.remove_red_eye_outlined,
                          size: 14,
                          color: textColor.withAlpha(160),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatNumber(widget.illust.totalView),
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