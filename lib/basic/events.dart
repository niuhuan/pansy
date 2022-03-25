import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

EventChannel _eventChannel = EventChannel("onEvent");
StreamSubscription? _eventChannelListen;

Map<void Function(String args), String> _eventMap = {};

void _onEvent(String method, String params) {
  _eventMap.forEach((key, value) {
    if (value == method) {
      key(params);
    }
  });
}

void _onFlatEvent(dynamic t) {
  var map = jsonDecode(t);
  _onEvent(map["method"], map["params"]);
}

void registerLowLevelEvent(void Function(String args) eventHandler, String method) {
  if (_eventMap.containsKey(eventHandler)) {
    throw 'once register';
  }
  _eventMap[eventHandler] = method;
  if (_eventMap.length == 1) {
    _eventChannelListen?.cancel();
  }
}

void unregisterLowLevelEvent(void Function(String args) eventHandler) {
  if (!_eventMap.containsKey(eventHandler)) {
    throw 'no register';
  }
  _eventMap.remove(eventHandler);
  if (_eventMap.length == 0) {
    _eventChannelListen =
        _eventChannel.receiveBroadcastStream().listen(_onFlatEvent);
  }
}


