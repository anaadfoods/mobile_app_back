class PaymentStatus {
  final String status;
  final String respMessage;

  const PaymentStatus({
    required this.status,
    required this.respMessage,
  });

  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
  
  bool get isPending =>
      status.toUpperCase() == 'INITIATED' ||
      status.toUpperCase() == 'PENDING';

  bool get isFailed {
    const failed = {'FAILED', 'CANCELLED', 'ABANDONED'};
    return failed.contains(status.toUpperCase());
  }
}
