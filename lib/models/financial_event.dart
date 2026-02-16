class FinancialEvent {
  final String eventType;
  final double? amount;
  final DateTime date;
  final String? accountId; // last 4 digits
  final String? channel; // UPI, ATM, card, etc.
  final String? counterparty; // merchant/person name
  final double? balanceAfter;
  final DateTime? dueDate;
  final bool? isMinimumDue;
  final String? billerName;
  final String rawSms;
  final String sender;

  FinancialEvent({
    required this.eventType,
    this.amount,
    required this.date,
    this.accountId,
    this.channel,
    this.counterparty,
    this.balanceAfter,
    this.dueDate,
    this.isMinimumDue,
    this.billerName,
    required this.rawSms,
    required this.sender,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventType': eventType,
      'amount': amount,
      'date': date.toIso8601String(),
      'accountId': accountId,
      'channel': channel,
      'counterparty': counterparty,
      'balanceAfter': balanceAfter,
      'dueDate': dueDate?.toIso8601String(),
      'isMinimumDue': isMinimumDue,
      'billerName': billerName,
    };
  }

  @override
  String toString() {
    return 'FinancialEvent($eventType, ₹$amount, $date)';
  }
}
