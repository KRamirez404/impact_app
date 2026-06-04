import '../entities/support_summary_entity.dart';
import '../repositories/support_repository.dart';

class GetSupportSummaryUseCase {
  final SupportRepository repository;
  GetSupportSummaryUseCase(this.repository);

  Future<SupportSummaryEntity> call() {
    return repository.getSummary();
  }
}
