import 'dart:math';

String newId([String prefix = '']) {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final random = Random.secure().nextInt(1 << 32).toRadixString(36);
  return prefix.isEmpty ? '$time$random' : '${prefix}_$time$random';
}
