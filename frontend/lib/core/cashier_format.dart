import 'package:intl/intl.dart';

final _moneyFormatter = NumberFormat.currency(
  locale: 'en_US',
  symbol: '₫',
  decimalDigits: 0,
);
final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
final _timeFormatter = DateFormat('HH:mm');

String formatMoney(num value) => _moneyFormatter.format(value);
String formatDateTime(DateTime? value) =>
    value == null ? 'Not available' : _dateTimeFormatter.format(value.toLocal());
String formatTime(DateTime? value) =>
    value == null ? '--:--' : _timeFormatter.format(value.toLocal());
