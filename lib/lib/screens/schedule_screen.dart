import 'package:flutter/material.dart';
import '../core/ui.dart';
import '../services/api_service.dart';

const _indigo = Color(0xFF1929E9);
const _orange = Color(0xFFE8590C);

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
  void initState() { super.initState(); _loadClasses(); }

  Future<void> _loadClasses() async {
    setState(() { _loadingClasses = true; _error = null; });
    try {
      final data = await ApiService.getClasses();
      setState(() { _classes = data; _loadingClasses = false; });
    } catch (e) { setState(() { _error = e.toString(); _loadingClasses = false; }); }
  }

  Future<void> _loadSchedule(int classId) async {
    setState(() { _loadingSchedule = true; _schedule = []; });
    try {
      final data = await ApiService.getScheduleByClass(classId);
      setState(() { _schedule = data; _loadingSchedule = false; });
    } catch (e) { setState(() { _error = e.toString(); _loadingSchedule = false; }); }
  }

  String _t(dynamic v) {
    final s = v?.toString() ?? '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'approved': return const Color(0xFF0CA678);
      case 'draft': return _orange;
      case 'cancelled': return const Color(0xFFE03131);
      default: return Colors.grey;
    }
  }

  void _openGenerator() {
    if (_selectedClass == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => GenerateScheduleScreen(selectedClass: _selectedClass),
    )).then((_) {
      if (_selectedClass != null) _loadSchedule(_selectedClass['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: _loadingClasses ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _loadClasses)
          : Column(children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<dynamic>(
                  decoration: const InputDecoration(labelText: 'Select a class'),
                  value: _selectedClass,
                  items: _classes.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c['name']} — ${c['course_name']} (${c['school_year']})',
                        overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) {
                    setState(() => _selectedClass = v);
                    if (v != null) _loadSchedule(v['id']);
                  },
                ),
              ),
              if (_loadingSchedule)
                const Expanded(child: LoadingView())
              else if (_selectedClass == null)
                const Expanded(child: EmptyView(
                  icon: Icons.calendar_month_outlined,
                  message: 'Select a class to view its schedule'))
              else if (_schedule.isEmpty)
                Expanded(child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('No schedule for this class'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: _orange),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Generate schedule'),
                      onPressed: _openGenerator,
                    ),
                  ],
                )))
              else
                Expanded(child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_schedule.length} sessions',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        TextButton.icon(
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Regenerate'),
                          onPressed: _openGenerator,
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: Builder(builder: (context) {
                    // Agrupar sesiones por fecha para cabeceras tipo agenda
                    final items = <dynamic>[];
                    String? lastDate;
                    for (final s in _schedule) {
                      final d = s['schedule_date']?.toString().substring(0, 10) ?? '';
                      if (d != lastDate) { items.add(d); lastDate = d; }
                      items.add(s);
                    }
                    return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      if (item is String) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 2),
                          child: Row(children: [
                            const Icon(Icons.calendar_today,
                                size: 13, color: _indigo),
                            const SizedBox(width: 6),
                            Text(item, style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13, color: _indigo)),
                            const SizedBox(width: 10),
                            const Expanded(child: Divider()),
                          ]),
                        );
                      }
                      final s = item;
                      return Card(child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Container(
                            width: 4, height: 56,
                            decoration: BoxDecoration(
                              color: _statusColor(s['status']),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['discipline_name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('${s['professor_name'] ?? ''} · ${s['room_name'] ?? ''}',
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          )),
                          Text('${_t(s['start_time'])} – ${_t(s['end_time'])}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14, color: _indigo)),
                        ]),
                      ));
                    },
                  );
                  })),
                ])),
            ]),
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
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));
  bool _replace = false;
  bool _generating = false;
  Map<String, dynamic>? _result;
  String? _error;

  String _d(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<void> _pick(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _generate() async {
    setState(() { _generating = true; _result = null; _error = null; });
    try {
      final r = await ApiService.generateSchedule(
        classId: widget.selectedClass['id'],
        startDate: _d(_start),
        endDate: _d(_end),
        replaceExisting: _replace,
      );
      setState(() { _result = r; _generating = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _generating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ok = _result?['success'] == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Schedule'),
        backgroundColor: _orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Class: ${widget.selectedClass['name']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${widget.selectedClass['course_name']} · ${widget.selectedClass['school_year']}',
                      style: TextStyle(color: Colors.grey.shade600)),
                ]),
              )),
              const SizedBox(height: 20),
              const Text('Date range', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('Start: ${_d(_start)}'),
                  onPressed: () => _pick(true),
                )),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('End: ${_d(_end)}'),
                  onPressed: () => _pick(false),
                )),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Replace existing schedule'),
                subtitle: const Text('Deletes the current schedule in this range'),
                value: _replace,
                onChanged: (v) => setState(() => _replace = v),
              ),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _orange),
                icon: _generating
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_generating ? 'Generating…' : 'Generate Schedule'),
                onPressed: _generating ? null : _generate,
              )),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _ResultBox(color: const Color(0xFFE03131), icon: Icons.error_outline,
                    title: 'Generation failed', lines: [_error!]),
              ],
              if (_result != null) ...[
                const SizedBox(height: 16),
                _ResultBox(
                  color: ok ? const Color(0xFF0CA678) : _orange,
                  icon: ok ? Icons.check_circle_outline : Icons.warning_amber,
                  title: ok ? 'Schedule generated successfully'
                            : 'Completed with issues',
                  lines: [
                    'Sessions created: ${_result!['created_records']}',
                    'Quality score: ${_result!['score']}',
                    ...((_result!['conflicts'] as List?) ?? []).take(3).map(
                        (c) => '• ${c['discipline']}: ${c['reason']}'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Schedule'),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final List<String> lines;
  const _ResultBox({required this.color, required this.icon,
      required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 8),
        ...lines.map((l) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(l, style: const TextStyle(fontSize: 13)))),
      ]),
    );
  }
}
