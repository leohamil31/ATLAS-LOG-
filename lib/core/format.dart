/// Helpers de formatação (datas, tempo relativo, CSV) sem depender de intl.
library;

String two(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

String fmtShort(DateTime d) => '${two(d.day)}/${two(d.month)}';

String fmtDateTime(DateTime d) => '${fmtDate(d)} ${two(d.hour)}:${two(d.minute)}';

/// "há 5 min", "há 3 h", "há 2 d".
String fmtAgo(DateTime d, DateTime now) {
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  return 'há ${diff.inDays} d';
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Escapa um campo para CSV com separador ';' (padrão do Excel em pt-BR).
String csvField(String value) {
  final needsQuotes = value.contains(';') ||
      value.contains('"') ||
      value.contains('\n');
  final escaped = value.replaceAll('"', '""');
  return needsQuotes ? '"$escaped"' : escaped;
}

String csvRow(List<String> fields) => fields.map(csvField).join(';');
