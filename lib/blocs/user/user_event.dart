import 'package:equatable/equatable.dart';
import '../../models/local_user.dart';

abstract class UserEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserCheckRequested extends UserEvent {}

class UserRegistered extends UserEvent {
  final LocalUser user;
  UserRegistered(this.user);

  @override
  List<Object?> get props => [user];
}

class UserUpdated extends UserEvent {
  final LocalUser user;
  UserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class FavoriteToggled extends UserEvent {
  final int rutaId;
  FavoriteToggled(this.rutaId);

  @override
  List<Object?> get props => [rutaId];
}

class HistoryAdded extends UserEvent {
  final String descripcion;
  HistoryAdded(this.descripcion);

  @override
  List<Object?> get props => [descripcion];
}
