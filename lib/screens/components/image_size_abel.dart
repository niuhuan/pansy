import 'package:flutter/material.dart';

Widget imageSizeLabel(int number) {
  return Row(
    children: [
      Expanded(child: Container()),
      number <= 1
          ? Container()
          : Container(
              padding: const EdgeInsets.only(
                top: 3,
                bottom: 3,
                left: 8,
                right: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_in_picture_alt_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  Text(
                    " $number",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
    ],
  );
}
