class UserEntity {
  final int idUsuario;
  final String nombre;
  final String apellido;
  final String correo;
  final String? telefono;
  final String estado;

  const UserEntity({
    required this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.telefono,
    required this.estado,
  });
}

