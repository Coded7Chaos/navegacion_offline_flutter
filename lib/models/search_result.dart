import 'package:app_navegacion_offline/models/location_point.dart';
import 'package:app_navegacion_offline/models/puma_route.dart';

enum SearchResultType { location, route }

class SearchResult {
  const SearchResult._({
    required this.type,
    required this.title,
    required this.subtitle,
    this.location,
    this.route,
  });

  final SearchResultType type;
  final String title;
  final String subtitle;
  final LocationPoint? location;
  final PumaRoute? route;

  factory SearchResult.fromLocation(LocationPoint point) {
    return SearchResult._(
      type: SearchResultType.location,
      title: point.name,
      subtitle: point.address != null && point.address!.isNotEmpty
          ? point.address!
          : point.type == LocationPointType.stop
              ? 'Parada PumaKatari'
              : 'Ubicación',
      location: point,
      route: null,
    );
  }

  factory SearchResult.fromRoute(PumaRoute route) {
    return SearchResult._(
      type: SearchResultType.route,
      title: route.name,
      subtitle: 'Sentido ${route.direction}',
      route: route,
      location: null,
    );
  }
}
