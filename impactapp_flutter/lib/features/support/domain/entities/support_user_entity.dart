class SupportUserEntity {
  final int idUsuario;
  final String nombre;
  final String apellido;
  final String correo;
  final String rol;
  final String estado;

  const SupportUserEntity({
    required this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.rol,
    required this.estado,
  });
}
