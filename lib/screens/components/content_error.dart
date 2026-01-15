import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'package:pansy/basic/error_types.dart';

class ContentError extends StatelessWidget {
  final Object? error;
  final StackTrace? stackTrace;
  final Future<void> Function() onRefresh;

  const ContentError({
    Key? key,
    required this.error,
    required this.stackTrace,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var type = errorType("$error");
    late String message;
    late IconData iconData;
    switch (type) {
      case ERROR_TYPE_NETWORK:
        iconData = Icons.wifi_off_rounded;
        message = "连接不上啦, 请检查网络";
        break;
      case ERROR_TYPE_PERMISSION:
        iconData = Icons.highlight_off;
        message = "没有权限或路径不可用";
        break;
      case ERROR_TYPE_TIME:
        iconData = Icons.timer_off;
        message = "请检查设备时间";
        break;
      case ERROR_TYPE_UNDER_REVIEW:
        iconData = Icons.highlight_off;
        message = "资源未审核或不可用";
        break;
      default:
        iconData = Icons.highlight_off;
        message = "啊哦, 被玩坏了";
        break;
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // 使用 developer.log 输出详细错误信息
        developer.log(
          'ContentError',
          error: error,
          stackTrace: stackTrace,
          name: 'UI_ERROR',
        );
        // 同时使用 print 以便在某些环境下也能看到
        print("ERROR: $error");
        if (stackTrace != null) {
          print("STACKTRACE:\n$stackTrace");
        }
        var width = constraints.maxWidth;
        var height = constraints.maxHeight;
        var min = width < height ? width : height;
        var iconSize = min / 2.3;
        var textSize = min / 16;
        var tipSize = min / 20;
        var infoSize = min / 30;
        if (false) {
          return GestureDetector(
            onTap: onRefresh,
            child: ListView(
              children: [
                Container(
                  height: height,
                  child: Column(
                    children: [
                      Expanded(child: Container()),
                      Container(
                        child: Icon(
                          iconData,
                          size: iconSize,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Container(height: min / 10),
                      Container(
                        padding: EdgeInsets.only(
                          left: 30,
                          right: 30,
                        ),
                        child: Text(
                          message,
                          style: TextStyle(fontSize: textSize),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Text('(点击刷新)', style: TextStyle(fontSize: tipSize)),
                      Container(height: min / 15),
                      Text('$error', style: TextStyle(fontSize: infoSize)),
                      Expanded(child: Container()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: [
              SizedBox(
                height: height,
                child: Column(
                  children: [
                    Expanded(child: Container()),
                    Icon(
                      iconData,
                      size: iconSize,
                      color: Colors.grey.shade600,
                    ),
                    Container(height: min / 10),
                    Container(
                      padding: const EdgeInsets.only(
                        left: 30,
                        right: 30,
                      ),
                      child: Text(
                        message,
                        style: TextStyle(fontSize: textSize),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text('(下拉刷新)', style: TextStyle(fontSize: tipSize)),
                    Container(height: min / 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SelectableText(
                        '$error',
                        style: TextStyle(
                          fontSize: infoSize,
                          color: Colors.red.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (stackTrace != null) ...[
                      Container(height: min / 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SelectableText(
                          'Stack trace:\n${stackTrace.toString().split('\n').take(5).join('\n')}',
                          style: TextStyle(
                            fontSize: infoSize * 0.8,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                    Expanded(child: Container()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
