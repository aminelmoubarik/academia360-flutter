import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<dynamic> _students = [];
  List<dynamic> _attendance = [];
  List<Map<String, dynamic>> _report = [];
  bool _loading = true;
  String? _error;
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final students = await ApiService.getStudents();
      final attendance = await ApiService.getAttendance();
      setState(() {
        _students = students;
        _attendance = attendance;
        _report = _buildReport(students, attendance);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _buildReport(
      List<dynamic> students, List<dynamic> attendance) {
    final report = <Map<String, dynamic>>[];

    for (final student in students) {
      final studentId = student['id'];
      final records = attendance
          .where((a) => a['student_id'] == studentId)
          .toList();

      final punchIns = records.where((a) => a['punch_type'] == 'in').length;
      final totalSessions = punchIns;

      report.add({
        'id': studentId,
        'full_name': student['full_name'] ?? 'Unknown',
        'student_number': student['student_number'] ?? '',
        'class_name': student['class_name'] ?? '',
        'course_name': student['course_name'] ?? '',
        'total_sessions': totalSessions,
        'total_records': records.length,
      });
    }

    _sortReport(report);
    return report;
  }

  void _sortReport(List<Map<String, dynamic>> report) {
    if (_sortBy == 'sessions_desc') {
      report.sort((a, b) =>
          (b['total_sessions'] as int).compareTo(a['total_sessions'] as int));
    } else if (_sortBy == 'sessions_asc') {
      report.sort((a, b) =>
          (a['total_sessions'] as int).compareTo(b['total_sessions'] as int));
    } else {
      report.sort((a, b) =>
          (a['full_name'] as String).compareTo(b['full_name'] as String));
    }
  }

  Color _attendanceColor(int sessions) {
    if (sessions == 0) return Colors.red;
    if (sessions < 3) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortReport(_report);
              });
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'name', child: Text('Sort by name')),
              const PopupMenuItem(
                  value: 'sessions_desc',
                  child: Text('Most attendance first')),
              const PopupMenuItem(
                  value: 'sessions_asc',
                  child: Text('Least attendance first')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    Container(
                      color: Colors.brown.shade50,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatCard(
                            label: 'Students',
                            value: '${_report.length}',
                            color: Colors.blue,
                            icon: Icons.people,
                          ),
                          _StatCard(
                            label: 'Total punches',
                            value: '${_attendance.length}',
                            color: Colors.green,
                            icon: Icons.fingerprint,
                          ),
                          _StatCard(
                            label: 'No attendance',
                            value: '${_report.where((r) => r['total_sessions'] == 0).length}',
                            color: Colors.red,
                            icon: Icons.warning,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _report.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final r = _report[index];
                          final sessions = r['total_sessions'] as int;
                          final color = _attendanceColor(sessions);
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color.withOpacity(0.15),
                                    child: Icon(
                                      sessions == 0
                                          ? Icons.warning
                                          : Icons.check_circle,
                                      color: color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r['full_name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          [
                                            if (r['student_number'].isNotEmpty)
                                              '#${r['student_number']}',
                                            if (r['class_name'].isNotEmpty)
                                              r['class_name'],
                                          ].join(' · '),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$sessions sessions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        '${r['total_records']} punches',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500),
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
