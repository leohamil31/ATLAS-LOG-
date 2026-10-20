/// Exportação de arquivos (CSV, JSON, PDF) com download real na web e
/// compartilhamento nativo no celular.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../core/format.dart';
import '../models/models.dart';
import 'store.dart';
import 'export_stub.dart' if (dart.library.js_interop) 'export_web.dart'
    as impl;

Future<void> saveBytes(Uint8List bytes, String name, String mime) =>
    impl.saveFile(bytes, name, mime);

/// CSV com BOM e separador `;` para abrir direto no Excel (pt-BR).
Future<void> saveCsv(String name, String csv) => saveBytes(
  Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]),
  name,
  'text/csv',
);

Future<void> saveJson(String name, String json) =>
    saveBytes(Uint8List.fromList(utf8.encode(json)), name, 'application/json');

/// Monta o CSV do relatório para os pedidos informados.
String ordersToCsv(AtlasStore store, List<Order> orders) {
  final rows = <String>[
    csvRow([
      'Codigo',
      'Cliente',
      'Origem',
      'Destino',
      'Status',
      'Etapa',
      'Envio',
      'Previsao',
      'Motorista',
    ]),
    for (final o in orders)
      csvRow([
        o.id,
        o.cliente,
        o.origem,
        o.destino,
        o.status.label,
        kStages[o.stage],
        fmtDate(o.dataEnvio),
        fmtDate(o.previsaoEntrega),
        store.driverById(o.motoristaId)?.nome ?? '',
      ]),
  ];
  return rows.join('\r\n');
}
