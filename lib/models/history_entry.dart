class HistoryEntry {
  final String id;
  final DateTime timestamp;

  final double originLat;
  final double originLon;
  final double destinationLat;
  final double destinationLon;

  final int routeId;
  final String routeName;

  final String boardStopName;
  final double boardStopLat;
  final double boardStopLon;
  final int? boardStopId;
  final int boardCoordId;
  final int boardOrder;

  final String alightStopName;
  final double alightStopLat;
  final double alightStopLon;
  final int? alightStopId;
  final int alightCoordId;
  final int alightOrder;

  final double totalWalkingDistance;

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.originLat,
    required this.originLon,
    required this.destinationLat,
    required this.destinationLon,
    required this.routeId,
    required this.routeName,
    required this.boardStopName,
    required this.boardStopLat,
    required this.boardStopLon,
    required this.boardStopId,
    required this.boardCoordId,
    required this.boardOrder,
    required this.alightStopName,
    required this.alightStopLat,
    required this.alightStopLon,
    required this.alightStopId,
    required this.alightCoordId,
    required this.alightOrder,
    required this.totalWalkingDistance,
  });

  bool get canReplay =>
      routeId > 0 && boardCoordId > 0 && alightCoordId > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ts': timestamp.toIso8601String(),
        'originLat': originLat,
        'originLon': originLon,
        'destinationLat': destinationLat,
        'destinationLon': destinationLon,
        'routeId': routeId,
        'routeName': routeName,
        'boardStopName': boardStopName,
        'boardStopLat': boardStopLat,
        'boardStopLon': boardStopLon,
        'boardStopId': boardStopId,
        'boardCoordId': boardCoordId,
        'boardOrder': boardOrder,
        'alightStopName': alightStopName,
        'alightStopLat': alightStopLat,
        'alightStopLon': alightStopLon,
        'alightStopId': alightStopId,
        'alightCoordId': alightCoordId,
        'alightOrder': alightOrder,
        'totalWalkingDistance': totalWalkingDistance,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['ts'] as String),
      originLat: (json['originLat'] as num).toDouble(),
      originLon: (json['originLon'] as num).toDouble(),
      destinationLat: (json['destinationLat'] as num).toDouble(),
      destinationLon: (json['destinationLon'] as num).toDouble(),
      routeId: json['routeId'] as int,
      routeName: json['routeName'] as String,
      boardStopName: json['boardStopName'] as String,
      boardStopLat: (json['boardStopLat'] as num).toDouble(),
      boardStopLon: (json['boardStopLon'] as num).toDouble(),
      boardStopId: json['boardStopId'] as int?,
      boardCoordId: json['boardCoordId'] as int,
      boardOrder: json['boardOrder'] as int,
      alightStopName: json['alightStopName'] as String,
      alightStopLat: (json['alightStopLat'] as num).toDouble(),
      alightStopLon: (json['alightStopLon'] as num).toDouble(),
      alightStopId: json['alightStopId'] as int?,
      alightCoordId: json['alightCoordId'] as int,
      alightOrder: json['alightOrder'] as int,
      totalWalkingDistance: (json['totalWalkingDistance'] as num).toDouble(),
    );
  }
}

