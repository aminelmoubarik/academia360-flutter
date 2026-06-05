import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<dynamic> _courses = [];
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
      final data = await ApiService.getCourses();
      setState(() {
        _courses = data;
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
      _filtered = _courses.where((c) {
        final name = (c['name'] ?? '').toLowerCase();
        final code = (c['code'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) ||
            code.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        backgroundColor: Colors.cyan.shade700,
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
                          hintText: 'Search by name or code...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(children: [
                        Text('${_filtered.length} courses',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ]),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final c = _filtered[index];
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.cyan.shade100,
                                child: Text(
                                  (c['code'] as String? ?? '?')
                                      .substring(0, c['code'].toString().length > 2 ? 2 : c['code'].toString().length)
                                      .toUpperCase(),
                                  style: TextStyle(
                                      color: Colors.cyan.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                              title: Text(c['name'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('Code: ${c['code'] ?? ''}'),
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
