import 'package:flutter/services.dart';
import '../models/financial_event.dart';
import '../models/sms_message_model.dart';
import 'sms_filter_service.dart';
import 'sms_parser_service.dart';

class SmsReaderService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.creditflow/sms',
  );

  /// Check if SMS permission is granted
  Future<bool> hasSmsPermission() async {
    try {
      final bool result = await _channel.invokeMethod('hasSmsPermission');
      return result;
    } on PlatformException catch (e) {
      print('Error checking SMS permission: ${e.message}');
      return false;
    }
  }

  /// Request SMS permission
  Future<bool> requestSmsPermission() async {
    try {
      final bool result = await _channel.invokeMethod('requestSmsPermission');
      return result;
    } on PlatformException catch (e) {
      print('Error requesting SMS permission: ${e.message}');
      return false;
    }
  }

  /// Get event summary from SMS messages
  Future<Map<String, dynamic>> getEventSummary({int months = 6}) async {
    try {
      // Get all SMS messages
      final List<dynamic>? smsList = await _channel.invokeMethod('getAllSms');

      if (smsList == null || smsList.isEmpty) {
        return _emptySummary();
      }

      // Convert to SmsMessageModel and filter for financial SMS
      List<FinancialEvent> events = [];
      double totalCredits = 0.0;
      double totalDebits = 0.0;
      int salaryCount = 0;

      for (final sms in smsList) {
        final sender = sms['address'] as String? ?? '';
        final body = sms['body'] as String? ?? '';
        final dateMillis = sms['date'] as int? ?? 0;

        // Skip if sender or body is empty
        if (sender.isEmpty || body.isEmpty) continue;

        // Convert timestamp to DateTime
        final date = DateTime.fromMillisecondsSinceEpoch(dateMillis);

        // Filter for financial SMS
        if (!SmsFilterService.isFinancialSms(sender, body)) continue;

        // Parse into FinancialEvent
        final event = SmsParserService.parseSms(
          sender: sender,
          body: body,
          date: date,
        );

        // Skip OTP-only messages
        if (event.eventType == 'OTP_ONLY') continue;

        events.add(event);

        // Calculate totals
        if (event.amount != null) {
          if (event.eventType.contains('CREDIT') ||
              event.eventType.contains('SALARY')) {
            totalCredits += event.amount!;
            if (event.eventType == 'SALARY_CREDIT') {
              salaryCount++;
            }
          } else if (event.eventType.contains('DEBIT') ||
              event.eventType.contains('EMI') ||
              event.eventType.contains('CARD')) {
            totalDebits += event.amount!;
          }
        }
      }

      // Sort events by date (newest first)
      events.sort((a, b) => b.date.compareTo(a.date));

      return {
        'totalCredits': totalCredits,
        'totalDebits': totalDebits,
        'salaryCount': salaryCount,
        'events': events,
      };
    } on PlatformException catch (e) {
      print('Error getting SMS: ${e.message}');
      return _emptySummary();
    }
  }

  /// Get all financial SMS messages
  Future<List<SmsMessageModel>> getFinancialSms({int months = 6}) async {
    try {
      final List<dynamic>? smsList = await _channel.invokeMethod('getAllSms');

      if (smsList == null || smsList.isEmpty) {
        return [];
      }

      List<SmsMessageModel> financialSms = [];

      for (final sms in smsList) {
        final sender = sms['address'] as String? ?? '';
        final body = sms['body'] as String? ?? '';
        final dateMillis = sms['date'] as int? ?? 0;

        if (sender.isEmpty || body.isEmpty) continue;

        final date = DateTime.fromMillisecondsSinceEpoch(dateMillis);

        if (SmsFilterService.isFinancialSms(sender, body)) {
          financialSms.add(
            SmsMessageModel(sender: sender, body: body, date: date),
          );
        }
      }

      return financialSms;
    } on PlatformException catch (e) {
      print('Error getting financial SMS: ${e.message}');
      return [];
    }
  }

  /// Parse SMS into FinancialEvent
  FinancialEvent parseSms(SmsMessageModel sms) {
    return SmsParserService.parseSms(
      sender: sms.sender,
      body: sms.body,
      date: sms.date,
    );
  }

  Map<String, dynamic> _emptySummary() {
    return {
      'totalCredits': 0.0,
      'totalDebits': 0.0,
      'salaryCount': 0,
      'events': <FinancialEvent>[],
    };
  }
}
