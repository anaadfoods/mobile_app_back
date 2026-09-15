import '../repositories/orders_repository.dart';

class DownloadInvoiceUseCase {
  final OrdersRepository _repository;

  DownloadInvoiceUseCase(this._repository);

  Future<String> call(String orderNumber) {
    return _repository.downloadInvoice(orderNumber);
  }
}
