/// 格式化大数字为人性化的显示
/// 例如: 0, 100, 1K, 300K, 1M, 10M 等
String formatNumber(int number) {
  if (number < 1000) {
    return number.toString();
  } else if (number < 1000000) {
    // 千位
    final k = number / 1000;
    if (k < 10) {
      return '${k.toStringAsFixed(1)}K';
    } else {
      return '${k.toInt()}K';
    }
  } else if (number < 1000000000) {
    // 百万位
    final m = number / 1000000;
    if (m < 10) {
      return '${m.toStringAsFixed(1)}M';
    } else {
      return '${m.toInt()}M';
    }
  } else {
    // 十亿位
    final b = number / 1000000000;
    if (b < 10) {
      return '${b.toStringAsFixed(1)}B';
    } else {
      return '${b.toInt()}B';
    }
  }
}
