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
import 'admin_config_screen.dart';

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
    } catch (_) {}
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showUserProfile(User user) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: Brand.heroGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_outline, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Perfil da sessão')),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileLine(label: 'Nome', value: user.fullName),
              _ProfileLine(label: 'Email', value: user.email),
              _ProfileLine(label: 'Perfil', value: _roleLabel(user.role)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Terminar sessão'),
          ),
        ],
      ),
    );
  }

  void _navigate(String key) {
    final Widget? screen = switch (key) {
      'students' => const StudentsScreen(),
      'professors' => const ProfessorsScreen(),
      'rooms' => const RoomsScreen(),
      'disciplines' => const DisciplinesScreen(),
      'attendance' => const AttendanceScreen(),
      'classes' => const ClassesScreen(),
      'users' => const UsersScreen(),
      'courses' => const CoursesScreen(),
      'reports' => const ReportsScreen(),
      'configuration' => const AdminConfigScreen(),
      'schedule' || 'my_schedule' || 'generate_schedule' => const ScheduleScreen(),
      _ => null,
    };
    if (screen == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$key — em breve'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 20,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Brand.blueSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Brand.blue.withValues(alpha: 0.14)),
            ),
            child: const Text('academia360',
                style: TextStyle(
                    color: Brand.blue,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6)),
          ),
          const SizedBox(width: 14),
          const Text('Painel', style: TextStyle(fontSize: 15)),
        ]),
        actions: [
          if (_user != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _UserMenuButton(
                user: _user!,
                roleLabel: _roleLabel(_user!.role),
                canOpenConfiguration: ['admin', 'director', 'secretary'].contains(_user!.role),
                onProfile: () => _showUserProfile(_user!),
                onConfiguration: () => _navigate('configuration'),
                onLogout: _logout,
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Brand.line),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Não foi possível carregar o utilizador'))
              : _buildBody(_user!),
    );
  }

  String _roleLabel(String role) {
    return switch (role) {
      'admin' => 'Administrador',
      'director' => 'Diretor',
      'secretary' => 'Secretaria',
      'professor' => 'Professor',
      _ => role,
    };
  }

  Widget _buildBody(User user) {
    final items = _menuItemsForRole(user.role);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Brand.blueSoft.withValues(alpha: 0.48), Brand.bg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _HeroPanel(user: user, roleLabel: _roleLabel(user.role)),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 760;
            final tiles = [
              _StatTile(icon: Icons.people_alt_outlined, label: 'Estudantes', value: _nStudents, color: Brand.blue),
              _StatTile(icon: Icons.school_outlined, label: 'Professores', value: _nProfessors, color: Brand.ok),
              _StatTile(icon: Icons.groups_outlined, label: 'Turmas', value: _nClasses, color: Brand.warn),
            ];
            if (narrow) {
              return Column(children: [
                for (final t in tiles) ...[t, const SizedBox(height: 12)],
              ]);
            }
            return Row(children: [
              for (var i = 0; i < tiles.length; i++) ...[
                Expanded(child: tiles[i]),
                if (i != tiles.length - 1) const SizedBox(width: 12),
              ]
            ]);
          }),
          const SizedBox(height: 30),
          Row(children: [
            const Text('Módulos',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Brand.ink)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Brand.blueSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('${items.length} disponíveis',
                  style: const TextStyle(fontSize: 11, color: Brand.blue, fontWeight: FontWeight.w900)),
            ),
          ]),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.08,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _ModuleCard(
              icon: items[i].$1,
              label: items[i].$2,
              color: items[i].$4,
              onTap: () => _navigate(items[i].$3),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              'Academia360 · Projeto Erasmus+ · Prof. Albino de Matos',
              style: TextStyle(fontSize: 11, color: Brand.muted.withValues(alpha: 0.65)),
            ),
          ),
        ]),
      ),
    );
  }

  List<(IconData, String, String, Color)> _menuItemsForRole(String role) {
    const all = [
      (Icons.people_alt_outlined, 'Estudantes', 'students', Brand.blue),
      (Icons.school_outlined, 'Professores', 'professors', Brand.ok),
      (Icons.groups_outlined, 'Turmas', 'classes', Brand.warn),
      (Icons.layers_outlined, 'Cursos', 'courses', Color(0xFF0B7285)),
      (Icons.menu_book_outlined, 'Disciplinas', 'disciplines', Color(0xFF7048E8)),
      (Icons.meeting_room_outlined, 'Salas', 'rooms', Color(0xFF087F5B)),
      (Icons.calendar_month_outlined, 'Horários', 'schedule', Brand.blue),
      (Icons.auto_awesome_outlined, 'Gerar horário', 'generate_schedule', Color(0xFFE03131)),
      (Icons.fingerprint, 'Assiduidade', 'attendance', Color(0xFFD6336C)),
      (Icons.bar_chart_outlined, 'Relatórios', 'reports', Color(0xFF5C3D2E)),
      (Icons.settings_outlined, 'Configuração', 'configuration', Color(0xFF1A1A2E)),
      (Icons.manage_accounts_outlined, 'Utilizadores', 'users', Color(0xFF495057)),
    ];
    const secretary = [
      (Icons.people_alt_outlined, 'Estudantes', 'students', Brand.blue),
      (Icons.groups_outlined, 'Turmas', 'classes', Brand.warn),
      (Icons.calendar_month_outlined, 'Horários', 'schedule', Brand.blue),
      (Icons.fingerprint, 'Assiduidade', 'attendance', Color(0xFFD6336C)),
      (Icons.bar_chart_outlined, 'Relatórios', 'reports', Color(0xFF5C3D2E)),
      (Icons.settings_outlined, 'Configuração', 'configuration', Color(0xFF1A1A2E)),
    ];
    const professor = [
      (Icons.calendar_month_outlined, 'O meu horário', 'my_schedule', Brand.blue),
      (Icons.fingerprint, 'Assiduidade', 'attendance', Color(0xFFD6336C)),
      (Icons.bar_chart_outlined, 'Relatórios', 'reports', Color(0xFF5C3D2E)),
    ];
    const director = [
      (Icons.calendar_month_outlined, 'Horários', 'schedule', Brand.blue),
      (Icons.people_alt_outlined, 'Estudantes', 'students', Brand.blue),
      (Icons.school_outlined, 'Professores', 'professors', Brand.ok),
      (Icons.fingerprint, 'Assiduidade', 'attendance', Color(0xFFD6336C)),
      (Icons.bar_chart_outlined, 'Relatórios', 'reports', Color(0xFF5C3D2E)),
      (Icons.settings_outlined, 'Configuração', 'configuration', Color(0xFF1A1A2E)),
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

class _UserMenuButton extends StatelessWidget {
  final User user;
  final String roleLabel;
  final bool canOpenConfiguration;
  final VoidCallback onProfile;
  final VoidCallback onConfiguration;
  final VoidCallback onLogout;

  const _UserMenuButton({
    required this.user,
    required this.roleLabel,
    required this.canOpenConfiguration,
    required this.onProfile,
    required this.onConfiguration,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Abrir menu do utilizador',
      elevation: 12,
      offset: const Offset(0, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            onProfile();
            break;
          case 'configuration':
            onConfiguration();
            break;
          case 'logout':
            onLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: 260,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Brand.blueSoft,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Brand.blue, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Brand.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'profile',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.person_outline),
            title: Text('Ver perfil'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (canOpenConfiguration)
          const PopupMenuItem<String>(
            value: 'configuration',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.settings_outlined),
              title: Text('Configuração'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.logout, color: Brand.danger),
            title: Text('Terminar sessão'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Brand.line),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(user.fullName.split(' ').first,
              style: const TextStyle(color: Brand.ink, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Brand.blueSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(roleLabel.toUpperCase(),
                style: const TextStyle(color: Brand.blue, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.expand_more, size: 17, color: Brand.muted),
        ]),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: Brand.muted, fontWeight: FontWeight.w800)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Brand.ink, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final User user;
  final String roleLabel;
  const _HeroPanel({required this.user, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: Brand.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Brand.blue.withValues(alpha: 0.20), blurRadius: 28, offset: const Offset(0, 16)),
        ],
      ),
      child: Stack(children: [
        Positioned(top: -95, right: -80, child: _HeroGlow(size: 260, opacity: 0.15)),
        Positioned(bottom: -130, left: -70, child: _HeroGlow(size: 300, opacity: 0.13)),
        Padding(
          padding: const EdgeInsets.all(26),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                  ),
                  child: const Text('ACADEMIA PROFISSIONAL',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 14),
                Text('Olá, ${user.fullName.split(' ').first}',
                    style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 5),
                Text('Prof. Albino de Matos · $roleLabel',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.74), fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 15),
                const Text(
                  'Gerencie utilizadores, turmas, horários e assiduidade a partir de uma única plataforma.',
                  style: TextStyle(color: Colors.white, fontSize: 13, height: 1.45),
                ),
              ]),
            ),
            const SizedBox(width: 20),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: const Icon(Icons.school_outlined, color: Colors.white, size: 36),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _HeroGlow extends StatelessWidget {
  final double size;
  final double opacity;
  const _HeroGlow({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
      );
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ModuleCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Brand.line),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.white, 0.35)!]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  const Spacer(),
                  Text(label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Brand.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('Abrir', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward, size: 11, color: color),
                  ]),
                ],
              ),
            ),
          ]),
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
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Brand.line),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          value == null
              ? SizedBox(
                  width: 38,
                  height: 16,
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(999),
                    color: color.withValues(alpha: 0.5),
                    backgroundColor: Brand.blueSoft,
                  ),
                )
              : Text('$value', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Brand.muted, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}
