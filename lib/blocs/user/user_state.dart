import 'package:equatable/equatable.dart';
import '../../models/local_user.dart';
import '../../models/history_entry.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserNeedsRegistration extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final LocalUser user;
  final List<int> favoritos;
  final List<HistoryEntry> historial;

  const UserLoaded({
    required this.user,
    this.favoritos = const [],
    this.historial = const [],
  });

  UserLoaded copyWith({
    LocalUser? user,
    List<int>? favoritos,
    List<HistoryEntry>? historial,
  }) {
    return UserLoaded(
      user: user ?? this.user,
      favoritos: favoritos ?? this.favoritos,
      historial: historial ?? this.historial,
    );
  }

  @override
  List<Object?> get props => [user, favoritos, historial];
}
