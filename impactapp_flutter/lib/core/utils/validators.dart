import 'dart:convert';

class Validators {
  static String? requiredField(String? value, String label, {int? maxLength}) {
    if (value == null || value.trim().isEmpty) return '$label es obligatorio';
    if (maxLength != null && value.trim().length > maxLength) {
      return '$label no puede superar $maxLength caracteres';
    }
    return null;
  }

  static String? optionalText(String? value, String label, int maxLength) {
    if (value != null && value.trim().length > maxLength) {
      return '$label no puede superar $maxLength caracteres';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Correo es obligatorio';
    final normalized = value.trim();
    if (normalized.length > 150) return 'Correo no puede superar 150 caracteres';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(normalized)) return 'Correo inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 8) {
      return 'Contraseña mínima de 8 caracteres';
    }
    if (utf8.encode(value).length > 72) {
      return 'Contraseña no puede superar 72 bytes';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe incluir al menos una mayúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe incluir al menos un número';
    }
    return null;
  }
}
