const currencySymbol = '\$';

/// e.g. 1250.5 -> "$1,250.50"
String formatMoney(num value) {
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final sign = value < 0 ? '-' : '';
  return '$sign$currencySymbol$whole.${parts[1]}';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// e.g. "Nov 21, 2026 · 14:05" in the device's local time.
String formatDate(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${_months[d.month - 1]} ${d.day}, ${d.year} · '
      '${two(d.hour)}:${two(d.minute)}';
}

/// Postgres numeric values may arrive as a JSON number or a string.
double parseDouble(Object? value) => switch (value) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0,
      _ => 0,
    };
