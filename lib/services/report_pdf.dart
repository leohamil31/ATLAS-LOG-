/// Geração do relatório em PDF (abre diálogo de impressão / salvar PDF).
library;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/format.dart';
import '../models/models.dart';
import 'store.dart';

Future<void> printReport(
  AtlasStore store,
  List<Order> orders,
  DateTime from,
  DateTime to,
) async {
  final dist = store.statusDistribution(orders);
  final doc = pw.Document(title: 'Relatorio Atlas');
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ATLAS - Relatorio de pedidos',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('${fmtDate(from)} a ${fmtDate(to)}'),
          ],
        ),
      ),
      build: (_) => [
        pw.Text(
          'Total: ${orders.length}   |   '
          'Pendentes: ${dist[OrderStatus.pendente]}   |   '
          'Em transito: ${dist[OrderStatus.emTransito]}   |   '
          'Entregues: ${dist[OrderStatus.entregue]}   |   '
          'Cancelados: ${dist[OrderStatus.cancelado]}',
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headers: [
            'Codigo',
            'Cliente',
            'Origem',
            'Destino',
            'Status',
            'Envio',
            'Previsao',
            'Motorista',
          ],
          data: [
            for (final o in orders)
              [
                o.id,
                o.cliente,
                o.origem,
                o.destino,
                o.status.label,
                fmtDate(o.dataEnvio),
                fmtDate(o.previsaoEntrega),
                store.driverById(o.motoristaId)?.nome ?? '-',
              ],
          ],
        ),
      ],
    ),
  );
  await Printing.layoutPdf(
    name: 'relatorio-atlas.pdf',
    onLayout: (_) async => doc.save(),
  );
}
