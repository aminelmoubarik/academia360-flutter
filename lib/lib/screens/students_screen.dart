import 'package:flutter/material.dart';
import '../core/ui.dart';
import '../services/api_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<dynamic> _all = [], _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getStudents();
      setState(() { _all = data; _filtered = data; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _search(String q) {
    final query = q.toLowerCase();
    setState(() { _filtered = _all.where((s) =>
      (s['full_name'] ?? '').toLowerCase().contains(query) ||
      (s['student_number'] ?? '').toLowerCase().contains(query) ||
      (s['class_name'] ?? '').toLowerCase().contains(query)).toList(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: _loading ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _load)
          : Column(children: [
              SearchBarField(hint: 'Search by name, number or class…', onChanged: _search),
              ResultCount(count: _filtered.length, noun: 'students'),
              Expanded(
                child: _filtered.isEmpty
                    ? const EmptyView(icon: Icons.person_off_outlined, message: 'No students found')
                    : RefreshIndicator(onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final s = _filtered[i];
                            return Card(child: ListTile(
                              leading: InitialAvatar(text: s['full_name'] ?? '?'),
                              title: Text(s['full_name'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text([
                                if (s['student_number'] != null) '#${s['student_number']}',
                                if (s['class_name'] != null) s['class_name'],
                                if (s['course_name'] != null) s['course_name'],
                              ].join(' · ')),
                              trailing: s['school_year'] != null ? Tag(text: s['school_year']) : null,
                            ));
                          },
                        ),
                      ),
              ),
            ]),
    );
  }
}
