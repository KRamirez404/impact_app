import '../entities/support_entity.dart';
import '../repositories/verification_repository.dart';

class UploadSupportUseCase {
  final VerificationRepository repository;
  UploadSupportUseCase(this.repository);

  Future<SupportEntity> call({
    required int idCampania,
    required String tipo,
    String? descripcion,
    String? filePath,
    String? url,
  }) {
    return repository.uploadSupport(
      idCampania: idCampania,
      tipo: tipo,
      descripcion: descripcion,
      filePath: filePath,
      url: url,
    );
  }
}

