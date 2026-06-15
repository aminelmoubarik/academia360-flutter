import 'package:flutter/material.dart';
import '../core/ui.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> _all = [], _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getAttendance();
      setState(() { _all = data; _filtered = data; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _search(String q) {
    final query = q.toLowerCase();
    setState(() { _filtered = _all.where((r) =>
      (r['student_name'] ?? '').toLowerCase().contains(query) ||
      (r['student_number'] ?? '').toLowerCase().contains(query) ||
      (r['discipline_name'] ?? '').toLowerCase().contains(query)).toList(); });
  }

  String _formatDT(dynamic dt) {
    if (dt == null) return '';
    final s = dt.toString();
    return s.length >= 16 ? s.substring(0, 16).replaceAll('T', ' ') : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance'), backgroundColor: const Color(0xFFD6336C)),
      body: _loading ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _load)
          : Column(children: [
              SearchBarField(hint: 'Search by student or discipline…', onChanged: _search),
              ResultCount(count: _filtered.length, noun: 'records'),
              Expanded(child: RefreshIndicator(onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = _filtered[i];
                    final isIn = r['punch_type'] == 'in';
                    final color = isIn ? const Color(0xFF0CA678) : const Color(0xFFE03131);
                    return Card(child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(isIn ? Icons.login : Icons.logout, color: color, size: 20),
                      ),
                      title: Text(r['student_name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text([
                        if (r['student_number'] != null) '#${r['student_number']}',
                        if (r['class_name'] != null) r['class_name'],
                        if (r['discipline_name'] != null) r['discipline_name'],
                      ].join(' · ')),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatDT(r['punch_time']),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(r['punch_method']?.toString() ?? '',
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
