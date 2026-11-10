import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.idUsuario,
    required super.nombre,
    required super.apellido,
    required super.correo,
    super.telefono,
    super.idCiudad,
    super.ciudadNombre,
    super.biografia,
    super.fotoPerfil,
    super.instagramUrl,
    super.facebookUrl,
    super.tiktokUrl,
    super.redesSociales,
    super.mostrarFotoTop,
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
      idCiudad: json['id_ciudad'],
      ciudadNombre: json['ciudad']?['nombre'],
      biografia: json['biografia'],
      fotoPerfil: json['foto_perfil'],
      instagramUrl: json['instagram_url'],
      facebookUrl: json['facebook_url'],
      tiktokUrl: json['tiktok_url'],
      redesSociales: Map<String, dynamic>.from(
        json['redes_sociales'] ?? const {},
      ),
      mostrarFotoTop: json['mostrar_foto_top'] ?? true,
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
    'id_ciudad': idCiudad,
    'ciudad': idCiudad == null
        ? null
        : {'id_ciudad': idCiudad, 'nombre': ciudadNombre},
    'biografia': biografia,
    'foto_perfil': fotoPerfil,
    'instagram_url': instagramUrl,
    'facebook_url': facebookUrl,
    'tiktok_url': tiktokUrl,
    'redes_sociales': redesSociales,
    'mostrar_foto_top': mostrarFotoTop,
    'fecha_registro': fechaRegistro,
    'rol': rol,
    'estado': estado,
  };
}
