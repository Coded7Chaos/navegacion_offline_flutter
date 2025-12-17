import 'package:equatable/equatable.dart';
import '../../models/alerta.dart';

class AlertsState extends Equatable {
  final List<Alerta> alertas;
  final Alerta? seleccionada;
  final String? errorMessage;

  const AlertsState({this.alertas = const [], this.seleccionada, this.errorMessage});

  AlertsState copyWith({
    List<Alerta>? alertas,
    Alerta? seleccionada,
    String? errorMessage,
  }) {
    return AlertsState(
      alertas: alertas ?? this.alertas,
      seleccionada: seleccionada,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [alertas, seleccionada, errorMessage];
}
