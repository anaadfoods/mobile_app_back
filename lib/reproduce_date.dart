import 'package:intl/intl.dart';

void main() {
  final formats = [
    'dd-MM-yyyy HH:mm',
    'dd-MM-yyyy',
    'dd/MM/yyyy HH:mm',
    'dd/MM/yyyy',
    'yyyy-MM-dd HH:mm:ss',
    'yyyy-MM-dd',
  ];

  final testDates = ['18-07-32', '18/07/32', '2032-07-18', '0032-07-18'];

  print('Testing Date Parsing logic from order_model.dart:');

  for (var dateString in testDates) {
    bool parsed = false;
    for (final format in formats) {
      try {
        final date = DateFormat(format).parse(dateString);
        print(
          "Success: Input '$dateString' matched format '$format' -> Result: $date (Year: ${date.year})",
        );
        parsed = true;
        break;
      } catch (_) {
        // Continue to next format
      }
    }

    if (!parsed) {
      try {
        final date = DateTime.parse(dateString);
        print(
          "Success: Input '$dateString' matched ISO 8601 -> Result: $date (Year: ${date.year})",
        );
      } catch (_) {
        print("Failure: Input '$dateString' could not be parsed.");
      }
    }
  }
}
