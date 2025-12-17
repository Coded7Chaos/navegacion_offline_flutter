import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/local_user.dart';
import '../../models/history_entry.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  static const _userKey = 'rutikal_usuario';
  static const _favoritesKey = 'rutikal_favoritos';
  static const _historyKey = 'rutikal_historial';

  final SharedPreferences prefs;

  UserBloc(this.prefs) : super(UserInitial()) {
    on<UserCheckRequested>(_onCheck);
    on<UserRegistered>(_onRegister);
    on<UserUpdated>(_onUpdate);
    on<FavoriteToggled>(_onFavoriteToggled);
    on<HistoryAdded>(_onHistoryAdded);
    on<HistoryRouteSearchSaved>(_onHistoryRouteSearchSaved);
  }

  List<HistoryEntry> _readHistory() {
    final raw = prefs.getStringList(_historyKey) ?? const [];
    final entries = <HistoryEntry>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          entries.add(HistoryEntry.fromJson(decoded));
        }
      } catch (_) {
        // Legacy string entries are ignored (they can't be replayed).
      }
    }
    return entries;
  }

  Future<void> _onCheck(UserCheckRequested event, Emitter<UserState> emit) async {
    emit(UserLoading());
    final savedUser = prefs.getString(_userKey);
    if (savedUser == null) {
      emit(UserNeedsRegistration());
      return;
    }
    final user = LocalUser.fromJson(jsonDecode(savedUser));
    emit(UserLoaded(
      user: user,
      favoritos: prefs.getStringList(_favoritesKey)?.map(int.parse).toList() ?? [],
      historial: _readHistory(),
    ));
  }

  Future<void> _onRegister(UserRegistered event, Emitter<UserState> emit) async {
    emit(UserLoading());
    await prefs.setString(_userKey, jsonEncode(event.user.toJson()));
    emit(UserLoaded(
      user: event.user,
      favoritos: const [],
      historial: const <HistoryEntry>[],
    ));
  }

  Future<void> _onUpdate(UserUpdated event, Emitter<UserState> emit) async {
    if (state is! UserLoaded) return;
    await prefs.setString(_userKey, jsonEncode(event.user.toJson()));
    final current = state as UserLoaded;
    emit(current.copyWith(user: event.user));
  }

  Future<void> _onFavoriteToggled(FavoriteToggled event, Emitter<UserState> emit) async {
    if (state is! UserLoaded) return;
    final current = state as UserLoaded;
    final favs = List<int>.from(current.favoritos);
    if (favs.contains(event.rutaId)) {
      favs.remove(event.rutaId);
    } else {
      favs.add(event.rutaId);
    }
    await prefs.setStringList(_favoritesKey, favs.map((e) => e.toString()).toList());
    emit(current.copyWith(favoritos: favs));
  }

  Future<void> _onHistoryAdded(HistoryAdded event, Emitter<UserState> emit) async {
    if (state is! UserLoaded) return;
    final current = state as UserLoaded;
    // Legacy event kept for compatibility; it doesn't have enough data to replay.
    // No-op to avoid polluting history with non-replayable strings.
    emit(current.copyWith(historial: current.historial));
  }

  Future<void> _onHistoryRouteSearchSaved(
      HistoryRouteSearchSaved event, Emitter<UserState> emit) async {
    if (state is! UserLoaded) return;
    final current = state as UserLoaded;
    final decoded = jsonDecode(event.payloadJson) as Map<String, dynamic>;
    final entry = HistoryEntry.fromJson(decoded);

    final next = [entry, ...current.historial].take(50).toList();
    await prefs.setStringList(
      _historyKey,
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
    emit(current.copyWith(historial: next));
  }
}
