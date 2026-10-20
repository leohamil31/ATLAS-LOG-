/// Utilitários de geografia e logística: coordenadas das cidades, distâncias,
/// cálculo de frete/prazo e otimização da sequência de paradas.
library;

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/models.dart';

const Map<String, LatLng> kCities = {
  'São Paulo, SP': LatLng(-23.5505, -46.6333),
  'Rio de Janeiro, RJ': LatLng(-22.9068, -43.1729),
  'Belo Horizonte, MG': LatLng(-19.9167, -43.9345),
  'Vitória, ES': LatLng(-20.3155, -40.3128),
  'Curitiba, PR': LatLng(-25.4284, -49.2733),
  'Porto Alegre, RS': LatLng(-30.0346, -51.2177),
  'Campinas, SP': LatLng(-22.9099, -47.0626),
  'Goiânia, GO': LatLng(-16.6869, -49.2648),
  'Santos, SP': LatLng(-23.9618, -46.3322),
  'Brasília, DF': LatLng(-15.7939, -47.8828),
  'Salvador, BA': LatLng(-12.9777, -38.5016),
  'Recife, PE': LatLng(-8.0476, -34.8770),
  'Florianópolis, SC': LatLng(-27.5954, -48.5480),
  'Fortaleza, CE': LatLng(-3.7319, -38.5267),
  'Uberlândia, MG': LatLng(-18.9186, -48.2772),
  'Ribeirão Preto, SP': LatLng(-21.1775, -47.8103),
};

String _norm(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const to = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  var out = s.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    out = out.replaceAll(from[i].toLowerCase(), to[i].toLowerCase());
  }
  return out.trim();
}

/// Procura a cidade pelo texto livre (ignora acentos/maiúsculas e a UF).
LatLng? cityPos(String text) {
  final t = _norm(text.split(',').first);
  if (t.isEmpty) return null;
  for (final e in kCities.entries) {
    if (_norm(e.key.split(',').first) == t) return e.value;
  }
  return null;
}

const _dist = Distance();

/// Distância em km entre dois pontos (reta).
double kmBetween(LatLng a, LatLng b) => _dist.as(LengthUnit.Kilometer, a, b);

/// Distância rodoviária estimada (reta x 1,22) entre duas cidades, ou null.
double? roadKm(String origem, String destino) {
  final a = cityPos(origem);
  final b = cityPos(destino);
  if (a == null || b == null) return null;
  return kmBetween(a, b) * 1.22;
}

/// Posição estimada de um pedido ativo, interpolando origem -> destino.
LatLng? orderPosition(Order o) {
  final a = cityPos(o.origem);
  final b = cityPos(o.destino);
  if (a == null || b == null) return null;
  final t = (o.stage / 4).clamp(0.05, 0.95);
  return LatLng(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t,
  );
}

class FreightQuote {
  FreightQuote(this.cost, this.days, this.km, this.kg, this.express);

  final double cost;
  final int days;
  final double km;
  final double kg;
  final bool express;
}

/// Frete = base + km x tarifa + peso x tarifa (+ seguro 1%); expresso +40%.
FreightQuote calcFreight({
  required double km,
  required double kg,
  bool express = false,
}) {
  final perKg = kg <= 100 ? 0.45 : (kg <= 1000 ? 0.32 : 0.22);
  var cost = 85 + km * 2.15 + kg * perKg * (km / 400).clamp(0.5, 4);
  cost *= 1.01;
  var days = (km / 550).ceil() + 1;
  if (express) {
    cost *= 1.4;
    days = math.max(1, (days * 0.6).round());
  }
  return FreightQuote(cost, days, km, kg, express);
}

class RouteStop {
  RouteStop(this.order, this.pos);

  final Order order;
  final LatLng pos;
}

class OptimizedRoute {
  OptimizedRoute(this.stops, this.optimizedKm, this.originalKm);

  final List<RouteStop> stops;
  final double optimizedKm;
  final double originalKm;

  double get savedKm => math.max(0, originalKm - optimizedKm);
}

double _routeKm(LatLng start, List<RouteStop> stops) {
  var km = 0.0;
  var cur = start;
  for (final s in stops) {
    km += kmBetween(cur, s.pos);
    cur = s.pos;
  }
  return km;
}

/// Vizinho mais próximo + refinamento 2-opt a partir de [start].
OptimizedRoute optimizeRoute(LatLng start, List<RouteStop> input) {
  final original = _routeKm(start, input);
  final remaining = [...input];
  final route = <RouteStop>[];
  var cur = start;
  while (remaining.isNotEmpty) {
    remaining.sort(
      (a, b) => kmBetween(cur, a.pos).compareTo(kmBetween(cur, b.pos)),
    );
    final next = remaining.removeAt(0);
    route.add(next);
    cur = next.pos;
  }
  var improved = true;
  while (improved) {
    improved = false;
    for (var i = 0; i < route.length - 1; i++) {
      for (var j = i + 1; j < route.length; j++) {
        final candidate = [
          ...route.sublist(0, i),
          ...route.sublist(i, j + 1).reversed,
          ...route.sublist(j + 1),
        ];
        if (_routeKm(start, candidate) + 0.01 < _routeKm(start, route)) {
          route
            ..clear()
            ..addAll(candidate);
          improved = true;
        }
      }
    }
  }
  return OptimizedRoute(route, _routeKm(start, route), original);
}
