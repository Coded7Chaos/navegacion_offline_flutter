import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/alerta.dart';
import '../../repositories/data_repository.dart';
import 'alerts_event.dart';
import 'alerts_state.dart';

class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  final DataRepository repository;

  AlertsBloc({required this.repository}) : super(const AlertsState()) {
    on<AlertsStarted>(_onStarted);
    on<AlertSelected>(_onSelected);
  }

  Future<void> _onStarted(AlertsStarted event, Emitter<AlertsState> emit) async {
    try {
      final notificaciones = await repository.fetchNotificaciones();
      if (notificaciones.isEmpty) {
        throw Exception("No se pudieron cargar las notificaciones");
      }
      final List<Alerta> alertas = [];

      for (var n in notificaciones) {
        final rutaNombre = await repository.getRouteName(n.rutaAfectada);
        final List<String> paradasNombres = [];
        for (var pId in n.paradasAfectadas) {
          paradasNombres.add(await repository.getStopName(pId));
        }

        final List<String> alternativas = [];
        if (n.rutaAuxiliar > 0) {
          final rutaAuxNombre = await repository.getRouteName(n.rutaAuxiliar);
          alternativas.add("Ruta Auxiliar: $rutaAuxNombre");
        }

        final fechaStr = "${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}";

        alertas.add(Alerta(
          id: n.id.toString(),
          rutaNombre: rutaNombre,
          descripcionCorta: n.informacion, 
          descripcionCompleta: n.informacion,
          paradasAfectadas: paradasNombres,
          paradasAlternativas: alternativas, 
          motivo: n.informacion,
          fecha: fechaStr,
        ));
      }
      emit(state.copyWith(alertas: alertas, errorMessage: null));
    } catch (e) {
      print("Error loading alerts: $e");
      emit(state.copyWith(errorMessage: "No hay conexión a internet. No se pueden actualizar las notificaciones."));
    }
  }

  void _onSelected(AlertSelected event, Emitter<AlertsState> emit) {
    final alerta = state.alertas.firstWhere((a) => a.id == event.id);
    emit(state.copyWith(seleccionada: alerta));
  }
}
