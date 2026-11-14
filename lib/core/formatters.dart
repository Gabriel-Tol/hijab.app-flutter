import 'package:intl/intl.dart';

String formatRupiah(int amount) {
  final formatted = NumberFormat.decimalPattern('id_ID').format(amount);
  return 'Rp $formatted';
}

String formatDateWib(DateTime value) {
  return '${DateFormat('d MMM yyyy, HH.mm', 'id_ID').format(value)} WIB';
}

String formatShortDate(DateTime value) {
  return DateFormat('d MMM yyyy', 'id_ID').format(value);
}

String formatCountdown(Duration value) {
  if (value <= Duration.zero) return 'Kedaluwarsa';
  final days = value.inDays;
  final hours = (value.inHours % 24).toString().padLeft(2, '0');
  final minutes = (value.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
  return days > 0 ? '$days hari $hours:$minutes:$seconds' : '$hours:$minutes:$seconds';
}
