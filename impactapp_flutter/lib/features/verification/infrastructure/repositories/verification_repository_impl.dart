import '../../domain/entities/support_entity.dart';
import '../../domain/repositories/verification_repository.dart';
import '../datasources/verification_remote_datasource.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  final VerificationRemoteDataSource dataSource;
  VerificationRepositoryImpl(this.dataSource);

  @override
  Future<SupportEntity> uploadSupport({
    required int idCampania,
    required String tipo,
    String? descripcion,
    String? filePath,
    String? url,
  }) {
    return dataSource.uploadSupport(
      idCampania: idCampania,
      tipo: tipo,
      descripcion: descripcion,
      filePath: filePath,
      url: url,
    );
  }
}

