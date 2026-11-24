import 'dart:math';

String newId([String prefix = '']) {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  // ponytail: 0x7FFFFFFF keeps nextInt safe on web/JS where 1 << 32 evaluates to 0
  final random = Random.secure().nextInt(0x7FFFFFFF).toRadixString(36);
  return prefix.isEmpty ? '$time$random' : '${prefix}_$time$random';
}
