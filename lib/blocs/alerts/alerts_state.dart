import 'package:equatable/equatable.dart';
import '../../models/alerta.dart';

class AlertsState extends Equatable {
  final List<Alerta> alertas;
  final Alerta? seleccionada;

  const AlertsState({this.alertas = const [], this.seleccionada});

  AlertsState copyWith({
    List<Alerta>? alertas,
    Alerta? seleccionada,
  }) {
    return AlertsState(
      alertas: alertas ?? this.alertas,
      seleccionada: seleccionada,
    );
  }

  @override
  List<Object?> get props => [alertas, seleccionada];
}
