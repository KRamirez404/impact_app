class Validators {
  static String? requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label es obligatorio';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Correo es obligatorio';
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!regex.hasMatch(value)) return 'Correo inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) {
      return 'Contraseña mínima de 6 caracteres';
    }
    return null;
  }
}

