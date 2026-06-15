import 'package:flutter/material.dart';
import '../core/ui.dart';
import '../services/api_service.dart';

class DisciplinesScreen extends StatefulWidget {
  const DisciplinesScreen({super.key});
  @override
  State<DisciplinesScreen> createState() => _DisciplinesScreenState();
}

class _DisciplinesScreenState extends State<DisciplinesScreen> {
  List<dynamic> _all = [], _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getDisciplines();
      setState(() { _all = data; _filtered = data; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _search(String q) {
    final query = q.toLowerCase();
    setState(() { _filtered = _all.where((d) =>
      (d['name'] ?? '').toLowerCase().contains(query) ||
      (d['code'] ?? '').toLowerCase().contains(query)).toList(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disciplines'), backgroundColor: const Color(0xFF7048E8)),
      body: _loading ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _load)
          : Column(children: [
              SearchBarField(hint: 'Search by name or code…', onChanged: _search),
              ResultCount(count: _filtered.length, noun: 'disciplines'),
              Expanded(child: RefreshIndicator(onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = _filtered[i];
                    final code = d['code']?.toString() ?? '';
                    return Card(child: ListTile(
                      leading: InitialAvatar(
                        text: code.isNotEmpty ? code.substring(0, code.length > 2 ? 2 : code.length) : 'D',
                        color: const Color(0xFF7048E8),
                      ),
                      title: Text(d['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: code.isNotEmpty ? Text('Code: $code') : null,
                    ));
                  },
                ),
              )),
            ]),
    );
  }
}
