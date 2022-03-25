import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';

class ShadowIconButton extends StatelessWidget {
  final Function() onPressed;
  final IconData icon;

  const ShadowIconButton(
      {Key? key, required this.onPressed, required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: Colors.white,
      icon: DecoratedIcon(
        icon,
        size: 24,
        shadows: [
          BoxShadow(
            color: Colors.black,
            offset: Offset(1.0, 1.0),
            blurRadius: 5.0,
          ),
        ],
      ),
      onPressed: onPressed,
    );
  }
}
