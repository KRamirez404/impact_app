import '../../domain/entities/support_user_entity.dart';

class SupportUserModel extends SupportUserEntity {
  const SupportUserModel({
    required super.idUsuario,
    required super.nombre,
    required super.apellido,
    required super.correo,
    required super.rol,
    required super.estado,
  });

  factory SupportUserModel.fromJson(Map<String, dynamic> json) =>
      SupportUserModel(
        idUsuario: json['id_usuario'] as int,
        nombre: (json['nombre'] ?? '') as String,
        apellido: (json['apellido'] ?? '') as String,
        correo: (json['correo'] ?? '') as String,
        rol: (json['rol'] ?? '') as String,
        estado: (json['estado'] ?? 'activo') as String,
      );
}
