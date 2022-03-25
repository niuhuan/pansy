import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final ImageProvider image;
  final double size;
  final double padding;
  final Color paddingColor;

  const Avatar({
    Key? key,
    required this.image,
    this.size = 50,
    this.padding = 5,
    this.paddingColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final max = size + padding;
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(max)),
      child: Container(
        color: Colors.white,
        width: max,
        height: max,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(this.size)),
            child: Image(
              image: image,
              width: this.size,
              height: this.size,
            ),
          ),
        ),
      ),
    );
  }
}
