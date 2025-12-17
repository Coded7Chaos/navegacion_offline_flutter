import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/data_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DataRepository repository;

  HomeBloc({required this.repository}) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      final rutas = await repository.loadRutas();
      emit(state.copyWith(
        loading: false,
        rutas: rutas,
        ads: const [
          AdItem(
            id: 'a1',
            titulo: 'Transporte Seguro y Eficiente',
            descripcion: 'Pumakatari al servicio de La Paz',
            imagen:
                'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&h=400&fit=crop',
          ),
          AdItem(
            id: 'a2',
            titulo: 'Nuevas Rutas 2024',
            descripcion: 'Conectando toda la ciudad',
            imagen:
                'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=800&h=400&fit=crop',
          ),
          AdItem(
            id: 'a3',
            titulo: 'Tarifa Social',
            descripcion: 'Bs. 1.40 por viaje',
            imagen:
                'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&h=400&fit=crop',
          ),
        ],
      ));
    } catch (e) {
      emit(state.copyWith(
          loading: false, error: 'No se pudieron cargar las rutas'));
    }
  }
}
