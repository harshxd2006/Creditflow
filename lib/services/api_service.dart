import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/financial_event.dart';

class ApiService {
  // Demo API endpoint - using JSONPlaceholder as a mock API
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';

  /// Send a single financial event to the demo API
  Future<ApiResponse> sendFinancialEvent(FinancialEvent event) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/posts'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'title': 'Financial Event: ${event.eventType}',
          'body': event.rawSms,
          'userId': 1,
          'metadata': event.toMap(),
        }),
      );

      if (response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: 'Event sent successfully',
          data: jsonDecode(response.body),
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to send event: ${response.statusCode}',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error sending event: $e',
        data: null,
      );
    }
  }

  /// Send multiple financial events to the demo API
  Future<ApiResponse> sendMultipleEvents(List<FinancialEvent> events) async {
    try {
      // Convert events to a list of maps using explicit map type
      final eventsData = events.map((e) {
        return <String, dynamic>{
          'title': 'Financial Event: ${e.eventType}',
          'body': e.rawSms,
          'userId': 1,
          'metadata': e.toMap(),
        };
      }).toList();

      // Send each event individually to the demo API
      final responses = <dynamic>[];
      var successCount = 0;

      for (final event in eventsData) {
        final response = await http.post(
          Uri.parse('$_baseUrl/posts'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(event),
        );

        if (response.statusCode == 201) {
          successCount++;
          responses.add(jsonDecode(response.body));
        }
      }

      return ApiResponse(
        success: successCount > 0,
        message: 'Sent $successCount out of ${events.length} events',
        data: responses,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error sending events: $e',
        data: null,
      );
    }
  }

  /// Send raw SMS text to the demo API
  Future<ApiResponse> sendSmsText({
    required String sender,
    required String body,
    required DateTime date,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/posts'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'title': 'SMS from $sender',
          'body': body,
          'userId': 1,
          'metadata': {'sender': sender, 'date': date.toIso8601String()},
        }),
      );

      if (response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: 'SMS sent successfully',
          data: jsonDecode(response.body),
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to send SMS: ${response.statusCode}',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error sending SMS: $e',
        data: null,
      );
    }
  }

  /// Test the API connection
  Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/posts/1'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Response model for API calls
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({required this.success, required this.message, this.data});
}
