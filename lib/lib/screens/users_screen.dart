import 'package:flutter/material.dart';
import '../core/ui.dart';
import '../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _all = [], _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getUsers();
      setState(() { _all = data; _filtered = data; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _search(String q) {
    final query = q.toLowerCase();
    setState(() { _filtered = _all.where((u) =>
      (u['full_name'] ?? '').toLowerCase().contains(query) ||
      (u['email'] ?? '').toLowerCase().contains(query) ||
      (u['role'] ?? '').toLowerCase().contains(query)).toList(); });
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'admin': return const Color(0xFFE03131);
      case 'director': return const Color(0xFF7048E8);
      case 'secretary': return const Color(0xFF1929E9);
      case 'professor': return const Color(0xFF0CA678);
      default: return const Color(0xFF868E96);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users'), backgroundColor: const Color(0xFF495057)),
      body: _loading ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _load)
          : Column(children: [
              SearchBarField(hint: 'Search by name, email or role…', onChanged: _search),
              ResultCount(count: _filtered.length, noun: 'users'),
              Expanded(child: RefreshIndicator(onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final u = _filtered[i];
                    final role = u['role']?.toString();
                    final color = _roleColor(role);
                    return Card(child: ListTile(
                      leading: InitialAvatar(text: u['full_name'] ?? '?', color: color),
                      title: Text(u['full_name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(u['email'] ?? ''),
                      trailing: role != null ? Tag(text: role.toUpperCase(), color: color) : null,
                    ));
                  },
                ),
              )),
            ]),
    );
  }
}
