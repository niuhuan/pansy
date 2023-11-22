import 'package:flutter/material.dart';
import 'package:pansy/ffi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

var _inChina = false;

bool get inChina => _inChina;

Future setInChina(bool value) async {
  await api.setInChina(value: value);
  _inChina = value;
}

Future initInChina() async {
  await api.perInChina();
  _inChina = await api.getInChina();
}

Widget inChinaSetting() {
  return StatefulBuilder(
    builder: (context, setState) {
      return SwitchListTile(
        title: Text(AppLocalizations.of(context)!.inChineseNetwork),
        value: _inChina,
        onChanged: (value) async {
          await setInChina(value);
          _inChina = value;
          setState(() {});
        },
      );
    },
  );
}
