import 'package:equatable/equatable.dart';
import '../../models/ruta.dart';

class AdItem {
  final String id;
  final String titulo;
  final String descripcion;
  final String imagen;

  const AdItem({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagen,
  });
}

class HomeState extends Equatable {
  final bool loading;
  final List<Ruta> rutas;
  final List<AdItem> ads;
  final String? error;

  const HomeState({
    this.loading = false,
    this.rutas = const [],
    this.ads = const [],
    this.error,
  });

  HomeState copyWith({
    bool? loading,
    List<Ruta>? rutas,
    List<AdItem>? ads,
    String? error,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      rutas: rutas ?? this.rutas,
      ads: ads ?? this.ads,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, rutas, ads, error];
}
