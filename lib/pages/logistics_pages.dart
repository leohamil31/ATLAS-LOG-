/// Telas de logística do ATLAS LOG.
///
/// Este arquivo é só a "biblioteca": imports compartilhados + `part`s.
/// Cada tela vive em `logistics/` e compartilha os widgets privados (`_X`)
/// sem precisar torná-los públicos:
///   shell.dart                 → LogisticsShell (sidebar, top bar, Ctrl+K)
///   dashboard_page.dart        → DashboardPage
///   orders_page.dart           → OrdersPage
///   fleet_page.dart            → FleetPage
///   public_tracking_page.dart  → PublicTrackingPage
library;

import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/format.dart';
import '../core/geo.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/store.dart';
import '../widgets/atlas_logo_3d.dart';
import '../widgets/button3d.dart';
import '../widgets/common.dart';
import '../widgets/extras_dialogs.dart';
import '../widgets/icon3d.dart';
import '../widgets/order_dialogs.dart';
import 'management_pages.dart';

part 'logistics/shell.dart';
part 'logistics/dashboard_page.dart';
part 'logistics/orders_page.dart';
part 'logistics/fleet_page.dart';
part 'logistics/public_tracking_page.dart';
