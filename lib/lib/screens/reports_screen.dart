import 'package:flutter/material.dart';
import '../core/ui.dart';
import '../services/api_service.dart';

const _brown = Color(0xFF5C3D2E);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _report = [];
  int _totalPunches = 0;
  bool _loading = true;
  String? _error;
  String _sortBy = 'name';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final students = await ApiService.getStudents();
      final attendance = await ApiService.getAttendance();
      final report = <Map<String, dynamic>>[];
      for (final s in students) {
        final records = attendance.where((a) => a['student_id'] == s['id']).toList();
        report.add({
          'full_name': s['full_name'] ?? 'Unknown',
          'student_number': s['student_number'] ?? '',
          'class_name': s['class_name'] ?? '',
          'sessions': records.where((a) => a['punch_type'] == 'in').length,
          'punches': records.length,
        });
      }
      setState(() {
        _report = report;
        _totalPunches = attendance.length;
        _sort();
        _loading = false;
      });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _sort() {
    if (_sortBy == 'desc') {
      _report.sort((a, b) => (b['sessions'] as int).compareTo(a['sessions'] as int));
    } else if (_sortBy == 'asc') {
      _report.sort((a, b) => (a['sessions'] as int).compareTo(b['sessions'] as int));
    } else {
      _report.sort((a, b) => (a['full_name'] as String).compareTo(b['full_name'] as String));
    }
  }

  Color _c(int n) => n == 0 ? const Color(0xFFE03131)
      : n < 3 ? const Color(0xFFE8590C) : const Color(0xFF0CA678);

  @override
  Widget build(BuildContext context) {
    final zero = _report.where((r) => r['sessions'] == 0).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        backgroundColor: _brown,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() { _sortBy = v; _sort(); }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'name', child: Text('Sort by name')),
              PopupMenuItem(value: 'desc', child: Text('Most attendance first')),
              PopupMenuItem(value: 'asc', child: Text('Least attendance first')),
            ],
          ),
        ],
      ),
      body: _loading ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _load)
          : Column(children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(label: 'Students', value: '${_report.length}',
                        color: const Color(0xFF1929E9), icon: Icons.people_outlined),
                    _Stat(label: 'Total punches', value: '$_totalPunches',
                        color: const Color(0xFF0CA678), icon: Icons.fingerprint),
                    _Stat(label: 'No attendance', value: '$zero',
                        color: const Color(0xFFE03131), icon: Icons.warning_amber),
                  ],
                ),
              ),
              Expanded(child: RefreshIndicator(onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _report.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = _report[i];
                    final n = r['sessions'] as int;
                    final color = _c(n);
                    return Card(child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(n == 0 ? Icons.warning_amber : Icons.check_circle_outline,
                            color: color, size: 20),
                      ),
                      title: Text(r['full_name'],
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text([
                        if ((r['student_number'] as String).isNotEmpty) '#${r['student_number']}',
                        if ((r['class_name'] as String).isNotEmpty) r['class_name'],
                      ].join(' · ')),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$n sessions',
                              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                          Text('${r['punches']} punches',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ));
                  },
                ),
              )),
            ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _Stat({required this.label, required this.value,
      required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 26),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ]);
  }
}
