import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<dynamic> _classes = [];
  List<dynamic> _schedule = [];
  dynamic _selectedClass;
  bool _loadingClasses = true;
  bool _loadingSchedule = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final data = await ApiService.getClasses();
      setState(() {
        _classes = data;
        _loadingClasses = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingClasses = false;
      });
    }
  }

  Future<void> _loadSchedule(int classId) async {
    setState(() {
      _loadingSchedule = true;
      _schedule = [];
    });
    try {
      final data = await ApiService.getScheduleByClass(classId);
      setState(() {
        _schedule = data;
        _loadingSchedule = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingSchedule = false;
      });
    }
  }

  String _formatTime(dynamic t) {
    if (t == null) return '';
    final str = t.toString();
    if (str.length >= 5) return str.substring(0, 5);
    return str;
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'draft': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _loadingClasses
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    Container(
                      color: Colors.indigo.shade50,
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<dynamic>(
                        decoration: InputDecoration(
                          labelText: 'Select a class',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: _selectedClass,
                        items: _classes.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text('${c['name']} — ${c['course_name']} (${c['school_year']})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedClass = value);
                          if (value != null) {
                            _loadSchedule(value['id']);
                          }
                        },
                      ),
                    ),
                    if (_loadingSchedule)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_selectedClass == null)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'Select a class to view its schedule',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_schedule.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text('No schedule found for this class'),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('Generate schedule'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GenerateScheduleScreen(
                                        selectedClass: _selectedClass,
                                      ),
                                    ),
                                  ).then((_) {
                                    if (_selectedClass != null) {
                                      _loadSchedule(_selectedClass['id']);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_schedule.length} sessions',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.auto_awesome, size: 16),
                                    label: const Text('Regenerate'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => GenerateScheduleScreen(
                                            selectedClass: _selectedClass,
                                          ),
                                        ),
                                      ).then((_) {
                                        if (_selectedClass != null) {
                                          _loadSchedule(_selectedClass['id']);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _schedule.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final s = _schedule[index];
                                  return Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: _statusColor(s['status']),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s['discipline_name'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${s['professor_name'] ?? ''} · ${s['room_name'] ?? ''}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                s['schedule_date']?.toString().substring(0, 10) ?? '',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600),
                                              ),
                                              Text(
                                                '${_formatTime(s['start_time'])} - ${_formatTime(s['end_time'])}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

class GenerateScheduleScreen extends StatefulWidget {
  final dynamic selectedClass;
  const GenerateScheduleScreen({super.key, required this.selectedClass});

  @override
  State<GenerateScheduleScreen> createState() => _GenerateScheduleScreenState();
}

class _GenerateScheduleScreenState extends State<GenerateScheduleScreen> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _replaceExisting = false;
  bool _generating = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _result = null;
      _error = null;
    });
    try {
      final result = await ApiService.generateSchedule(
        classId: widget.selectedClass['id'],
        startDate: _startDate.toIso8601String().substring(0, 10),
        endDate: _endDate.toIso8601String().substring(0, 10),
        replaceExisting: _replaceExisting,
      );
      setState(() {
        _result = result;
        _generating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _generating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Schedule'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class: ${widget.selectedClass['name']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${widget.selectedClass['course_name']} · ${widget.selectedClass['school_year']}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Date Range',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                        'Start: ${_startDate.toIso8601String().substring(0, 10)}'),
                    onPressed: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                        'End: ${_endDate.toIso8601String().substring(0, 10)}'),
                    onPressed: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Replace existing schedule'),
              subtitle: const Text('Deletes current schedule for this class in the selected range'),
              value: _replaceExisting,
              onChanged: (v) => setState(() => _replaceExisting = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_generating ? 'Generating...' : 'Generate Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _generating ? null : _generate,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _result!['success'] == true
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _result!['success'] == true
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _result!['success'] == true
                              ? Icons.check_circle
                              : Icons.warning,
                          color: _result!['success'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _result!['success'] == true
                              ? 'Schedule generated successfully'
                              : 'Generation completed with issues',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _result!['success'] == true
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Sessions created: ${_result!['created_records']}'),
                    Text('Quality score: ${_result!['score']}'),
                    if ((_result!['conflicts'] as List?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Conflicts (${(_result!['conflicts'] as List).length}):',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...(_result!['conflicts'] as List).take(3).map(
                            (c) => Text('• ${c['discipline']}: ${c['reason']}',
                                style: const TextStyle(fontSize: 13)),
                          ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back to Schedule'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
