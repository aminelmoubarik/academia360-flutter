import 'package:flutter/material.dart';
import '../core/permissions.dart';
import '../core/ui.dart';
import '../main.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'attendance_punch_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> _all = [], _filtered = [];
  User? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _bootstrap(); }

  Future<void> _bootstrap() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() => _user = user);
    await _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getAttendance();
      setState(() { _all = data; _filtered = data; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _search(String q) {
    final query = q.toLowerCase();
    setState(() { _filtered = _all.where((r) =>
      (r['student_name'] ?? '').toLowerCase().contains(query) ||
      (r['student_number'] ?? '').toLowerCase().contains(query) ||
      (r['discipline_name'] ?? '').toLowerCase().contains(query)).toList(); });
  }

  String _formatDT(dynamic dt) {
    if (dt == null) return '';
    final s = dt.toString();
    return s.length >= 16 ? s.substring(0, 16).replaceAll('T', ' ') : s;
  }

  String _punchLabel(dynamic type) => type == 'in' ? 'Entrada' : 'Saída';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assiduidade'),
        actions: [
          if (AppPermissions.canUsePunchTerminal(_user?.role)) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendancePunchScreen())).then((_) => _load()),
              icon: const Icon(Icons.contactless_outlined, size: 18),
              label: const Text('Picagem'),
            ),
            const SizedBox(width: 10),
          ],
        ],
        backgroundColor: AppColors.of(context).surface,
        foregroundColor: AppColors.of(context).ink,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFD6336C), Brand.blueLight]),
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.of(context).isDark ? [AppColors.of(context).surface, AppColors.of(context).bg] : [Colors.white, Brand.blueSoft.withValues(alpha: 0.42), AppColors.of(context).bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _load)
          : Column(children: [
              SearchBarField(hint: 'Pesquisar por estudante ou disciplina…', onChanged: _search),
              ResultCount(count: _filtered.length, noun: 'registos'),
              Expanded(child: RefreshIndicator(onRefresh: _load,
                child: _filtered.isEmpty
                    ? const EmptyView(icon: Icons.fingerprint, message: 'Sem registos de assiduidade')
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = _filtered[i];
                    final isIn = r['punch_type'] == 'in';
                    final color = isIn ? const Color(0xFF0CA678) : const Color(0xFFE03131);
                    return Card(child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(isIn ? Icons.login : Icons.logout, color: color, size: 20),
                      ),
                      title: Text(r['student_name'] ?? 'Desconhecido',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text([
                        if (r['student_number'] != null) '#${r['student_number']}',
                        if (r['class_name'] != null) r['class_name'],
                        if (r['discipline_name'] != null) r['discipline_name'],
                        _punchLabel(r['punch_type']),
                      ].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatDT(r['punch_time']),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          Text(r['punch_method']?.toString().toUpperCase() ?? '',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ));
                  },
                ),
              )),
            ]),
      ),
    );
  }
}
