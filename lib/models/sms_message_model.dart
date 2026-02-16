class SmsMessageModel {
  final String sender;
  final String body;
  final DateTime date;
  final String? eventType;
  final Map<String, dynamic>? extractedData;

  SmsMessageModel({
    required this.sender,
    required this.body,
    required this.date,
    this.eventType,
    this.extractedData,
  });

  @override
  String toString() {
    return 'SmsMessageModel(sender: $sender, date: $date, eventType: $eventType)';
  }
}
