import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'students_screen.dart';
import 'schedule_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? _user;
  bool _loading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academia360'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(_user!.fullName,
                    style: const TextStyle(fontSize: 14)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Error loading user'))
              : _buildDashboard(_user!),
    );
  }

  Widget _buildDashboard(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(user),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildMenuForRole(user.role),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(User user) {
    return Container(
      width: double.infinity,
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade700,
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome, ${user.fullName}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Role: ${user.role.toUpperCase()}',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuForRole(String role) {
    final items = _menuItemsForRole(role);
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _DashboardCard(
        icon: items[index]['icon'] as IconData,
        label: items[index]['label'] as String,
        color: items[index]['color'] as Color,
        onTap: () => _navigate(items[index]['label'] as String),
      ),
    );
  }

  void _navigate(String label) {
    switch (label) {
      case 'Students':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StudentsScreen()));
        break;
      case 'Schedule':
      case 'My Schedule':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ScheduleScreen()));
        break;
      case 'Generate Schedule':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ScheduleScreen()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label — coming soon'),
            duration: const Duration(seconds: 1),
          ),
        );
    }
  }

  List<Map<String, dynamic>> _menuItemsForRole(String role) {
    final adminItems = [
      {'icon': Icons.people, 'label': 'Students', 'color': Colors.blue},
      {'icon': Icons.school, 'label': 'Professors', 'color': Colors.green},
      {'icon': Icons.class_, 'label': 'Classes', 'color': Colors.orange},
      {'icon': Icons.book, 'label': 'Disciplines', 'color': Colors.purple},
      {'icon': Icons.meeting_room, 'label': 'Rooms', 'color': Colors.teal},
      {'icon': Icons.calendar_today, 'label': 'Schedule', 'color': Colors.indigo},
      {'icon': Icons.auto_awesome, 'label': 'Generate Schedule', 'color': Colors.deepOrange},
      {'icon': Icons.fingerprint, 'label': 'Attendance', 'color': Colors.red},
      {'icon': Icons.bar_chart, 'label': 'Reports', 'color': Colors.brown},
      {'icon': Icons.manage_accounts, 'label': 'Users', 'color': Colors.blueGrey},
    ];
    final secretaryItems = [
      {'icon': Icons.people, 'label': 'Students', 'color': Colors.blue},
      {'icon': Icons.class_, 'label': 'Classes', 'color': Colors.orange},
      {'icon': Icons.calendar_today, 'label': 'Schedule', 'color': Colors.indigo},
      {'icon': Icons.fingerprint, 'label': 'Attendance', 'color': Colors.red},
    ];
    final professorItems = [
      {'icon': Icons.calendar_today, 'label': 'My Schedule', 'color': Colors.indigo},
      {'icon': Icons.fingerprint, 'label': 'Attendance', 'color': Colors.red},
    ];
    final directorItems = [
      {'icon': Icons.calendar_today, 'label': 'Schedule', 'color': Colors.indigo},
      {'icon': Icons.bar_chart, 'label': 'Reports', 'color': Colors.brown},
      {'icon': Icons.people, 'label': 'Students', 'color': Colors.blue},
      {'icon': Icons.school, 'label': 'Professors', 'color': Colors.green},
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

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
