import 'package:pansy/ffi.dart';

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
