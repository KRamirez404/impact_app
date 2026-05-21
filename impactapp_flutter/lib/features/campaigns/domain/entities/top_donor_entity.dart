class TopDonorEntity {
  final int idUsuario;
  final String nombre;
  final String apellido;
  final double totalDonado;
  final int donacionesCount;

  const TopDonorEntity({
    required this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.totalDonado,
    required this.donacionesCount,
  });

  String get nombreCompleto {
    final full = '$nombre $apellido'.trim();
    return full.isEmpty ? 'Donador' : full;
  }
}
