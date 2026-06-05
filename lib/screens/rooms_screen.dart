import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<dynamic> _rooms = [];
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
      final data = await ApiService.getRooms();
      setState(() {
        _rooms = data;
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
      _filtered = _rooms.where((r) {
        final name = (r['name'] ?? '').toLowerCase();
        final location = (r['location'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) ||
            location.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        backgroundColor: Colors.teal.shade700,
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
                          hintText: 'Search by name or location...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final r = _filtered[index];
                          final isPractice = r['is_practice_room'] == 1 ||
                              r['is_practice_room'] == true;
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPractice
                                    ? Colors.orange.shade100
                                    : Colors.teal.shade100,
                                child: Icon(
                                  isPractice
                                      ? Icons.science
                                      : Icons.meeting_room,
                                  color: isPractice
                                      ? Colors.orange.shade700
                                      : Colors.teal.shade700,
                                ),
                              ),
                              title: Text(r['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text([
                                if (r['capacity'] != null)
                                  'Capacity: ${r['capacity']}',
                                if (r['location'] != null) r['location'],
                              ].join(' · ')),
                              trailing: isPractice
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.orange.shade200),
                                      ),
                                      child: Text('Practice',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w600)),
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
