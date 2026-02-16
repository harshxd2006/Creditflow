import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/sms_reader_service.dart';
import '../models/financial_event.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final ApiService _apiService = ApiService();
  final SmsReaderService _smsService = SmsReaderService();

  bool _isLoading = false;
  String _responseMessage = '';
  bool _isSuccess = false;
  List<FinancialEvent>? _events;

  // Detailed tracking variables
  List<String> _debugLogs = []; // Store debug logs for each step
  dynamic _lastApiResponse; // Store last API response for display
  List<SmsMessageModel>? _scannedSms; // Store scanned SMS for display

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _responseMessage = 'Testing API connection...';
    });

    final isConnected = await _apiService.testConnection();

    setState(() {
      _isLoading = false;
      _isSuccess = isConnected;
      _responseMessage = isConnected
          ? '✅ API Connection Successful!'
          : '❌ API Connection Failed!';
    });
  }

  Future<void> _sendSampleSms() async {
    setState(() {
      _isLoading = true;
      _responseMessage = 'Sending sample SMS to demo API...';
    });

    // Sample SMS data
    final response = await _apiService.sendSmsText(
      sender: 'HDFCBANK',
      body:
          'Your a/c ****1234 is credited with INR 50,000.00 on 15-01-2024. Avl balance: INR 1,50,000.00',
      date: DateTime.now(),
    );

    setState(() {
      _isLoading = false;
      _isSuccess = response.success;
      _responseMessage = response.message;
    });
  }

  Future<void> _sendScannedEvents() async {
    if (_events == null || _events!.isEmpty) {
      setState(() {
        _responseMessage = 'No events to send. Please scan SMS first.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _responseMessage = 'Sending ${_events!.length} events to demo API...';
    });

    final response = await _apiService.sendMultipleEvents(_events!);

    setState(() {
      _isLoading = false;
      _isSuccess = response.success;
      _responseMessage = response.message;
    });
  }

  Future<void> _scanAndSend() async {
    setState(() {
      _isLoading = true;
      _responseMessage = 'Scanning SMS...';
    });

    try {
      // Request permission
      final granted = await _smsService.requestSmsPermission();
      if (!granted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _responseMessage = 'SMS permission required';
        });
        return;
      }

      // Get events
      final summary = await _smsService.getEventSummary(months: 6);
      final events = (summary['events'] as List<FinancialEvent>?) ?? [];

      setState(() {
        _events = events;
        _isLoading = false;
        _responseMessage =
            'Found ${events.length} financial events. Tap "Send Events to API" to send them.';
        _isSuccess = events.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _responseMessage = 'Error scanning SMS: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text(
          'Demo API Route',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A0E21),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.tealAccent.withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.api, color: Colors.tealAccent),
                      SizedBox(width: 8),
                      Text(
                        'Demo API Endpoint',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'https://jsonplaceholder.typicode.com/posts',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Connection Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSuccess
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSuccess
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle : Icons.error,
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _responseMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            const Text(
              'Test Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Test Connection Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: const Icon(Icons.wifi),
              label: const Text('Test Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Send Sample SMS Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendSampleSms,
              icon: const Icon(Icons.send),
              label: const Text('Send Sample SMS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Scan and Send Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _scanAndSend,
              icon: const Icon(Icons.search),
              label: const Text('Scan & Prepare SMS Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Send Scanned Events Button
            ElevatedButton.icon(
              onPressed: (_events != null && _events!.isNotEmpty && !_isLoading)
                  ? _sendScannedEvents
                  : null,
              icon: const Icon(Icons.upload),
              label: const Text('Send Scanned Events to API'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const Spacer(),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
