import 'package:flutter/material.dart';
import '../core/ui.dart';
import '../services/api_service.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});
  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<dynamic> _all = [], _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getClasses();
      setState(() { _all = data; _filtered = data; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _search(String q) {
    final query = q.toLowerCase();
    setState(() { _filtered = _all.where((c) =>
      (c['name'] ?? '').toLowerCase().contains(query) ||
      (c['course_name'] ?? '').toLowerCase().contains(query) ||
      (c['school_year'] ?? '').toLowerCase().contains(query)).toList(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classes'), backgroundColor: const Color(0xFFE8590C)),
      body: _loading ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _load)
          : Column(children: [
              SearchBarField(hint: 'Search by name, course or year…', onChanged: _search),
              ResultCount(count: _filtered.length, noun: 'classes'),
              Expanded(child: RefreshIndicator(onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final c = _filtered[i];
                    return Card(child: ListTile(
                      leading: InitialAvatar(
                        text: '${c['course_year_number'] ?? '?'}',
                        color: const Color(0xFFE8590C),
                      ),
                      title: Text(c['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${c['course_name'] ?? ''} · ${c['course_code'] ?? ''}'),
                      trailing: c['school_year'] != null
                          ? Tag(text: c['school_year'], color: const Color(0xFFE8590C))
                          : null,
                    ));
                  },
                ),
              )),
            ]),
    );
  }
}
