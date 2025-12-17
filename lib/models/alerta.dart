class Alerta {
  final String id;
  final String rutaNombre;
  final String descripcionCorta;
  final String descripcionCompleta;
  final List<String> paradasAfectadas;
  final List<String> paradasAlternativas;
  final String motivo;
  final String fecha;

  const Alerta({
    required this.id,
    required this.rutaNombre,
    required this.descripcionCorta,
    required this.descripcionCompleta,
    required this.paradasAfectadas,
    required this.paradasAlternativas,
    required this.motivo,
    required this.fecha,
  });
}
