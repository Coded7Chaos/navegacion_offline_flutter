import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/alerta.dart';
import 'alerts_event.dart';
import 'alerts_state.dart';

class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  AlertsBloc() : super(const AlertsState()) {
    on<AlertsStarted>(_onStarted);
    on<AlertSelected>(_onSelected);
  }

  void _onStarted(AlertsStarted event, Emitter<AlertsState> emit) {
    emit(state.copyWith(alertas: _mockData()));
  }

  void _onSelected(AlertSelected event, Emitter<AlertsState> emit) {
    final alerta = state.alertas.firstWhere((a) => a.id == event.id);
    emit(state.copyWith(seleccionada: alerta));
  }

  List<Alerta> _mockData() => const [
        Alerta(
          id: 'n1',
          rutaNombre: 'Línea 1 - Roja',
          descripcionCorta:
              'Desvío temporal por mantenimiento vial en la zona de Sopocachi',
          descripcionCompleta:
              'Se informa a los usuarios que la Línea 1 estará realizando un desvío temporal debido a trabajos de mantenimiento en la Av. Ecuador.',
          paradasAfectadas: ['Sopocachi', 'Plaza España'],
          paradasAlternativas: ['San Francisco', 'Plaza Murillo'],
          motivo:
              'Trabajos de mantenimiento vial programados por el Gobierno Autónomo Municipal de La Paz. Se estima una duración de 5 días hábiles.',
          fecha: '15/12/2024',
        ),
        Alerta(
          id: 'n2',
          rutaNombre: 'Línea 2 - Azul',
          descripcionCorta: 'Nuevo horario extendido hasta las 23:00 hrs',
          descripcionCompleta:
              'A partir del 20 de diciembre, la Línea 2 extenderá su horario de servicio.',
          paradasAfectadas: [],
          paradasAlternativas: [],
          motivo:
              'Para mejorar el servicio a la ciudadanía, especialmente en horarios nocturnos, se ha decidido extender el horario de operación de esta línea.',
          fecha: '17/12/2024',
        ),
        Alerta(
          id: 'n3',
          rutaNombre: 'Línea 3 - Verde',
          descripcionCorta: 'Incremento de unidades en horario pico',
          descripcionCompleta:
              'Se incrementará la frecuencia de buses en horarios pico (7:00-9:00 y 17:00-19:00).',
          paradasAfectadas: [],
          paradasAlternativas: [],
          motivo:
              'Debido a la alta demanda de pasajeros en horarios pico, se han asignado 10 unidades adicionales para mejorar la calidad del servicio.',
          fecha: '16/12/2024',
        ),
      ];
}
