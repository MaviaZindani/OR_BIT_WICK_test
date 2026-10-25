import 'package:intl/intl.dart';

class HelperFunction {
  static final _currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  /// 1099.99 -> "$1,099.99"
  static String price(double value) => _currency.format(value);

  /// 10.48 -> "-10%". Whole percent: the card has no room for decimals.
  static String discountLabel(double percentage) =>
      '-${percentage.round()}%';

  /// "2025-04-30T09:41:02.053Z" -> "Apr 30, 2025". Empty when the review has
  /// no date so the caller can skip the row.
  static String reviewDate(DateTime? date) =>
      date == null ? '' : DateFormat('MMM d, y').format(date.toLocal());

  /// 4.0 -> "4.0", 4.56 -> "4.6"
  static String rating(double value) => value.toStringAsFixed(1);

  /// "mobile-accessories" -> "Mobile Accessories", for payloads that carry a
  /// slug where a display name is needed.
  static String titleCase(String slug) => slug
      .split(RegExp(r'[-_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// "N products" / "1 product"
  static String productCount(int count) =>
      '$count ${count == 1 ? 'product' : 'products'}';
}
