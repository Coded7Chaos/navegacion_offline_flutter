import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app_navegacion_offline/models/favorite_route.dart';
import 'package:app_navegacion_offline/models/geo_point.dart';
import 'package:app_navegacion_offline/models/location_point.dart';
import 'package:app_navegacion_offline/models/puma_route.dart';
import 'package:app_navegacion_offline/models/search_result.dart';
import 'package:app_navegacion_offline/models/route_schedule.dart';
import 'package:app_navegacion_offline/models/user_profile.dart';
import 'package:app_navegacion_offline/services/local_storage_service.dart';
import 'package:app_navegacion_offline/services/offline_map_service.dart';
import 'package:app_navegacion_offline/services/route_database_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppNavigationOffline());
}

class AppNavigationOffline extends StatelessWidget {
  const AppNavigationOffline({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Navegación Offline',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade700),
        useMaterial3: true,
      ),
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeMapPage(),
    FavoritesPage(),
    RoutesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (value) => setState(() => _selectedIndex = value),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Rutas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class HomeMapPage extends StatefulWidget {
  const HomeMapPage({super.key});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage> {
  late String _stylePath;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  MapLibreMapController? _mapController;
  Timer? _searchDebounce;
  List<SearchResult> _suggestions = [];
  bool _dbReady = false;
  bool _isSearching = false;
  bool _mapStyleReady = false;

  Position? _userPosition;
  StreamSubscription<Position>? _positionSubscription;
  Symbol? _userSymbol;
  bool _userIconReady = false;
  String? _locationStatus;

  Symbol? _selectedSymbol;
  LatLng? _selectedLatLng;
  bool _markerIconReady = false;

  bool get _hasSelectedMarker => _selectedLatLng != null;
  bool get _hasUserLocation => _userPosition != null;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initializeDatabases();
    _initializeLocationTracking();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    _positionSubscription?.cancel();
    _mapController?.onFeatureDrag.remove(_handleFeatureDrag);
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    try {
      final style = await OfflineMapService.instance.getStylePath();
      if (!mounted) return;
      setState(() {
        _stylePath = style;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error preparando mapas: $e');
    }
  }

  Future<void> _initializeDatabases() async {
    await RouteDatabaseService.instance.ensureInitialized();
    if (!mounted) return;
    setState(() => _dbReady = true);
  }

  Future<void> _initializeLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _locationStatus = 'Activa el GPS para mostrar tu ubicación');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _locationStatus = 'Permiso de ubicación denegado permanentemente');
        return;
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() => _locationStatus = 'Permiso de ubicación denegado');
        return;
      }

      setState(() => _locationStatus = null);
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _handleNewPosition(current);

      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(_handleNewPosition);
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      if (!mounted) return;
      setState(() => _locationStatus = 'No se pudo obtener tu ubicación');
    }
  }

  void _handleNewPosition(Position position) {
    setState(() {
      _userPosition = position;
    });
    _addOrMoveUserSymbol();
  }

  Future<void> _addOrMoveUserSymbol() async {
    if (_mapController == null || !_mapStyleReady || _userPosition == null) {
      return;
    }

    await _ensureUserIcon();
    final userLatLng = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    if (_userSymbol == null) {
      _userSymbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: userLatLng,
          iconImage: 'user-location-icon',
          iconSize: 0.7,
          iconAnchor: 'bottom',
        ),
      );
    } else {
      await _mapController!.updateSymbol(
        _userSymbol!,
        SymbolOptions(geometry: userLatLng),
      );
    }
  }

  Future<void> _ensureUserIcon() async {
    if (_mapController == null || _userIconReady) return;
    final bytes = await _createUserIconBytes();
    await _mapController!.addImage('user-location-icon', bytes);
    _userIconReady = true;
  }

  Future<Uint8List> _createUserIconBytes() async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFF1565C0);
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2.4, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.person.codePoint),
        style: TextStyle(
          fontSize: 48,
          fontFamily: Icons.person.fontFamily,
          package: Icons.person.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<void> _ensureMarkerIcon() async {
    if (_mapController == null || _markerIconReady) return;
    final bytes = await _createMarkerIconBytes();
    await _mapController!.addImage('custom-selection-icon', bytes);
    _markerIconReady = true;
  }

  Future<Uint8List> _createMarkerIconBytes() async {
    const width = 110.0;
    const height = 120.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final path = Path()
      ..moveTo(width / 2, height)
      ..cubicTo(width * 0.9, height * 0.7, width * 0.9, height * 0.35, width / 2,
          height * 0.2)
      ..cubicTo(width * 0.1, height * 0.35, width * 0.1, height * 0.7, width / 2,
          height)
      ..close();

    final paint = Paint()..color = const Color(0xFF00897B);
    canvas.drawShadow(path, Colors.black54, 6, true);
    canvas.drawPath(path, paint);

    final circlePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(width / 2, height * 0.42), 22, circlePaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.location_pin.codePoint),
        style: TextStyle(
          fontSize: 30,
          fontFamily: Icons.location_pin.fontFamily,
          package: Icons.location_pin.fontPackage,
          color: const Color(0xFF00897B),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        height * 0.42 - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    _mapController?.onFeatureDrag.add(_handleFeatureDrag);
  }

  void _onStyleLoaded() {
    _mapStyleReady = true;
    _addOrMoveUserSymbol();
    _restoreSelectedMarker();
  }

  Future<void> _restoreSelectedMarker() async {
    if (_mapController == null || _selectedLatLng == null) return;
    await _ensureMarkerIcon();
    if (_selectedSymbol != null) {
      await _mapController!.removeSymbol(_selectedSymbol!);
    }
    _selectedSymbol = await _mapController!.addSymbol(
      SymbolOptions(
        geometry: _selectedLatLng,
        iconImage: 'custom-selection-icon',
        iconSize: 0.8,
        draggable: true,
        iconAnchor: 'bottom',
      ),
    );
  }

  Future<void> _placeMarkerAtCrosshair() async {
    if (_mapController == null) return;
    final cameraPosition = _mapController!.cameraPosition;
    if (cameraPosition == null) return;
    await _setSelectedMarker(cameraPosition.target);
  }

  Future<void> _setSelectedMarker(LatLng target) async {
    if (_mapController == null) return;
    await _ensureMarkerIcon();
    if (_selectedSymbol != null) {
      await _mapController!.removeSymbol(_selectedSymbol!);
    }
    _selectedSymbol = await _mapController!.addSymbol(
      SymbolOptions(
        geometry: target,
        iconImage: 'custom-selection-icon',
        iconSize: 0.8,
        iconAnchor: 'bottom',
        draggable: true,
      ),
    );
    setState(() => _selectedLatLng = target);
  }

  Future<void> _centerOnUser() async {
    if (_mapController == null) return;
    if (_userPosition == null) {
      await _initializeLocationTracking();
      return;
    }
    final target = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16),
      ),
    );
  }

  void _handleFeatureDrag(
    math.Point<double> point,
    LatLng origin,
    LatLng current,
    LatLng delta,
    String id,
    Annotation? annotation,
    DragEventType eventType,
  ) {
    if (annotation is Symbol && _selectedSymbol != null &&
        annotation.id == _selectedSymbol!.id) {
      if (_selectedLatLng != current) {
        setState(() => _selectedLatLng = current);
      }
    }
  }

  void _onCalculateRoute() {
    if (_selectedLatLng == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cálculo de ruta pendiente para (${_selectedLatLng!.latitude.toStringAsFixed(5)}, ${_selectedLatLng!.longitude.toStringAsFixed(5)})',
        ),
      ),
    );
  }

  Widget _buildCenterCrosshair() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 2),
            color: Colors.black.withValues(alpha: 0.2),
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      right: 16,
      bottom: 110,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'center-user',
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            onPressed: _hasUserLocation ? _centerOnUser : _initializeLocationTracking,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'place-marker',
            backgroundColor: Colors.green.shade700,
            onPressed: _mapController == null ? null : _placeMarkerAtCrosshair,
            child: const Icon(Icons.location_on),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    if (!_hasSelectedMarker) return const SizedBox.shrink();
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: SafeArea(
        top: false,
        child: FilledButton(
          onPressed: _onCalculateRoute,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('CALCULAR RUTA'),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    final results = await RouteDatabaseService.instance.search(query);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _isSearching = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _suggestions = [];
      _isSearching = false;
    });
  }

  Future<void> _onSuggestionTap(SearchResult result) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.text = result.title;
      _suggestions = [];
    });

    if (result.location != null) {
      await _moveCameraTo(result.location!);
    } else if (result.route != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ruta ${result.route!.name} - ${result.route!.direction}')),
      );
    }
  }

  Future<void> _moveCameraTo(LocationPoint point) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(point.latitude, point.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    final query = _searchController.text.trim();
    if (query.isEmpty || !_dbReady) return const SizedBox.shrink();

    final double topOffset = _locationStatus != null ? 138 : 96;

    return Positioned(
      left: 16,
      right: 16,
      top: topOffset,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _suggestions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No se encontraron coincidencias'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: _suggestions.length,
                        separatorBuilder: (context, index) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final result = _suggestions[index];
                          return ListTile(
                            leading: Icon(_iconForResult(result)),
                            title: Text(result.title),
                            subtitle: Text(result.subtitle),
                            onTap: () => _onSuggestionTap(result),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  IconData _iconForResult(SearchResult result) {
    if (result.type == SearchResultType.route) {
      return Icons.directions_bus;
    }
    return result.location?.type == LocationPointType.stop
        ? Icons.directions_bus_filled
        : Icons.place;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparando mapas offline...'),
          ],
        ),
      );
    }

    return SafeArea(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  enabled: _dbReady,
                  decoration: InputDecoration(
                    hintText: 'Buscar calles, paradas o rutas',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _clearSearch,
                              )
                            : null),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (_locationStatus != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationStatus!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      MapLibreMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(-16.5000, -68.1193),
                          zoom: 12,
                        ),
                        styleString: _stylePath,
                        trackCameraPosition: true,
                        onMapCreated: _onMapCreated,
                        onStyleLoadedCallback: _onStyleLoaded,
                        onCameraIdle: () => setState(() {}),
                      ),
                      _buildCenterCrosshair(),
                      _buildActionButtons(),
                      _buildCalculateButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildSuggestionsOverlay(),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FavoriteRoute>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = LocalStorageService.instance.getFavoriteRoutes();
  }

  Future<void> _refreshFavorites() async {
    setState(() {
      _favoritesFuture = LocalStorageService.instance.getFavoriteRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshFavorites,
        child: FutureBuilder<List<FavoriteRoute>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
                ],
              );
            }

            final favorites = snapshot.data ?? [];

            if (favorites.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.star_border, size: 72, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No existen rutas guardadas en favoritos',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Rutas guardadas en favoritos',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final route = favorites[index - 1];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(route.title),
                    subtitle: Text(route.description),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  late Future<List<PumaRoute>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _routesFuture = _loadRoutes();
  }

  Future<List<PumaRoute>> _loadRoutes() async {
    await RouteDatabaseService.instance.ensureInitialized();
    return RouteDatabaseService.instance.getAllRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<PumaRoute>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Error al cargar rutas del PumaKatari.'),
              ),
            );
          }

          final routes = snapshot.data ?? [];
          if (routes.isEmpty) {
            return const Center(child: Text('No se encontraron rutas del PumaKatari.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Rutas del PumaKatari',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                );
              }

              final route = routes[index - 1];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: route.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                    child: Icon(
                      Icons.directions_bus,
                      color: route.isActive ? Colors.green.shade700 : Colors.grey,
                    ),
                  ),
                  title: Text(route.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PumaRouteDetailPage(route: route),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PumaRouteDetailPage extends StatefulWidget {
  const PumaRouteDetailPage({super.key, required this.route});

  final PumaRoute route;

  @override
  State<PumaRouteDetailPage> createState() => _PumaRouteDetailPageState();
}

class _PumaRouteDetailPageState extends State<PumaRouteDetailPage> {
  bool _loading = true;
  String? _stylePath;
  List<LocationPoint> _stops = [];
  List<GeoPoint> _polyline = [];
  List<RouteSchedule> _schedules = [];
  RouteSchedule? _todaySchedule;
  MapLibreMapController? _mapController;
  Line? _routeLine;
  final List<Symbol> _stopSymbols = [];
  bool _busIconReady = false;
  bool _mapReady = false;
  bool _hasCenteredOnUser = false;
  String? _error;

  Position? _userPosition;
  Symbol? _userSymbol;
  bool _userIconReady = false;
  StreamSubscription<Position>? _locationSubscription;

  bool get _hasUserLocation => _userPosition != null;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initUserLocation();
  }

  @override
  void dispose() {
    _removeMapDecorations();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final style = await OfflineMapService.instance.getStylePath();
      await RouteDatabaseService.instance.ensureInitialized();
      final stopsFuture = RouteDatabaseService.instance.getStopsForRoute(widget.route.id);
      final polylineFuture = RouteDatabaseService.instance.getRoutePolyline(widget.route.id);
      final schedulesFuture = RouteDatabaseService.instance.getRouteSchedules(widget.route.id);
      final stops = await stopsFuture;
      final polyline = await polylineFuture;
      final schedules = await schedulesFuture;
      if (!mounted) return;
      setState(() {
        _stylePath = style;
        _stops = stops;
        _polyline = polyline;
        _schedules = schedules;
        _todaySchedule = _selectScheduleForToday(schedules);
        _loading = false;
      });
      await _renderRoute();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar la ruta seleccionada.';
        _loading = false;
      });
    }
  }

  Future<void> _onMapCreated(MapLibreMapController controller) async {
    _mapController = controller;
    await _renderRoute();
    await _addOrMoveUserSymbol();
  }

  void _onStyleLoaded() {
    _mapReady = true;
    _renderRoute();
    _addOrMoveUserSymbol();
  }

  Future<void> _renderRoute() async {
    if (_mapController == null || _stylePath == null || _polyline.isEmpty || !_mapReady) {
      return;
    }

    await _addLine();
    await _addStopSymbols();
    if (_userPosition == null) {
      await _fitCameraToRoute();
    } else {
      await _maybeCenterOnUser();
    }
  }

  Future<void> _addLine() async {
    if (_mapController == null) return;
    if (_routeLine != null) {
      await _mapController!.removeLine(_routeLine!);
      _routeLine = null;
    }
    final geometry = _polyline
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    if (geometry.isEmpty) return;
    _routeLine = await _mapController!.addLine(
      LineOptions(
        geometry: geometry,
        lineColor: '#0C7C59',
        lineWidth: 4.5,
        lineOpacity: 0.85,
      ),
    );
  }

  Future<void> _addStopSymbols() async {
    if (_mapController == null) return;
    if (_stopSymbols.isNotEmpty) {
      await _mapController!.removeSymbols(_stopSymbols);
      _stopSymbols.clear();
    }
    if (_stops.isEmpty) return;

    await _ensureBusIcon();
    for (final stop in _stops) {
      final symbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(stop.latitude, stop.longitude),
          iconImage: 'bus-stop-icon',
          iconSize: 0.6,
          iconAnchor: 'bottom',
        ),
      );
      _stopSymbols.add(symbol);
    }
  }

  Future<void> _ensureBusIcon() async {
    if (_busIconReady || _mapController == null) return;
    final iconBytes = await _createBusIconBytes();
    await _mapController!.addImage('bus-stop-icon', iconBytes);
    _busIconReady = true;
  }

  Future<void> _initUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _handleUserPosition(current);

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen(_handleUserPosition);
    } catch (e) {
      debugPrint('No se pudo obtener ubicación de usuario en detalle: $e');
    }
  }

  void _handleUserPosition(Position position) {
    _userPosition = position;
    _addOrMoveUserSymbol();
    _maybeCenterOnUser();
  }

  Future<void> _ensureUserIcon() async {
    if (_mapController == null || _userIconReady) return;
    final bytes = await _createUserIconBytes();
    await _mapController!.addImage('user-location-icon', bytes);
    _userIconReady = true;
  }

  Future<Uint8List> _createUserIconBytes() async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFF1565C0);
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2.4, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.person.codePoint),
        style: TextStyle(
          fontSize: 48,
          fontFamily: Icons.person.fontFamily,
          package: Icons.person.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<void> _addOrMoveUserSymbol() async {
    if (_mapController == null || _userPosition == null || !_mapReady) return;
    await _ensureUserIcon();
    final latLng = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    if (_userSymbol == null) {
      _userSymbol = await _mapController!.addSymbol(
        SymbolOptions(
          geometry: latLng,
          iconImage: 'user-location-icon',
          iconSize: 0.7,
          iconAnchor: 'bottom',
        ),
      );
    } else {
      await _mapController!.updateSymbol(
        _userSymbol!,
        SymbolOptions(geometry: latLng),
      );
    }
  }

  Future<void> _maybeCenterOnUser() async {
    if (_mapController == null || _userPosition == null || !_mapReady) return;
    if (_hasCenteredOnUser) return;
    _hasCenteredOnUser = true;
    final target = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 14),
      ),
    );
  }

  Future<void> _centerOnUser() async {
    if (_mapController == null) return;
    if (_userPosition == null) {
      await _initUserLocation();
      return;
    }
    final target = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: FloatingActionButton.small(
        heroTag: 'center-route-user-${widget.route.id}',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        onPressed: _hasUserLocation ? _centerOnUser : _initUserLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildScheduleCard() {
    final today = _todaySchedule;
    final hasSchedules = _schedules.isNotEmpty;
    final subtitle = today != null
        ? '${today.dayDescription}\n${today.formattedRange}'
        : 'No hay horarios registrados para esta ruta';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: const Text(
          'Horario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        onTap: hasSchedules ? _openSchedulesPage : null,
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: hasSchedules ? _openSchedulesPage : null,
        ),
      ),
    );
  }

  Future<void> _openSchedulesPage() async {
    if (_schedules.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteSchedulePage(route: widget.route, schedules: _schedules),
      ),
    );
  }

  RouteSchedule? _selectScheduleForToday(List<RouteSchedule> schedules) {
    if (schedules.isEmpty) return null;
    final now = DateTime.now();
    final weekday = now.weekday;
    RouteSchedule? match;
    for (final schedule in schedules) {
      if (_matchesDay(schedule.dayDescription, weekday)) {
        match = schedule;
        break;
      }
    }
    return match ?? schedules.first;
  }

  bool _matchesDay(String description, int weekday) {
    final normalized = _normalizeText(description);
    final dayMap = {
      DateTime.monday: ['lunes'],
      DateTime.tuesday: ['martes'],
      DateTime.wednesday: ['miercoles'],
      DateTime.thursday: ['jueves'],
      DateTime.friday: ['viernes'],
      DateTime.saturday: ['sabado'],
      DateTime.sunday: ['domingo', 'festivo', 'feriado'],
    };

    final terms = dayMap[weekday] ?? [];
    if (terms.any((term) => normalized.contains(term))) {
      return true;
    }

    if (weekday >= DateTime.monday && weekday <= DateTime.friday) {
      if (normalized.contains('lunes a viernes') || normalized.contains('dias habiles') || normalized.contains('semana')) {
        return true;
      }
    }

    if (weekday == DateTime.saturday &&
        (normalized.contains('fin de semana') || normalized.contains('sabados'))) {
      return true;
    }

    if (weekday == DateTime.sunday &&
        (normalized.contains('fin de semana') || normalized.contains('domingos'))) {
      return true;
    }

    return false;
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  Future<Uint8List> _createBusIconBytes() async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFF0C7C59);
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2.2, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.directions_bus.codePoint),
        style: TextStyle(
          fontSize: 52,
          fontFamily: Icons.directions_bus.fontFamily,
          package: Icons.directions_bus.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<void> _fitCameraToRoute() async {
    if (_mapController == null || _polyline.isEmpty) return;
    double minLat = _polyline.first.latitude;
    double maxLat = _polyline.first.latitude;
    double minLng = _polyline.first.longitude;
    double maxLng = _polyline.first.longitude;

    for (final point in _polyline) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, left: 32, right: 32, top: 32, bottom: 180),
    );
  }

  Future<void> _openStopsPage() async {
    final selectedStop = await Navigator.of(context).push<LocationPoint?>(
      MaterialPageRoute(
        builder: (_) => RouteStopsPage(route: widget.route, stops: _stops),
      ),
    );
    if (selectedStop != null) {
      await _focusOnStop(selectedStop);
    }
  }

  Future<void> _focusOnStop(LocationPoint stop) async {
    if (_mapController == null) return;
    final currentZoom = _mapController!.cameraPosition?.zoom ?? 13;
    final targetZoom = (currentZoom + 2).clamp(0, 20);
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(stop.latitude, stop.longitude),
          zoom: targetZoom.toDouble(),
        ),
      ),
    );
  }

  void _removeMapDecorations() {
    if (_routeLine != null) {
      _mapController?.removeLine(_routeLine!);
      _routeLine = null;
    }
    if (_stopSymbols.isNotEmpty) {
      _mapController?.removeSymbols(_stopSymbols);
      _stopSymbols.clear();
    }
    if (_userSymbol != null) {
      _mapController?.removeSymbol(_userSymbol!);
      _userSymbol = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.route.name;
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : _stylePath == null
                ? const Center(child: Text('No se pudo preparar el mapa.'))
                : Column(
                    children: [
                      _buildScheduleCard(),
                      Expanded(
                        child: Stack(
                            children: [
                              MapLibreMap(
                              styleString: _stylePath!,
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(-16.5000, -68.1193),
                                zoom: 12,
                              ),
                              trackCameraPosition: true,
                              onMapCreated: _onMapCreated,
                              onStyleLoadedCallback: _onStyleLoaded,
                            ),
                            if (_polyline.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No se encontraron datos para dibujar la ruta.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            _buildCenterButton(),
                          ],
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: FilledButton.icon(
                            onPressed: _stops.isEmpty ? null : _openStopsPage,
                            icon: const Icon(Icons.directions_bus),
                            label: const Text('Paradas'),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          ),
                        ),
                      ),
                    ],
                  );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}

class RouteStopsPage extends StatelessWidget {
  const RouteStopsPage({super.key, required this.route, required this.stops});

  final PumaRoute route;
  final List<LocationPoint> stops;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paradas - ${route.name}'),
      ),
      body: stops.isEmpty
          ? const Center(child: Text('No existen paradas registradas para esta ruta.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stops.length,
              itemBuilder: (context, index) {
                final stop = stops[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text(
                      stop.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(stop.address ?? 'Sin dirección'),
                    onTap: () => Navigator.of(context).pop(stop),
                  ),
                );
              },
            ),
    );
  }
}

class RouteSchedulePage extends StatelessWidget {
  const RouteSchedulePage({super.key, required this.route, required this.schedules});

  final PumaRoute route;
  final List<RouteSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Horarios - ${route.name}')),
      body: schedules.isEmpty
          ? const Center(child: Text('No hay horarios disponibles.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text(
                      schedule.dayDescription,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(schedule.formattedRange),
                  ),
                );
              },
            ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await LocalStorageService.instance.getUserProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  void _openRegistrationForm() {
    final parentContext = context;
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      builder: (sheetContext) => RegistrationForm(
        initialProfile: _profile,
        onSaved: (profile) {
          setState(() => _profile = profile);
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('Perfil guardado correctamente')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasProfile = _profile != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey.shade200,
              child: Icon(
                hasProfile ? Icons.person : Icons.person_outline,
                size: 56,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasProfile ? _profile!.name : 'Invitado',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(hasProfile ? _profile!.email : 'No has iniciado sesión'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Iniciar sesión'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿No tienes cuenta? Regístrate '),
                TextButton(
                  onPressed: _openRegistrationForm,
                  child: const Text('AQUÍ'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key, required this.onSaved, this.initialProfile});

  final void Function(UserProfile profile) onSaved;
  final UserProfile? initialProfile;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile?.name);
    _emailController = TextEditingController(text: widget.initialProfile?.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final profile = UserProfile(
      id: widget.initialProfile?.id ?? 0,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    await LocalStorageService.instance.saveUserProfile(profile);
    if (!mounted) return;
    widget.onSaved(profile);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: padding.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Registro',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingresa tu correo' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
