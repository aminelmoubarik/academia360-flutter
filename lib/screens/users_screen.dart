import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getUsers();
      setState(() {
        _users = data;
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _search(String query) {
    setState(() {
      _filtered = _users.where((u) {
        final name = (u['full_name'] ?? '').toLowerCase();
        final email = (u['email'] ?? '').toLowerCase();
        final role = (u['role'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase()) ||
            role.contains(query.toLowerCase());
      }).toList();
    });
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'director': return Colors.purple;
      case 'secretary': return Colors.blue;
      case 'professor': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Colors.blueGrey.shade700,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _search,
                        decoration: InputDecoration(
                          hintText: 'Search by name, email or role...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(children: [
                        Text('${_filtered.length} users',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ]),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final u = _filtered[index];
                          final role = u['role']?.toString();
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _roleColor(role).withOpacity(0.15),
                                child: Text(
                                  (u['full_name'] as String? ?? '?')[0].toUpperCase(),
                                  style: TextStyle(
                                      color: _roleColor(role),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(u['full_name'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(u['email'] ?? ''),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _roleColor(role).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _roleColor(role).withOpacity(0.3)),
                                ),
                                child: Text(
                                  role?.toUpperCase() ?? '',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _roleColor(role),
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
