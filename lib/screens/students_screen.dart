import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<dynamic> _students = [];
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
      final data = await ApiService.getStudents();
      setState(() {
        _students = data;
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
      _filtered = _students.where((s) {
        final name = (s['full_name'] ?? '').toLowerCase();
        final number = (s['student_number'] ?? '').toLowerCase();
        final cls = (s['class_name'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) ||
            number.contains(query.toLowerCase()) ||
            cls.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: Colors.blue.shade700,
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
                          hintText: 'Search by name, number or class...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${_filtered.length} students',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = _filtered[index];
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  (s['full_name'] as String? ?? '?')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                s['full_name'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                [
                                  if (s['student_number'] != null) '#${s['student_number']}',
                                  if (s['class_name'] != null) s['class_name'],
                                  if (s['course_name'] != null) s['course_name'],
                                ].join(' · '),
                              ),
                              trailing: s['school_year'] != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        s['school_year'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    )
                                  : null,
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
