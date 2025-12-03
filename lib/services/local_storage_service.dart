import 'package:app_navegacion_offline/models/favorite_route.dart';
import 'package:app_navegacion_offline/models/user_profile.dart';
import 'package:flutter/services.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();
  static const MethodChannel _channel = MethodChannel('com.example.app_navegacion_offline/db');

  Future<List<FavoriteRoute>> getFavoriteRoutes() async {
    final response = await _channel.invokeMethod<List<dynamic>>('getFavorites');
    if (response == null) return const <FavoriteRoute>[];
    return response
        .map((data) {
          final map = Map<dynamic, dynamic>.from(data as Map);
          return FavoriteRoute.fromMap(map);
        })
        .toList();
  }

  Future<UserProfile?> getUserProfile() async {
    final response = await _channel.invokeMethod<Map<dynamic, dynamic>?>('getUserProfile');
    if (response == null) return null;
    return UserProfile.fromMap(response);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _channel.invokeMethod('saveUserProfile', profile.toMap());
  }
}
