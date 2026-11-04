import '../entities/bank_account_entity.dart';
import '../repositories/transfer_repository.dart';

class GetBankAccountUseCase {
  final TransferRepository repository;
  const GetBankAccountUseCase(this.repository);
  Future<BankAccountEntity> call(int campaignId) =>
      repository.getBankAccount(campaignId);
}
