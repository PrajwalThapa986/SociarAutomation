import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AttendanceAutomatorApp());
}

class AttendanceAutomatorApp extends StatelessWidget {
  const AttendanceAutomatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Automator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AutomatorScreen(),
    );
  }
}

class AutomatorScreen extends StatefulWidget {
  const AutomatorScreen({super.key});

  @override
  State<AutomatorScreen> createState() => _AutomatorScreenState();
}

class _AutomatorScreenState extends State<AutomatorScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  DateTimeRange? _selectedDateRange;
  bool _isRunning = false;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadSavedToken();
    // Default to today for selection if needed
    final today = DateTime.now();
    _selectedDateRange = DateTimeRange(start: today, end: today);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    if (savedToken != null) {
      _tokenController.text = savedToken;
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    // Auto-scroll to the bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickDateRange() async {
    DateTime now = DateTime.now();
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _execute() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Bearer token.')),
      );
      return;
    }

    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range.')),
      );
      return;
    }

    // Save token for future use
    await _saveToken(token);

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _addLog("🚀 Starting execution...");

    DateTime current = _selectedDateRange!.start;
    DateTime end = _selectedDateRange!.end;

    // Loop through each date (inclusive)
    while (!current.isAfter(end)) {
      String dateStr = _formatDate(current);
      _addLog("⏳ [$dateStr] Processing...");

      try {
        final headers = {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        };
        final body = jsonEncode({"date": dateStr});

        // 1. Daily Update API
        final updateResponse = await http.post(
          Uri.parse('https://api.placeholder.com/daily-update'),
          headers: headers,
          body: body,
        );

        if (updateResponse.statusCode == 200 || updateResponse.statusCode == 201) {
          _addLog("✅ [$dateStr] Update successful (${updateResponse.statusCode})");
        } else {
          _addLog("❌ [$dateStr] Update failed: ${updateResponse.statusCode} ${updateResponse.reasonPhrase}");
        }

        // 2. Attendance API
        final attendanceResponse = await http.post(
          Uri.parse('https://api.placeholder.com/attendance'),
          headers: headers,
          body: body,
        );

        if (attendanceResponse.statusCode == 200 || attendanceResponse.statusCode == 201) {
          _addLog("✅ [$dateStr] Attendance successful (${attendanceResponse.statusCode})");
        } else {
          _addLog("❌ [$dateStr] Attendance failed: ${attendanceResponse.statusCode} ${attendanceResponse.reasonPhrase}");
        }
      } catch (e) {
        _addLog("❌ [$dateStr] Network/Unexpected error: $e");
      }

      // Crucial delay to prevent rate-limiting
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Increment day
      current = current.add(const Duration(days: 1));
    }

    _addLog("🏁 Execution completed.");
    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String dateRangeText = "No date range selected";
    if (_selectedDateRange != null) {
      if (_selectedDateRange!.start.isAtSameMomentAs(_selectedDateRange!.end)) {
        dateRangeText = _formatDate(_selectedDateRange!.start);
      } else {
        dateRangeText = "${_formatDate(_selectedDateRange!.start)} to ${_formatDate(_selectedDateRange!.end)}";
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Automator'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Token Input
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Bearer Token',
                hintText: 'ey...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              obscureText: true, // Typically tokens are hidden
              enabled: !_isRunning,
            ),
            const SizedBox(height: 24),

            // Date Selection
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Date Range:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateRangeText,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isRunning ? null : _pickDateRange,
                      icon: const Icon(Icons.date_range),
                      label: const Text('Select Dates'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Controls
            ElevatedButton(
              onPressed: _isRunning ? null : _execute,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: _isRunning
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Executing...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : const Text(
                      'Execute',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 24),

            // Log Console
            const Text(
              'Execution Logs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                padding: const EdgeInsets.all(16),
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'Logs will appear here...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: SelectableText(
                              _logs[index],
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
