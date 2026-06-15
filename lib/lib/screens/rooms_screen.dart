import 'package:flutter/material.dart';
import '../core/ui.dart';
import '../services/api_service.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<dynamic> _all = [], _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getRooms();
      setState(() { _all = data; _filtered = data; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _search(String q) {
    final query = q.toLowerCase();
    setState(() { _filtered = _all.where((r) =>
      (r['name'] ?? '').toLowerCase().contains(query) ||
      (r['location'] ?? '').toLowerCase().contains(query)).toList(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rooms'), backgroundColor: const Color(0xFF087F5B)),
      body: _loading ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _load)
          : Column(children: [
              SearchBarField(hint: 'Search by name or location…', onChanged: _search),
              ResultCount(count: _filtered.length, noun: 'rooms'),
              Expanded(child: RefreshIndicator(onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = _filtered[i];
                    final isPractice = r['is_practice_room'] == 1 || r['is_practice_room'] == true;
                    return Card(child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPractice ? const Color(0xFFFFF3E0) : const Color(0xFFE0F2F1),
                        child: Icon(
                          isPractice ? Icons.science_outlined : Icons.meeting_room_outlined,
                          color: isPractice ? const Color(0xFFE8590C) : const Color(0xFF087F5B),
                        ),
                      ),
                      title: Text(r['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text([
                        if (r['capacity'] != null) 'Cap: ${r['capacity']}',
                        if (r['location'] != null) r['location'],
                      ].join(' · ')),
                      trailing: isPractice ? const Tag(text: 'Practice', color: Color(0xFFE8590C)) : null,
                    ));
                  },
                ),
              )),
            ]),
    );
  }
}
