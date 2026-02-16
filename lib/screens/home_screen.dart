import 'package:flutter/material.dart';
import '../services/sms_reader_service.dart';
import '../models/financial_event.dart';
import 'sms_detail_screen.dart';
import 'demo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SmsReaderService _smsService = SmsReaderService();

  bool _isLoading = false;
  bool _hasScanned = false;

  List<FinancialEvent> _events = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    await _smsService.hasSmsPermission();
  }

  Future<void> _scanSms() async {
    setState(() {
      _isLoading = true;
    });

    final granted = await _smsService.requestSmsPermission();
    if (!granted) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SMS permission is required to scan messages. Please grant permission in Settings.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      final summary = await _smsService.getEventSummary(months: 6);

      setState(() {
        _summary = summary;
        _events = (summary['events'] as List<FinancialEvent>?) ?? [];
        _hasScanned = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getEventColor(String eventType) {
    if (eventType.contains('CREDIT') ||
        eventType.contains('SALARY') ||
        eventType.contains('PAID')) {
      return Colors.green;
    }
    if (eventType.contains('BOUNCED') ||
        eventType.contains('FAILED') ||
        eventType.contains('LOW')) {
      return Colors.red;
    }
    if (eventType.contains('DUE') || eventType.contains('FEE')) {
      return Colors.orange;
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text(
          'CreditFlow',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A0E21),
        foregroundColor: Colors.white,
        actions: [
          if (_hasScanned)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _scanSms,
            ),
          IconButton(
            icon: const Icon(Icons.api),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DemoScreen()),
            ),
            tooltip: 'Demo API Route',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.tealAccent.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield, color: Colors.tealAccent, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'We read only financial SMS. Personal chats are ignored.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Scan Button or Summary
          if (!_hasScanned)
            Expanded(
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _scanSms,
                  icon: const Icon(Icons.search),
                  label: const Text('Scan SMS (Last 6 Months)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),

          if (_isLoading && !_hasScanned)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.tealAccent),
            ),

          if (_hasScanned && !_isLoading) ...[
            // Summary Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _summaryCard(
                    'Credits',
                    '₹${(_summary['totalCredits'] ?? 0).toStringAsFixed(0)}',
                    Colors.green,
                  ),
                  _summaryCard(
                    'Debits',
                    '₹${(_summary['totalDebits'] ?? 0).toStringAsFixed(0)}',
                    Colors.red,
                  ),
                  _summaryCard(
                    'Salary',
                    '${_summary['salaryCount'] ?? 0}',
                    Colors.amber,
                  ),
                  _summaryCard('Events', '${_events.length}', Colors.teal),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // List
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transactions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Card(
                    color: const Color(0xFF1D1E33),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.message,
                        color: _getEventColor(event.eventType),
                      ),
                      title: Text(
                        event.eventType.replaceAll('_', ' '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        event.sender,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: event.amount != null
                          ? Text(
                              '₹${event.amount!.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: _getEventColor(event.eventType),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SmsDetailScreen(event: event),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
