import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ubicacion.dart';
import '../repositories/data_repository.dart';

class RouteSegmentScreen extends StatefulWidget {
  final RouteSearchResult result;
  final DataRepository repository;
  final LatLng origin;
  final LatLng destination;

  const RouteSegmentScreen({
    super.key,
    required this.result,
    required this.repository,
    required this.origin,
    required this.destination,
  });

  @override
  State<RouteSegmentScreen> createState() => _RouteSegmentScreenState();
}

class _RouteSegmentScreenState extends State<RouteSegmentScreen> {
  MapLibreMapController? _controller;
  String? _stylePath;
  bool _isLoadingMap = true;
  bool _isStyleLoaded = false;
  bool _iconsLoaded = false;
  bool _instructionsExpanded = false;

  static const String _stopIconName = "parada_bus";
  static const String _boardIconName = "parada_subida";
  static const String _alightIconName = "parada_bajada";
  static const String _destinationIconName = "destino_icon";
  static const String _originIconName = "origen_icon";
  bool _boardIconLoaded = false;
  bool _alightIconLoaded = false;
  bool _destinationIconLoaded = false;
  bool _stopIconLoaded = false;
  bool _originIconLoaded = false;

  @override
  void initState() {
    super.initState();
    _prepareOfflineStyle();
  }

  Future<void> _prepareOfflineStyle() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mapsDir = Directory('${directory.path}/maps');
      if (!await mapsDir.exists()) await mapsDir.create();

      final mbtilesPath = '${mapsDir.path}/lapaz.mbtiles';
      if (!File(mbtilesPath).existsSync()) {
        final byteData = await rootBundle.load('assets/maps/lapaz.mbtiles');
        await File(mbtilesPath).writeAsBytes(byteData.buffer.asUint8List());
      }

      final styleString = await rootBundle.loadString('assets/maps/style.json');
      final finalStyle =
          styleString.replaceFirst('{path_to_mbtiles}', mbtilesPath);
      final styleFile = File('${mapsDir.path}/style_final.json');
      await styleFile.writeAsString(finalStyle);

      if (!mounted) return;
      setState(() {
        _stylePath = styleFile.path;
        _isLoadingMap = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMap = false);
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
  }

  Future<void> _onStyleLoaded() async {
    if (!mounted || _controller == null) return;
    _isStyleLoaded = true;

    try {
      await _controller!.setSymbolIconAllowOverlap(true);
      await _controller!.setSymbolIconIgnorePlacement(true);
      await _controller!.setSymbolTextAllowOverlap(true);
      await _controller!.setSymbolTextIgnorePlacement(true);
    } catch (_) {}

    final theme = Theme.of(context);
    try {
      final stopBytes = await _materialIconPngBytes(
        Icons.directions_bus_rounded,
        iconColor: theme.primaryColor,
        size: 84,
        backgroundColor: Colors.white,
      );
      await _controller!.addImage(_stopIconName, stopBytes);
      _stopIconLoaded = true;

      final boardBytes = await _materialIconPngBytes(
        Icons.person_pin_circle_rounded,
        iconColor: const Color(0xFF1B5E20),
        size: 88,
        backgroundColor: Colors.white,
      );
      await _controller!.addImage(_boardIconName, boardBytes);
      _boardIconLoaded = true;

      final alightBytes = await _materialIconPngBytes(
        Icons.place_rounded,
        iconColor: const Color(0xFFF57C00),
        size: 88,
        backgroundColor: Colors.white,
      );
      await _controller!.addImage(_alightIconName, alightBytes);
      _alightIconLoaded = true;

      final destBytes = await _materialIconPngBytes(
        Icons.flag_rounded,
        iconColor: const Color(0xFFE53935),
        size: 88,
        backgroundColor: Colors.white,
      );
      await _controller!.addImage(_destinationIconName, destBytes);
      _destinationIconLoaded = true;

      final originBytes = await _materialIconPngBytes(
        Icons.my_location_rounded,
        iconColor: const Color(0xFF1E88E5),
        size: 78,
        backgroundColor: Colors.white,
      );
      await _controller!.addImage(_originIconName, originBytes);
      _originIconLoaded = true;

      _iconsLoaded = true;
    } catch (_) {
      _iconsLoaded = false;
    }

    await _drawSegment();
  }

  Future<void> _drawSegment() async {
    if (_controller == null || !_isStyleLoaded || !_iconsLoaded) return;

    final startCoordId = widget.result.startInfo.idCoordenada;
    final endCoordId = widget.result.endInfo.idCoordenada;
    final List<Ubicacion> coords =
        await widget.repository.getPolylineBetweenCoords(startCoordId, endCoordId);
    final geometry =
        coords.map((u) => LatLng(u.latitud, u.longitud)).toList();

    if (geometry.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo dibujar el tramo de la ruta.')),
      );
      return;
    }

    await _controller!.addLine(LineOptions(
      geometry: geometry,
      lineColor: "#D97846",
      lineWidth: 5.0,
      lineOpacity: 0.85,
    ));

    await _controller!.addSymbol(SymbolOptions(
      geometry: LatLng(widget.result.startStop.lat, widget.result.startStop.lon),
      iconImage: _boardIconLoaded
          ? _boardIconName
          : (_stopIconLoaded ? _stopIconName : "marker-15"),
      iconSize: _boardIconLoaded
          ? 0.18
          : (_stopIconLoaded ? 0.28 : 1.6),
      iconAnchor: "bottom",
      textField: "Sube: ${widget.result.startStop.nombre}",
      textOffset: const Offset(0, 1.4),
      textSize: 12,
    ));

    await _controller!.addSymbol(SymbolOptions(
      geometry: LatLng(widget.result.endStop.lat, widget.result.endStop.lon),
      iconImage: _alightIconLoaded
          ? _alightIconName
          : (_stopIconLoaded ? _stopIconName : "marker-15"),
      iconSize: _alightIconLoaded
          ? 0.18
          : (_stopIconLoaded ? 0.28 : 1.6),
      iconAnchor: "bottom",
      textField: "Baja: ${widget.result.endStop.nombre}",
      textOffset: const Offset(0, 1.4),
      textSize: 12,
    ));

    await _controller!.addSymbol(SymbolOptions(
      geometry: widget.destination,
      iconImage: _destinationIconLoaded ? _destinationIconName : "marker-15",
      iconSize: _destinationIconLoaded ? 0.18 : 1.6,
      iconAnchor: "bottom",
      textField: "Destino",
      textOffset: const Offset(0, 1.4),
      textSize: 12,
    ));

    await _controller!.addSymbol(SymbolOptions(
      geometry: widget.origin,
      iconImage: _originIconLoaded ? _originIconName : "marker-15",
      iconSize: _originIconLoaded ? 0.16 : 1.6,
      iconAnchor: "center",
      textField: "Origen",
      textOffset: const Offset(0, 1.6),
      textSize: 12,
    ));

    await _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        _boundsFrom([
          ...geometry,
          LatLng(widget.origin.latitude, widget.origin.longitude),
          widget.destination,
        ]),
        left: 40,
        top: 140,
        right: 40,
        bottom: 220,
      ),
    );
  }

  LatLngBounds _boundsFrom(List<LatLng> coords) {
    double minLat = coords.first.latitude;
    double maxLat = coords.first.latitude;
    double minLon = coords.first.longitude;
    double maxLon = coords.first.longitude;
    for (final c in coords) {
      minLat = min(minLat, c.latitude);
      maxLat = max(maxLat, c.latitude);
      minLon = min(minLon, c.longitude);
      maxLon = max(maxLon, c.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * (pi / 180.0);
    final dLon = (b.longitude - a.longitude) * (pi / 180.0);
    final lat1 = a.latitude * (pi / 180.0);
    final lat2 = b.latitude * (pi / 180.0);
    final sinDLat = sin(dLat / 2);
    final sinDLon = sin(dLon / 2);
    final h = sinDLat * sinDLat + cos(lat1) * cos(lat2) * sinDLon * sinDLon;
    return 2 * r * atan2(sqrt(h), sqrt(1 - h));
  }

  Future<Uint8List> _materialIconPngBytes(
    IconData icon, {
    required Color iconColor,
    required double size,
    Color? backgroundColor,
  }) async {
    const padding = 18.0;
    final pixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final imageSize = ((size + padding * 2) * pixelRatio).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, imageSize.toDouble(), imageSize.toDouble()),
    );

    if (backgroundColor != null) {
      final paint = Paint()..color = backgroundColor;
      final radius = (imageSize / 2).toDouble();
      canvas.drawCircle(Offset(radius, radius), radius, paint);
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * pixelRatio,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: iconColor,
      ),
    );
    textPainter.layout();

    final dx = (imageSize - textPainter.width) / 2;
    final dy = (imageSize - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(dx, dy));

    final picture = recorder.endRecording();
    final image = await picture.toImage(imageSize, imageSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  String _formatMeters(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatWalkTime(double meters) {
    const metersPerMinute = 80.0; // ~4.8km/h
    final minutes = max(1, (meters / metersPerMinute).round());
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final walkToStart = _distanceMeters(
      widget.origin,
      LatLng(widget.result.startStop.lat, widget.result.startStop.lon),
    );
    final walkToDest = _distanceMeters(
      LatLng(widget.result.endStop.lat, widget.result.endStop.lon),
      widget.destination,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.result.routeName.isEmpty
            ? 'Ruta recomendada'
            : widget.result.routeName),
      ),
      body: _isLoadingMap
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                MapLibreMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.origin,
                    zoom: 13,
                  ),
                  styleString: _stylePath ?? "",
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoaded,
                  myLocationEnabled: true,
                  myLocationTrackingMode: MyLocationTrackingMode.none,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxExpandedHeight =
                                    MediaQuery.of(context).size.height * 0.52;
                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: _instructionsExpanded
                                        ? maxExpandedHeight
                                        : 110,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Material(
                                        color: Colors.white,
                                        child: InkWell(
                                          onTap: () => setState(() {
                                            _instructionsExpanded =
                                                !_instructionsExpanded;
                                          }),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                14, 12, 10, 12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: theme.primaryColor
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                  ),
                                                  child: Icon(
                                                    Icons.route_rounded,
                                                    color: theme.primaryColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        widget.result.routeName
                                                                .isEmpty
                                                            ? 'Ruta recomendada'
                                                            : widget
                                                                .result
                                                                .routeName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: theme.textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 6,
                                                        children: [
                                                          _InfoChip(
                                                            icon: Icons
                                                                .directions_walk_rounded,
                                                            label:
                                                                '${_formatMeters(walkToStart)} • ${_formatWalkTime(walkToStart)}',
                                                          ),
                                                          _InfoChip(
                                                            icon: Icons
                                                                .flag_rounded,
                                                            label:
                                                                '${_formatMeters(walkToDest)} • ${_formatWalkTime(walkToDest)}',
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  _instructionsExpanded
                                                      ? Icons
                                                          .keyboard_arrow_down_rounded
                                                      : Icons
                                                          .keyboard_arrow_up_rounded,
                                                  size: 30,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!_instructionsExpanded)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              14, 0, 14, 14),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.touch_app_rounded,
                                                color: Colors.grey.shade600,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Toca para ver instrucciones',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (_instructionsExpanded)
                                        Expanded(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 220),
                                            child: SingleChildScrollView(
                                              key: const ValueKey(
                                                  'instructionsScroll'),
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      14, 0, 14, 14),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Guía paso a paso',
                                                    style: theme
                                                        .textTheme.titleSmall
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  _StepTile(
                                                    step: 1,
                                                    icon: Icons
                                                        .directions_walk_rounded,
                                                    title:
                                                        'Camina a la parada de subida',
                                                    subtitle:
                                                        '${widget.result.startStop.nombre} • ~${_formatMeters(walkToStart)}',
                                                    color: const Color(
                                                        0xFF4CAF50),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  _StepTile(
                                                    step: 2,
                                                    icon: Icons
                                                        .directions_bus_rounded,
                                                    title: 'Toma la ruta',
                                                    subtitle: widget.result
                                                            .routeName.isEmpty
                                                        ? 'Ruta ${widget.result.routeId}'
                                                        : widget.result
                                                            .routeName,
                                                    color: const Color(
                                                        0xFF2196F3),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  _StepTile(
                                                    step: 3,
                                                    icon: Icons.place_rounded,
                                                    title:
                                                        'Bájate en la parada',
                                                    subtitle: widget
                                                        .result.endStop.nombre,
                                                    color: const Color(
                                                        0xFFFF9800),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  _StepTile(
                                                    step: 4,
                                                    icon: Icons.flag_rounded,
                                                    title: 'Camina al destino',
                                                    subtitle:
                                                        'Destino • ~${_formatMeters(walkToDest)}',
                                                    color: const Color(
                                                        0xFF9C27B0),
                                                  ),
                                                  const SizedBox(height: 14),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .all(12),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      border: Border.all(
                                                        color: Colors
                                                            .grey.shade200,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .info_outline_rounded,
                                                              color: theme
                                                                  .primaryColor,
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Text(
                                                              'Detalles',
                                                              style: theme
                                                                  .textTheme
                                                                  .titleSmall
                                                                  ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 10),
                                                        _DetailRow(
                                                          icon: Icons
                                                              .play_circle_fill_rounded,
                                                          label: 'Subida',
                                                          value: widget.result
                                                              .startStop.nombre,
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        _DetailRow(
                                                          icon: Icons
                                                              .stop_circle_rounded,
                                                          label: 'Bajada',
                                                          value: widget.result
                                                              .endStop.nombre,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _StepTile({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$step',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.primaryColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
