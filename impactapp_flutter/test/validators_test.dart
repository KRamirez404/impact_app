import 'package:flutter_test/flutter_test.dart';
import 'package:impactapp_flutter/core/utils/validators.dart';

void main() {
  group('Validators.requiredField', () {
    test('rechaza vacío y espacios', () {
      expect(Validators.requiredField(null, 'Nombre'), 'Nombre es obligatorio');
      expect(Validators.requiredField('', 'Nombre'), 'Nombre es obligatorio');
      expect(Validators.requiredField('   ', 'Nombre'), 'Nombre es obligatorio');
    });

    test('acepta texto', () {
      expect(Validators.requiredField('Ana', 'Nombre'), isNull);
    });
  });

  group('Validators.email', () {
    test('rechaza formatos inválidos', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('correo-invalido'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });

    test('acepta correos válidos', () {
      expect(Validators.email('ana@impactapp.co'), isNull);
      expect(Validators.email('a.b+tag@dominio.com.co'), isNull);
    });
  });

  group('Validators.password', () {
    test('exige mínimo 8 caracteres', () {
      expect(Validators.password('Aa1'), isNotNull);
      expect(Validators.password('Aaaa1'), isNotNull);
    });

    test('exige al menos una mayúscula', () {
      expect(Validators.password('contrasena1'), isNotNull);
    });

    test('exige al menos un número', () {
      expect(Validators.password('Contrasena'), isNotNull);
    });

    test('acepta contraseña fuerte', () {
      expect(Validators.password('Passw0rd!'), isNull);
    });
  });
}
