import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.idUsuario,
    required super.nombre,
    required super.apellido,
    required super.correo,
    super.telefono,
    super.biografia,
    super.fechaRegistro,
    required super.rol,
    required super.estado,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUsuario: json['id_usuario'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      correo: json['correo'] ?? '',
      telefono: json['telefono'],
      biografia: json['biografia'],
      fechaRegistro: json['fecha_registro'],
      rol: json['rol'] ?? 'usuario',
      estado: json['estado'] ?? 'activo',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_usuario': idUsuario,
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'telefono': telefono,
        'biografia': biografia,
        'fecha_registro': fechaRegistro,
        'rol': rol,
        'estado': estado,
      };
}
