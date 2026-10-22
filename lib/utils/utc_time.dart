
DateTime? parseKidGuardUtc(dynamic value) {
  if (value == null) return null;

  final raw = value.toString().trim();

  if (raw.isEmpty) return null;

  // SQL Server đôi khi trả thời gian UTC
  // nhưng không kèm chữ Z ở cuối.
  final hasTimezone =
      raw.endsWith('Z') ||
          raw.endsWith('z') ||
          RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);

  final text = hasTimezone ? raw : '${raw}Z';

  return DateTime.tryParse(text)?.toUtc();
}
