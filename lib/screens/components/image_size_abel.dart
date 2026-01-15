import 'package:flutter/material.dart';

Widget imageSizeLabel(int number) {
  if (number <= 1) {
    return const SizedBox.shrink();
  }
  return Container(
    padding: const EdgeInsets.only(
      top: 3,
      bottom: 3,
      left: 8,
      right: 5,
    ),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(.5),
      borderRadius: const BorderRadius.all(
        Radius.circular(5),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.picture_in_picture_alt_rounded,
          color: Colors.white,
          size: 12,
        ),
        Text(
          " $number",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
