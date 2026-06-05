import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
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

  static const _brandBlue = Color(0xFF1929E9);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigate(String label) {
    Widget? screen;
    switch (label) {
      case 'Students': screen = const StudentsScreen(); break;
      case 'Professors': screen = const ProfessorsScreen(); break;
      case 'Rooms': screen = const RoomsScreen(); break;
      case 'Disciplines': screen = const DisciplinesScreen(); break;
      case 'Attendance': screen = const AttendanceScreen(); break;
      case 'Classes': screen = const ClassesScreen(); break;
      case 'Users': screen = const UsersScreen(); break;
      case 'Courses': screen = const CoursesScreen(); break;
      case 'Reports': screen = const ReportsScreen(); break;
      case 'Schedule':
      case 'My Schedule':
      case 'Generate Schedule':
        screen = const ScheduleScreen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label — coming soon'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'academia.',
                style: TextStyle(
                  color: _brandBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Academia360',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (_user != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Text(
                        _user!.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: _brandBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _user!.fullName.split(' ').first,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _user!.role.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              tooltip: 'Sign out',
              onPressed: _logout,
            ),
          ],
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
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1929E9), Color(0xFF4A5CF0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good day, ${user.fullName.split(' ').first}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Academia Profissional Prof. Albino de Matos · ${user.role.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school,
                      color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Modules',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.05,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _ModuleCard(
              icon: items[index]['icon'] as IconData,
              label: items[index]['label'] as String,
              color: items[index]['color'] as Color,
              onTap: () => _navigate(items[index]['label'] as String),
            ),
          ),
          const SizedBox(height: 32),
          // Footer
          Center(
            child: Text(
              'Academia360 · Erasmus+ Project · Prof. Albino de Matos',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _menuItemsForRole(String role) {
    final adminItems = [
      {'icon': Icons.people_alt_outlined, 'label': 'Students', 'color': const Color(0xFF1929E9)},
      {'icon': Icons.school_outlined, 'label': 'Professors', 'color': const Color(0xFF0CA678)},
      {'icon': Icons.groups_outlined, 'label': 'Classes', 'color': const Color(0xFFE8590C)},
      {'icon': Icons.layers_outlined, 'label': 'Courses', 'color': const Color(0xFF0B7285)},
      {'icon': Icons.menu_book_outlined, 'label': 'Disciplines', 'color': const Color(0xFF7048E8)},
      {'icon': Icons.meeting_room_outlined, 'label': 'Rooms', 'color': const Color(0xFF087F5B)},
      {'icon': Icons.calendar_month_outlined, 'label': 'Schedule', 'color': const Color(0xFF1929E9)},
      {'icon': Icons.auto_awesome_outlined, 'label': 'Generate Schedule', 'color': const Color(0xFFE03131)},
      {'icon': Icons.fingerprint, 'label': 'Attendance', 'color': const Color(0xFFD6336C)},
      {'icon': Icons.bar_chart_outlined, 'label': 'Reports', 'color': const Color(0xFF5C3D2E)},
      {'icon': Icons.manage_accounts_outlined, 'label': 'Users', 'color': const Color(0xFF495057)},
    ];
    final secretaryItems = [
      {'icon': Icons.people_alt_outlined, 'label': 'Students', 'color': const Color(0xFF1929E9)},
      {'icon': Icons.groups_outlined, 'label': 'Classes', 'color': const Color(0xFFE8590C)},
      {'icon': Icons.calendar_month_outlined, 'label': 'Schedule', 'color': const Color(0xFF1929E9)},
      {'icon': Icons.fingerprint, 'label': 'Attendance', 'color': const Color(0xFFD6336C)},
      {'icon': Icons.bar_chart_outlined, 'label': 'Reports', 'color': const Color(0xFF5C3D2E)},
    ];
    final professorItems = [
      {'icon': Icons.calendar_month_outlined, 'label': 'My Schedule', 'color': const Color(0xFF1929E9)},
      {'icon': Icons.fingerprint, 'label': 'Attendance', 'color': const Color(0xFFD6336C)},
      {'icon': Icons.bar_chart_outlined, 'label': 'Reports', 'color': const Color(0xFF5C3D2E)},
    ];
    final directorItems = [
      {'icon': Icons.calendar_month_outlined, 'label': 'Schedule', 'color': const Color(0xFF1929E9)},
      {'icon': Icons.people_alt_outlined, 'label': 'Students', 'color': const Color(0xFF1929E9)},
      {'icon': Icons.school_outlined, 'label': 'Professors', 'color': const Color(0xFF0CA678)},
      {'icon': Icons.fingerprint, 'label': 'Attendance', 'color': const Color(0xFFD6336C)},
      {'icon': Icons.bar_chart_outlined, 'label': 'Reports', 'color': const Color(0xFF5C3D2E)},
    ];
    switch (role) {
      case 'admin': return adminItems;
      case 'secretary': return secretaryItems;
      case 'professor': return professorItems;
      case 'director': return directorItems;
      default: return professorItems;
    }
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

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
            border: Border.all(color: Colors.grey.shade100),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward, size: 10, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
