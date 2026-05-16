import '../entities/support_entity.dart';

abstract class VerificationRepository {
  Future<SupportEntity> uploadSupport({
    required int idCampania,
    required String tipo,
    String? descripcion,
    String? filePath,
    String? url,
  });
}

