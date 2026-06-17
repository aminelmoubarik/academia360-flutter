import 'package:flutter/material.dart';
import '../core/ui.dart';
import '../main.dart';
import '../services/api_service.dart';

const _brown = Color(0xFF5C3D2E);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _report = [];
  bool _loading = true;
  String? _error;
  int _totalPunches = 0;
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
        final schedules = records
            .map((r) => r['schedule_id'])
            .where((id) => id != null)
            .toSet();
        report.add({
          'student_id': s['id'],
          'full_name': s['full_name'] ?? '',
          'student_number': s['student_number'] ?? '',
          'class_name': s['class_name'] ?? '',
          'sessions': schedules.length,
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
        title: const Text('Relatório de assiduidade'),
        backgroundColor: Colors.white,
        foregroundColor: Brand.ink,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [_brown, Brand.blueLight])),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            onSelected: (v) => setState(() { _sortBy = v; _sort(); }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'name', child: Text('Ordenar por nome')),
              PopupMenuItem(value: 'desc', child: Text('Mais assiduidade primeiro')),
              PopupMenuItem(value: 'asc', child: Text('Menos assiduidade primeiro')),
            ],
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Brand.blueSoft.withValues(alpha: 0.38), Brand.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _load)
          : Column(children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(label: 'Estudantes', value: '${_report.length}',
                        color: Brand.blue, icon: Icons.people_outlined),
                    _Stat(label: 'Total de picagens', value: '$_totalPunches',
                        color: const Color(0xFF0CA678), icon: Icons.fingerprint),
                    _Stat(label: 'Sem assiduidade', value: '$zero',
                        color: const Color(0xFFE03131), icon: Icons.warning_amber),
                  ],
                ),
              ),
              Expanded(child: RefreshIndicator(onRefresh: _load,
                child: _report.isEmpty
                    ? const EmptyView(icon: Icons.bar_chart_outlined, message: 'Sem dados para relatório')
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _report.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = _report[i];
                    final n = r['sessions'] as int;
                    final color = _c(n);
                    return Card(child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(n == 0 ? Icons.warning_amber : Icons.check_circle_outline,
                            color: color, size: 20),
                      ),
                      title: Text(r['full_name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text([
                        if ((r['student_number'] as String).isNotEmpty) '#${r['student_number']}',
                        if ((r['class_name'] as String).isNotEmpty) r['class_name'],
                      ].join(' · ')),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$n sessões',
                              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                          Text('${r['punches']} picagens',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ));
                  },
                ),
              )),
            ]),
      ),
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
