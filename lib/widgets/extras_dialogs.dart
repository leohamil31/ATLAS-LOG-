/// Diálogos extras: comprovante de entrega (POD), etiqueta, calculadora de
/// frete e mensagem de WhatsApp.
library;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../core/geo.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/store.dart';
import 'button3d.dart';
import 'common.dart';

/// Link público de rastreio (rota /rastreio do app web).
String trackingUrl(String code) =>
    'https://leohamil31.github.io/ATLAS-LOG-/#/rastreio?codigo=$code';

// -------------------------------------------------------------------- WhatsApp

String whatsappMessage(Order o) =>
    'Olá, ${o.cliente}! Seu pedido ${o.id} está *${o.status.label}* '
    '(etapa: ${kStages[o.stage]}). Previsão de entrega: '
    '${fmtDate(o.previsaoEntrega)}. Acompanhe: ${trackingUrl(o.id)}';

/// Monta o link wa.me (com DDI 55 quando o número não o possui).
Uri? whatsappUri(Order o) {
  var digits = o.telefone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10) return null;
  if (digits.length <= 11) digits = '55$digits';
  return Uri.https('wa.me', '/$digits', {'text': whatsappMessage(o)});
}

Future<void> sendWhatsApp(BuildContext context, Order o) async {
  final uri = whatsappUri(o);
  if (uri == null) {
    toast(
      context,
      'Cadastre um telefone válido para o cliente (edite o pedido).',
      error: true,
    );
    return;
  }
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      toast(context, 'Não foi possível abrir o WhatsApp.', error: true);
    }
  } catch (error, stackTrace) {
    debugPrint('Falha ao abrir o WhatsApp: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (context.mounted) {
      toast(context, 'Falha ao abrir o WhatsApp: $error', error: true);
    }
  }
}

// ------------------------------------------------------------------------- POD

Future<void> showDeliveryDialog(
  BuildContext context,
  AtlasStore store,
  Order order,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DeliveryDialog(store: store, order: order),
  );
}

class _DeliveryDialog extends StatefulWidget {
  const _DeliveryDialog({required this.store, required this.order});

  final AtlasStore store;
  final Order order;

  @override
  State<_DeliveryDialog> createState() => _DeliveryDialogState();
}

class _DeliveryDialogState extends State<_DeliveryDialog> {
  final _name = TextEditingController();
  bool _signature = true;
  String _file = '';
  final List<Offset> _points = [];
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool _confirm() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Informe quem recebeu a entrega.');
      return false;
    }
    if (_signature && _points.isEmpty) {
      setState(() => _error = 'Colha a assinatura do destinatário.');
      return false;
    }
    if (!_signature && _file.isEmpty) {
      setState(() => _error = 'Anexe a foto do comprovante.');
      return false;
    }
    final pod = ProofOfDelivery(
      recebedor: _name.text.trim(),
      tipo: _signature ? 'assinatura' : 'foto',
      date: widget.store.now,
      arquivo: _file,
      assinatura: [
        for (final p in _points) [p.dx, p.dy],
      ],
    );
    final ok = widget.store.deliverOrder(widget.order.id, pod);
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) Navigator.pop(context);
    });
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return DialogShell(
      title: 'Concluir entrega ${widget.order.id}',
      maxWidth: 520,
      actions: [
        Button3D(
          label: 'Voltar',
          secondary: true,
          onPressed: () => Navigator.pop(context),
        ),
        Button3D(
          label: 'Confirmar entrega',
          icon: Icons.verified_rounded,
          color: ac.success,
          successLabel: 'Entregue!',
          onAction: _confirm,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Quem recebeu',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(Icons.draw_rounded),
                label: Text('Assinatura'),
              ),
              ButtonSegment(
                value: false,
                icon: Icon(Icons.photo_camera_rounded),
                label: Text('Foto'),
              ),
            ],
            selected: {_signature},
            onSelectionChanged: (s) => setState(() {
              _signature = s.first;
              _error = null;
            }),
          ),
          const SizedBox(height: 12),
          if (_signature) ...[
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ac.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: LayoutBuilder(
                  builder: (_, box) => GestureDetector(
                    onPanStart: (d) => setState(
                      () => _points
                        ..add(const Offset(-1, -1))
                        ..add(
                          Offset(
                            d.localPosition.dx / box.maxWidth,
                            d.localPosition.dy / box.maxHeight,
                          ),
                        ),
                    ),
                    onPanUpdate: (d) => setState(
                      () => _points.add(
                        Offset(
                          d.localPosition.dx / box.maxWidth,
                          d.localPosition.dy / box.maxHeight,
                        ),
                      ),
                    ),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: SignaturePainter(
                        _points.map((p) => [p.dx, p.dy]).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(_points.clear),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Limpar'),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ac.border),
              ),
              child: Row(
                children: [
                  Icon(
                    _file.isEmpty ? Icons.image_outlined : Icons.image_rounded,
                    color: ac.accent,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _file.isEmpty ? 'Nenhuma foto anexada' : _file,
                      style: TextStyle(
                        color: _file.isEmpty ? ac.muted : ac.text,
                      ),
                    ),
                  ),
                  Button3D(
                    label: 'Anexar foto',
                    compact: true,
                    secondary: true,
                    onPressed: () => setState(() {
                      // Simulação do anexo (sem câmera real nesta versão).
                      _file = 'comprovante_${widget.order.id}.jpg';
                      _error = null;
                    }),
                  ),
                ],
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: ac.danger)),
          ],
        ],
      ),
    );
  }
}

/// Desenha os traços da assinatura (pontos normalizados 0..1).
class SignaturePainter extends CustomPainter {
  SignaturePainter(this.points);

  final List<List<double>> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    var newStroke = true;
    for (final p in points) {
      if (p[0] < 0) {
        newStroke = true;
        continue;
      }
      final o = Offset(p[0] * size.width, p[1] * size.height);
      if (newStroke) {
        path.moveTo(o.dx, o.dy);
        path.lineTo(o.dx + 0.1, o.dy);
        newStroke = false;
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SignaturePainter old) => true;
}

// -------------------------------------------------------------------- Etiqueta

Future<void> showLabelDialog(BuildContext context, AtlasStore store, Order o) {
  final ac = context.ac;
  final driver = store.driverById(o.motoristaId);
  return showDialog<void>(
    context: context,
    builder: (ctx) => DialogShell(
      title: 'Etiqueta de envio',
      maxWidth: 480,
      actions: [
        Button3D(
          label: 'Fechar',
          secondary: true,
          onPressed: () => Navigator.pop(ctx),
        ),
        Button3D(
          label: 'Imprimir etiqueta',
          icon: Icons.print_rounded,
          color: ac.accent2,
          onPressed: () => printLabel(o, driver?.nome),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.black, fontSize: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'ATLAS',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Text(
                    o.id,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.black),
              const Text(
                'DESTINATÁRIO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              Text(
                o.cliente,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(o.destino),
              const SizedBox(height: 8),
              Text('Origem: ${o.origem}'),
              Text(
                'Peso: ${o.pesoKg.toStringAsFixed(0)} kg   Previsão: ${fmtDate(o.previsaoEntrega)}',
              ),
              if (driver != null) Text('Motorista: ${driver.nome}'),
              const SizedBox(height: 12),
              Center(
                child: QrImageView(
                  data: trackingUrl(o.id),
                  size: 140,
                  backgroundColor: Colors.white,
                ),
              ),
              Center(
                child: Text(
                  o.id,
                  style: const TextStyle(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> printLabel(Order o, String? motorista) async {
  final doc = pw.Document(title: 'Etiqueta ${o.id}');
  doc.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(
        10 * PdfPageFormat.cm,
        15 * PdfPageFormat.cm,
        marginAll: 12,
      ),
      build: (_) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'ATLAS',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  o.id,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Divider(),
            pw.Text(
              'DESTINATARIO',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              o.cliente,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(o.destino),
            pw.SizedBox(height: 6),
            pw.Text('Origem: ${o.origem}'),
            pw.Text(
              'Peso: ${o.pesoKg.toStringAsFixed(0)} kg  Previsao: ${fmtDate(o.previsaoEntrega)}',
            ),
            if (motorista != null) pw.Text('Motorista: $motorista'),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: trackingUrl(o.id),
                width: 120,
                height: 120,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: o.id,
              height: 50,
            ),
          ],
        ),
      ),
    ),
  );
  await Printing.layoutPdf(
    name: 'etiqueta-${o.id}.pdf',
    onLayout: (_) async => doc.save(),
  );
}

// ------------------------------------------------------------ Calculadora frete

Future<void> showFreightDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _FreightDialog(),
  );
}

class _FreightDialog extends StatefulWidget {
  const _FreightDialog();

  @override
  State<_FreightDialog> createState() => _FreightDialogState();
}

class _FreightDialogState extends State<_FreightDialog> {
  final _km = TextEditingController(text: '500');
  final _kg = TextEditingController(text: '250');
  String? _from;
  String? _to;
  bool _express = false;

  @override
  void dispose() {
    _km.dispose();
    _kg.dispose();
    super.dispose();
  }

  void _autoKm() {
    if (_from != null && _to != null) {
      final km = roadKm(_from!, _to!);
      if (km != null) _km.text = km.toStringAsFixed(0);
    }
  }

  static String _money(double v) {
    final s = v.toStringAsFixed(2).replaceAll('.', ',');
    final parts = s.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final km = double.tryParse(_km.text.replaceAll(',', '.')) ?? 0;
    final kg = double.tryParse(_kg.text.replaceAll(',', '.')) ?? 0;
    final q = calcFreight(km: km, kg: kg, express: _express);
    final cities = kCities.keys.toList()..sort();

    Widget cityDrop(String label, String? value, ValueChanged<String?> on) =>
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final c in cities) DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: on,
        );

    return DialogShell(
      title: 'Calculadora de frete e prazo',
      maxWidth: 540,
      actions: [
        Button3D(
          label: 'Fechar',
          secondary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      child: Column(
        children: [
          LayoutBuilder(
            builder: (_, box) {
              final a = cityDrop(
                'Origem (opcional)',
                _from,
                (v) => setState(() {
                  _from = v;
                  _autoKm();
                }),
              );
              final b = cityDrop(
                'Destino (opcional)',
                _to,
                (v) => setState(() {
                  _to = v;
                  _autoKm();
                }),
              );
              return box.maxWidth > 420
                  ? Row(
                      children: [
                        Expanded(child: a),
                        const SizedBox(width: 10),
                        Expanded(child: b),
                      ],
                    )
                  : Column(children: [a, const SizedBox(height: 10), b]);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _km,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Distância (km)',
                    prefixIcon: Icon(Icons.route_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _kg,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    prefixIcon: Icon(Icons.scale_rounded),
                  ),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Entrega expressa'),
            subtitle: Text(
              '+40% no valor, prazo reduzido',
              style: TextStyle(color: ac.muted),
            ),
            value: _express,
            onChanged: (v) => setState(() => _express = v),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ac.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ac.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Frete estimado', style: TextStyle(color: ac.muted)),
                      Text(
                        _money(q.cost),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Prazo', style: TextStyle(color: ac.muted)),
                    Text(
                      '${q.days} dia${q.days == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
