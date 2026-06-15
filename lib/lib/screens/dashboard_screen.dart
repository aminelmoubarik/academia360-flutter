import 'package:flutter/material.dart';
import '../main.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'students_screen.dart';
import 'professors_screen.dart';
import 'rooms_screen.dart';
import 'disciplines_screen.dart';
import 'attendance_screen.dart';
import 'schedule_screen.dart';
import 'classes_screen.dart';
import 'users_screen.dart';
import 'courses_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? _user;
  bool _loading = true;
  int? _nStudents, _nProfessors, _nClasses;

  @override
  void initState() { super.initState(); _loadUser(); }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() { _user = user; _loading = false; });
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        ApiService.getStudents(),
        ApiService.getProfessors(),
        ApiService.getClasses(),
      ]);
      if (!mounted) return;
      setState(() {
        _nStudents = results[0].length;
        _nProfessors = results[1].length;
        _nClasses = results[2].length;
      });
    } catch (_) {
      // Stats are decorative; the dashboard works without them.
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _navigate(String label) {
    final Widget? screen = switch (label) {
      'Students' => const StudentsScreen(),
      'Professors' => const ProfessorsScreen(),
      'Rooms' => const RoomsScreen(),
      'Disciplines' => const DisciplinesScreen(),
      'Attendance' => const AttendanceScreen(),
      'Classes' => const ClassesScreen(),
      'Users' => const UsersScreen(),
      'Courses' => const CoursesScreen(),
      'Reports' => const ReportsScreen(),
      'Schedule' || 'My Schedule' || 'Generate Schedule' => const ScheduleScreen(),
      _ => null,
    };
    if (screen == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$label — coming soon'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(6)),
            child: const Text('academia.',
                style: TextStyle(
                    color: Brand.blue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
          ),
          const SizedBox(width: 10),
          const Text('Academia360', style: TextStyle(fontSize: 15)),
        ]),
        actions: [
          if (_user != null)
            Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Text(_user!.fullName.split(' ').first,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(width: 6),
                Text(_user!.role.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ]),
            )),
          IconButton(
              icon: const Icon(Icons.logout, size: 20),
              tooltip: 'Sign out',
              onPressed: _logout),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Error loading user'))
              : _buildBody(_user!),
    );
  }

  Widget _buildBody(User user) {
    final items = _menuItemsForRole(user.role);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Brand.blue, Brand.blueLight],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good day, ${user.fullName.split(' ').first}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Academia Profissional Prof. Albino de Matos · ${user.role.toUpperCase()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            )),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.school, color: Colors.white, size: 30),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _StatTile(
              icon: Icons.people_alt_outlined,
              label: 'Students',
              value: _nStudents,
              color: Brand.blue)),
          const SizedBox(width: 12),
          Expanded(child: _StatTile(
              icon: Icons.school_outlined,
              label: 'Professors',
              value: _nProfessors,
              color: const Color(0xFF0CA678))),
          const SizedBox(width: 12),
          Expanded(child: _StatTile(
              icon: Icons.groups_outlined,
              label: 'Classes',
              value: _nClasses,
              color: const Color(0xFFE8590C))),
        ]),
        const SizedBox(height: 28),
        const Text('Modules',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Brand.ink)),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.1,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _ModuleCard(
            icon: items[i].$1,
            label: items[i].$2,
            color: items[i].$3,
            onTap: () => _navigate(items[i].$2),
          ),
        ),
        const SizedBox(height: 28),
        Center(child: Text(
            'Academia360 · Erasmus+ Project · Prof. Albino de Matos',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400))),
      ]),
    );
  }

  List<(IconData, String, Color)> _menuItemsForRole(String role) {
    const all = [
      (Icons.people_alt_outlined, 'Students', Brand.blue),
      (Icons.school_outlined, 'Professors', Color(0xFF0CA678)),
      (Icons.groups_outlined, 'Classes', Color(0xFFE8590C)),
      (Icons.layers_outlined, 'Courses', Color(0xFF0B7285)),
      (Icons.menu_book_outlined, 'Disciplines', Color(0xFF7048E8)),
      (Icons.meeting_room_outlined, 'Rooms', Color(0xFF087F5B)),
      (Icons.calendar_month_outlined, 'Schedule', Brand.blue),
      (Icons.auto_awesome_outlined, 'Generate Schedule', Color(0xFFE03131)),
      (Icons.fingerprint, 'Attendance', Color(0xFFD6336C)),
      (Icons.bar_chart_outlined, 'Reports', Color(0xFF5C3D2E)),
      (Icons.manage_accounts_outlined, 'Users', Color(0xFF495057)),
    ];
    const secretary = [
      (Icons.people_alt_outlined, 'Students', Brand.blue),
      (Icons.groups_outlined, 'Classes', Color(0xFFE8590C)),
      (Icons.calendar_month_outlined, 'Schedule', Brand.blue),
      (Icons.fingerprint, 'Attendance', Color(0xFFD6336C)),
      (Icons.bar_chart_outlined, 'Reports', Color(0xFF5C3D2E)),
    ];
    const professor = [
      (Icons.calendar_month_outlined, 'My Schedule', Brand.blue),
      (Icons.fingerprint, 'Attendance', Color(0xFFD6336C)),
      (Icons.bar_chart_outlined, 'Reports', Color(0xFF5C3D2E)),
    ];
    const director = [
      (Icons.calendar_month_outlined, 'Schedule', Brand.blue),
      (Icons.people_alt_outlined, 'Students', Brand.blue),
      (Icons.school_outlined, 'Professors', Color(0xFF0CA678)),
      (Icons.fingerprint, 'Attendance', Color(0xFFD6336C)),
      (Icons.bar_chart_outlined, 'Reports', Color(0xFF5C3D2E)),
    ];
    return switch (role) {
      'admin' => all,
      'secretary' => secretary,
      'professor' => professor,
      'director' => director,
      _ => professor,
    };
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ModuleCard({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 22, color: color),
              ),
              const Spacer(),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Brand.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                Text('Open', style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward, size: 10, color: color),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}


class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? value;
  final Color color;
  const _StatTile({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          value == null
              ? SizedBox(width: 28, height: 16,
                  child: LinearProgressIndicator(
                      color: color.withOpacity(0.4),
                      backgroundColor: const Color(0xFFF0F0F0)))
              : Text('$value', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(
              fontSize: 11, color: Colors.grey.shade600)),
        ]),
      ]),
    );
  }
}
