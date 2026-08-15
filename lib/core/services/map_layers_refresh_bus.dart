// lib/core/services/map_layers_refresh_bus.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-app refresh bus for GIS layers.
///
/// When admin updates gis.gis_layers flags (is_public/is_active), bump this
/// counter to ask any open MapPage to reload its layers/features.
final mapLayersRefreshTickProvider = StateProvider<int>((ref) => 0);
