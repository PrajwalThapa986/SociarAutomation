import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class AutomatorScreen extends StatefulWidget {
  const AutomatorScreen({super.key});

  @override
  State<AutomatorScreen> createState() => _AutomatorScreenState();
}

class _AutomatorScreenState extends State<AutomatorScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTimeRange? _selectedDateRange;
  bool _saveTokenLocally = true;

  @override
  void initState() {
    super.initState();
    context.read<AttendanceBloc>().add(LoadTokenEvent());
    final today = DateTime.now();
    _selectedDateRange = DateTimeRange(start: today, end: today);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  Future<void> _pickDateRange(BuildContext context) async {
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
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceRunning || state is AttendanceCompleted) {
            _scrollToBottom();
          }
          if (state is AttendanceInitial && state.savedToken != null && _tokenController.text.isEmpty) {
            _tokenController.text = state.savedToken!;
          }
          // Also set token if it loaded dynamically from another step and field is empty
          if (state.savedToken != null && _tokenController.text.isEmpty) {
            _tokenController.text = state.savedToken!;
          }
        },
        builder: (context, state) {
          bool isRunning = state is AttendanceRunning;
          List<String> logs = state.logs;

          return Padding(
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
                  obscureText: true,
                  enabled: !isRunning,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text("Save token locally"),
                  value: _saveTokenLocally,
                  onChanged: isRunning ? null : (val) {
                    setState(() {
                      _saveTokenLocally = val ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

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
                          onPressed: isRunning ? null : () => _pickDateRange(context),
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
                  onPressed: isRunning
                      ? null
                      : () {
                          final token = _tokenController.text.trim();
                          if (token.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter your Bearer token.')),
                            );
                            return;
                          }
                          if (_selectedDateRange == null) {
                            return;
                          }
                          context.read<AttendanceBloc>().add(
                                ExecuteAttendanceEvent(
                                  token: token,
                                  startDate: _selectedDateRange!.start,
                                  endDate: _selectedDateRange!.end,
                                  saveTokenLocally: _saveTokenLocally,
                                ),
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: isRunning
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
                    child: logs.isEmpty
                        ? const Center(
                            child: Text(
                              'Logs will appear here...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: SelectableText(
                                  logs[index],
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
          );
        },
      ),
    );
  }
}
