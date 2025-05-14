
class Order {
  final String id;
  final DateTime date;
  final String status;
  final double total;
  final List<String> items;

  Order({
    required this.id,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
  });
}
