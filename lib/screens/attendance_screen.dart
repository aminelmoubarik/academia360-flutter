import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> _records = [];
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
      final data = await ApiService.getAttendance();
      setState(() {
        _records = data;
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
      _filtered = _records.where((r) {
        final name = (r['student_name'] ?? '').toLowerCase();
        final number = (r['student_number'] ?? '').toLowerCase();
        final discipline = (r['discipline_name'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) ||
            number.contains(query.toLowerCase()) ||
            discipline.contains(query.toLowerCase());
      }).toList();
    });
  }

  Color _punchColor(String? type) {
    return type == 'in' ? Colors.green : Colors.red;
  }

  IconData _punchIcon(String? type) {
    return type == 'in' ? Icons.login : Icons.logout;
  }

  IconData _methodIcon(String? method) {
    switch (method) {
      case 'nfc': return Icons.nfc;
      case 'qr': return Icons.qr_code;
      case 'manual': return Icons.edit;
      default: return Icons.fingerprint;
    }
  }

  String _formatDateTime(dynamic dt) {
    if (dt == null) return '';
    final str = dt.toString();
    if (str.length >= 16) return str.substring(0, 16).replaceAll('T', ' ');
    return str;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.red.shade700,
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
                          hintText: 'Search by student or discipline...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(children: [
                        Text('${_filtered.length} records',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13)),
                      ]),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final r = _filtered[index];
                          final punchType = r['punch_type']?.toString();
                          final method = r['punch_method']?.toString();
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _punchColor(punchType).withOpacity(0.15),
                                child: Icon(_punchIcon(punchType),
                                    color: _punchColor(punchType)),
                              ),
                              title: Text(r['student_name'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text([
                                if (r['student_number'] != null)
                                  '#${r['student_number']}',
                                if (r['class_name'] != null) r['class_name'],
                                if (r['discipline_name'] != null)
                                  r['discipline_name'],
                              ].join(' · ')),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatDateTime(r['punch_time']),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_methodIcon(method),
                                          size: 14,
                                          color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(method ?? '',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ],
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
