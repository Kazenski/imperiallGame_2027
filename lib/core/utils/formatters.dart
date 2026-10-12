import 'package:intl/intl.dart';

/// Formatação de números e datas em pt-BR.
class Formatters {
  const Formatters._();

  static final NumberFormat _decimal = NumberFormat.decimalPattern('pt_BR');
  static final DateFormat _shortDate = DateFormat('dd/MM', 'pt_BR');
  static final DateFormat _fullDate = DateFormat("d 'de' MMMM", 'pt_BR');

  static String number(num value) => _decimal.format(value);

  /// 12345 -> "12.345"
  static String xp(int value) => _decimal.format(value);

  /// 1.0 -> "1,0"
  static String decimal1(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');

  /// Porcentagem a partir de uma fração (0.3 -> "+30%").
  static String percentFromFraction(double fraction) =>
      '${(fraction * 100).round()}%';

  static String shortDate(DateTime date) => _shortDate.format(date);

  static String fullDate(DateTime date) => _fullDate.format(date);

  /// "há 2 h", "há 3 d", "agora"
  static String relativeTime(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(date);

    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays < 7) return 'há ${diff.inDays} d';
    if (diff.inDays < 30) return 'há ${(diff.inDays / 7).floor()} sem';
    return shortDate(date);
  }
}
