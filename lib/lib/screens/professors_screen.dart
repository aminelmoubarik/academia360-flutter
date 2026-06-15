import 'package:flutter/material.dart';
import '../core/ui.dart';
import '../services/api_service.dart';

class ProfessorsScreen extends StatefulWidget {
  const ProfessorsScreen({super.key});
  @override
  State<ProfessorsScreen> createState() => _ProfessorsScreenState();
}

class _ProfessorsScreenState extends State<ProfessorsScreen> {
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getProfessors();
      setState(() { _all = data; _filtered = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _search(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = _all.where((p) =>
        (p['full_name'] ?? '').toLowerCase().contains(query) ||
        (p['email'] ?? '').toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professors'),
        backgroundColor: const Color(0xFF0CA678),
      ),
      body: _loading ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _load)
          : Column(children: [
              SearchBarField(hint: 'Search by name or email…', onChanged: _search),
              ResultCount(count: _filtered.length, noun: 'professors'),
              Expanded(
                child: _filtered.isEmpty
                    ? const EmptyView(icon: Icons.school_outlined, message: 'No professors found')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            return Card(
                              child: ListTile(
                                leading: InitialAvatar(
                                    text: p['full_name'] ?? '?',
                                    color: const Color(0xFF0CA678)),
                                title: Text(p['full_name'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (p['email'] != null) Text(p['email']),
                                    if (p['disciplines'] != null &&
                                        p['disciplines'].toString().isNotEmpty)
                                      Text(p['disciplines'],
                                          style: const TextStyle(fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ]),
    );
  }
}
