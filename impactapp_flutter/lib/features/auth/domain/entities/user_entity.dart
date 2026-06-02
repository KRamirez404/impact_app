class UserEntity {
  final int idUsuario;
  final String nombre;
  final String apellido;
  final String correo;
  final String? telefono;
  final String? biografia;
  final String? fotoPerfil;
  final String? fechaRegistro;
  final String rol;
  final String estado;

  const UserEntity({
    required this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.telefono,
    this.biografia,
    this.fotoPerfil,
    this.fechaRegistro,
    required this.rol,
    required this.estado,
  });
}
