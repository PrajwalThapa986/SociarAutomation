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
  final TextEditingController _worklogController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTimeRange? _selectedDateRange;
  bool _saveTokenLocally = true;
  bool _isSingleDateMode = false;
  bool _skipWeekends = true;
  bool _submitAttendance = true;
  bool _submitWorklog = false;

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
    _worklogController.dispose();
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

  Future<void> _pickSingleDate(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateRange?.start ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = DateTimeRange(start: picked, end: picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    String dateRangeText = "No date selected";
    if (_selectedDateRange != null) {
      if (_selectedDateRange!.start.day == _selectedDateRange!.end.day && 
          _selectedDateRange!.start.month == _selectedDateRange!.end.month && 
          _selectedDateRange!.start.year == _selectedDateRange!.end.year) {
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

          return SingleChildScrollView(
            child: Padding(
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
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text("Save token"),
                          value: _saveTokenLocally,
                          onChanged: isRunning ? null : (val) {
                            setState(() {
                              _saveTokenLocally = val ?? true;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text("Skip Weekends"),
                          value: _skipWeekends,
                          onChanged: isRunning ? null : (val) {
                            setState(() {
                              _skipWeekends = val ?? true;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Selection
                  Row(
                    children: [
                      const Text("Actions:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: const Text("Attendance"),
                        selected: _submitAttendance,
                        onSelected: isRunning ? null : (selected) {
                          setState(() {
                            _submitAttendance = selected;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text("Worklog"),
                        selected: _submitWorklog,
                        onSelected: isRunning ? null : (selected) {
                          setState(() {
                            _submitWorklog = selected;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Mode Selection
                  Row(
                    children: [
                      const Text("Date Mode:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text("Range"),
                        selected: !_isSingleDateMode,
                        onSelected: isRunning ? null : (selected) {
                          if (selected) {
                            setState(() {
                              _isSingleDateMode = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Single Day"),
                        selected: _isSingleDateMode,
                        onSelected: isRunning ? null : (selected) {
                          if (selected) {
                            setState(() {
                              _isSingleDateMode = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                                Text(
                                  _isSingleDateMode ? 'Selected Date:' : 'Selected Date Range:',
                                  style: const TextStyle(
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
                            onPressed: isRunning 
                                ? null 
                                : () => _isSingleDateMode ? _pickSingleDate(context) : _pickDateRange(context),
                            icon: Icon(_isSingleDateMode ? Icons.calendar_today : Icons.date_range),
                            label: Text(_isSingleDateMode ? 'Select Date' : 'Select Dates'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Worklog Input (Conditional)
                  if (_submitWorklog) ...[
                    TextField(
                      controller: _worklogController,
                      maxLines: 5,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Daily Worklog Content',
                        hintText: '[Date: 2026-03-24]\n[09:00 - 13:00] Task details...\n[14:00 - 18:00] Next task details...\n\n[Date: 2026-03-25]\n[09:00 - 13:00] More tasks...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        alignLabelWithHint: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Approve Pending Requests
                  OutlinedButton.icon(
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
                            context.read<AttendanceBloc>().add(
                                  ApproveAttendanceRequestsEvent(
                                    token: token,
                                    saveTokenLocally: _saveTokenLocally,
                                  ),
                                );
                          },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Approve All Pending Requests',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),

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
                            if (!_submitAttendance && !_submitWorklog) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select at least one action (Attendance or Worklog).')),
                              );
                              return;
                            }
                            if (_submitWorklog && _worklogController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a worklog.')),
                              );
                              return;
                            }
                            context.read<AttendanceBloc>().add(
                                  ExecuteAttendanceEvent(
                                    token: token,
                                    startDate: _selectedDateRange!.start,
                                    endDate: _selectedDateRange!.end,
                                    saveTokenLocally: _saveTokenLocally,
                                    skipWeekends: _skipWeekends,
                                    submitAttendance: _submitAttendance,
                                    submitWorklog: _submitWorklog,
                                    worklogText: _worklogController.text,
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
                  Container(
                    height: 350, // Fixed height for log console
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
