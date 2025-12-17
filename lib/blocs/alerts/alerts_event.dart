import 'package:equatable/equatable.dart';

abstract class AlertsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AlertsStarted extends AlertsEvent {}

class AlertSelected extends AlertsEvent {
  final String id;
  AlertSelected(this.id);

  @override
  List<Object?> get props => [id];
}
