import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OfflineMapService {
  OfflineMapService._();

  static final OfflineMapService instance = OfflineMapService._();

  String? _stylePath;
  Future<String>? _preparing;

  Future<String> getStylePath() async {
    if (_stylePath != null) {
      return _stylePath!;
    }

    _preparing ??= _prepareStyle();
    _stylePath = await _preparing!;
    _preparing = null;
    return _stylePath!;
  }

  Future<String> _prepareStyle() async {
    final directory = await getApplicationDocumentsDirectory();
    final mapsDir = Directory('${directory.path}/maps');
    if (!await mapsDir.exists()) await mapsDir.create(recursive: true);

    final mbtilesPath = '${mapsDir.path}/lapaz.mbtiles';
    final mbtilesFile = File(mbtilesPath);
    if (!mbtilesFile.existsSync()) {
      final byteData = await rootBundle.load('assets/maps/lapaz.mbtiles');
      await mbtilesFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    }

    final styleString = await rootBundle.loadString('assets/maps/style.json');
    final finalStyle = styleString.replaceFirst('{path_to_mbtiles}', mbtilesPath);
    final styleFile = File('${mapsDir.path}/style_final.json');
    await styleFile.writeAsString(finalStyle);
    return styleFile.path;
  }
}
