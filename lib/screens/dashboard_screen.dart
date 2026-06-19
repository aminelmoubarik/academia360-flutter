import 'package:flutter/material.dart';

import '../core/brand_logo.dart';
import '../core/permissions.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'admin_config_screen.dart';
import 'attendance_punch_screen.dart';
import 'attendance_screen.dart';
import 'audit_logs_screen.dart';
import 'classes_screen.dart';
import 'courses_screen.dart';
import 'disciplines_screen.dart';
import 'justifications_screen.dart';
import 'login_screen.dart';
import 'professors_screen.dart';
import 'reports_screen.dart';
import 'rooms_screen.dart';
import 'schedule_approval_screen.dart';
import 'schedule_screen.dart';
import 'students_screen.dart';
import 'users_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  User? _user;
  bool _loading = true;
  int? _nStudents;
  int? _nProfessors;
  int? _nClasses;
  int? _nPresentToday;
  int? _nAlertsToday;

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
        ApiService.getAttendanceDashboard(),
      ]);
      if (!mounted) return;
      final attendance = results[3] as Map<String, dynamic>;
      setState(() {
        _nStudents = (results[0] as List).length;
        _nProfessors = (results[1] as List).length;
        _nClasses = (results[2] as List).length;
        _nPresentToday = attendance['present_students'] as int?;
        _nAlertsToday = attendance['absent_students'] as int?;
      });
    } catch (_) {
      // Dashboard stats are useful, but should not block access to the app.
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigate(String key) {
    final role = _user?.role;
    if (!AppPermissions.canOpenFeature(role, key)) {
      AppFeedback.error(context, 'O seu perfil não tem permissão para abrir esta área.');
      return;
    }
    final Widget? screen = switch (key) {
      'students' => const StudentsScreen(),
      'professors' => const ProfessorsScreen(),
      'rooms' => const RoomsScreen(),
      'disciplines' => const DisciplinesScreen(),
      'attendance_punch' => const AttendancePunchScreen(),
      'attendance' => const AttendanceScreen(),
      'justifications' => const JustificationsScreen(),
      'classes' => const ClassesScreen(),
      'users' => const UsersScreen(),
      'audit_logs' => const AuditLogsScreen(),
      'courses' => const CoursesScreen(),
      'reports' => const ReportsScreen(),
      'configuration' => const AdminConfigScreen(),
      'schedule' || 'my_schedule' || 'generate_schedule' => const ScheduleScreen(),
      'schedule_approval' => const ScheduleApprovalScreen(),
      _ => null,
    };
    if (screen == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) => _loadStats());
  }

  void _showUserProfile(User user) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Perfil da sessão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileLine(label: 'Nome', value: user.fullName),
            _ProfileLine(label: 'Email', value: user.email),
            _ProfileLine(label: 'Perfil', value: _roleLabel(user.role)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Terminar sessão'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
        'admin' => 'Administrador',
        'director' => 'Diretor',
        'secretary' => 'Secretaria',
        'professor' => 'Professor',
        _ => role,
      };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = _user;
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      key: _scaffoldKey,
      drawer: (!isWide && user != null)
          ? _AppDrawer(
              user: user,
              roleLabel: _roleLabel(user.role),
              sections: _navSectionsForRole(user.role),
              onNavigate: (key) {
                Navigator.pop(context);
                if (key == 'dashboard') return;
                _navigate(key);
              },
            )
          : null,
      appBar: AppBar(
        toolbarHeight: 70,
        titleSpacing: 20,
        leading: !isWide
            ? IconButton(
                tooltip: 'Abrir menu',
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: Brand.blue.withValues(alpha: c.isDark ? 0.18 : 0.09),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Brand.blue.withValues(alpha: 0.16)),
            ),
            child: const AcademiaCompactMark(size: 20),
          ),
          const SizedBox(width: 14),
          Text('Painel', style: TextStyle(fontSize: 15, color: c.ink)),
        ]),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _UserMenuButton(
                user: user,
                roleLabel: _roleLabel(user.role),
                canOpenConfiguration: AppPermissions.canManageConfiguration(user.role),
                onProfile: () => _showUserProfile(user),
                onConfiguration: () => _navigate('configuration'),
                onPunch: () => _navigate('attendance_punch'),
                onLogout: _logout,
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.line),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? Center(child: Text('Não foi possível carregar o utilizador', style: TextStyle(color: c.muted)))
              : Row(children: [
                  if (isWide)
                    _SideNavigation(
                      user: user,
                      roleLabel: _roleLabel(user.role),
                      sections: _navSectionsForRole(user.role),
                      onNavigate: (key) {
                        if (key == 'dashboard') return;
                        _navigate(key);
                      },
                    ),
                  Expanded(child: _DashboardHome(user: user, roleLabel: _roleLabel(user.role), stats: _stats(), onNavigate: _navigate)),
                ]),
    );
  }

  _DashboardStats _stats() => _DashboardStats(
        students: _nStudents,
        professors: _nProfessors,
        classes: _nClasses,
        presentToday: _nPresentToday,
        alertsToday: _nAlertsToday,
      );
}

List<_NavSection> _navSectionsForRole(String role) {
  final normalized = AppPermissions.normalize(role);

  _NavSection section(String title, List<_NavItem> items) {
    return _NavSection(
      title,
      items.where((item) => AppPermissions.canOpenFeature(normalized, item.key)).toList(),
    );
  }

  final sections = [
    section('Núcleo do projeto', [
      _NavItem('attendance_punch', 'Terminal de picagem', Icons.contactless_outlined, Brand.blue),
      _NavItem('generate_schedule', 'Gerador de horários', Icons.auto_awesome_motion_outlined, Brand.danger),
      _NavItem('schedule_approval', 'Aprovação de horários', Icons.verified_outlined, Brand.ok),
      _NavItem('schedule', 'Horários', Icons.calendar_today_outlined, Brand.blue),
    ]),
    section('Assiduidade', [
      _NavItem('attendance', 'Registos de assiduidade', Icons.fingerprint, Brand.pink),
      _NavItem('justifications', 'Justificações de faltas', Icons.fact_check_outlined, Brand.blue),
      _NavItem('reports', 'Relatórios', Icons.bar_chart_outlined, Brand.amber),
    ]),
    section('Gestão académica', [
      _NavItem('students', 'Estudantes', Icons.people_alt_outlined, Brand.blue),
      _NavItem('professors', 'Professores', Icons.school_outlined, Brand.ok),
      _NavItem('classes', 'Turmas', Icons.groups_outlined, Brand.warn),
      _NavItem('courses', 'Cursos', Icons.layers_outlined, Brand.teal),
      _NavItem('disciplines', 'Disciplinas', Icons.menu_book_outlined, Brand.violet),
      _NavItem('rooms', 'Salas', Icons.meeting_room_outlined, Brand.green),
    ]),
    section('Configuração', [
      _NavItem('configuration', 'Calendário, cargas e disponibilidade', Icons.settings_outlined, const Color(0xFF5B6472)),
    ]),
    section('Administração', [
      _NavItem('users', 'Utilizadores', Icons.manage_accounts_outlined, const Color(0xFF7C8698)),
      _NavItem('audit_logs', 'Auditoria', Icons.security_outlined, Brand.violet),
    ]),
  ];

  return sections.where((section) => section.items.isNotEmpty).toList();
}

class _DashboardStats {
  final int? students;
  final int? professors;
  final int? classes;
  final int? presentToday;
  final int? alertsToday;

  const _DashboardStats({
    required this.students,
    required this.professors,
    required this.classes,
    required this.presentToday,
    required this.alertsToday,
  });
}

class _NavSection {
  final String title;
  final List<_NavItem> items;
  const _NavSection(this.title, this.items);
}

class _NavItem {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _NavItem(this.key, this.label, this.icon, this.color);
}

class _SideNavigation extends StatelessWidget {
  final User user;
  final String roleLabel;
  final List<_NavSection> sections;
  final ValueChanged<String> onNavigate;

  const _SideNavigation({
    required this.user,
    required this.roleLabel,
    required this.sections,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: 292,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Brand.blue.withValues(alpha: 0.10), Brand.blueSoft.withValues(alpha: 0.70)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Brand.blue.withValues(alpha: 0.13)),
              ),
              child: const AcademiaWordmark(size: 27, showSchoolText: true, show360: false),
            ),
          ),
          _NavTile(
            item: const _NavItem('dashboard', 'Painel geral', Icons.dashboard_customize_outlined, Brand.blue),
            selected: true,
            onTap: () => onNavigate('dashboard'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
              children: [
                for (final section in sections) ...[
                  _SectionHeader(section.title),
                  for (final item in section.items) _NavTile(item: item, onTap: () => onNavigate(item.key)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: _MiniUserCard(user: user, roleLabel: roleLabel),
          ),
        ]),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final User user;
  final String roleLabel;
  final List<_NavSection> sections;
  final ValueChanged<String> onNavigate;

  const _AppDrawer({
    required this.user,
    required this.roleLabel,
    required this.sections,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Drawer(
      backgroundColor: c.surface,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: const AcademiaWordmark(size: 28, showSchoolText: true, show360: false),
          ),
          _NavTile(
            item: const _NavItem('dashboard', 'Painel geral', Icons.dashboard_customize_outlined, Brand.blue),
            selected: true,
            onTap: () => onNavigate('dashboard'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final section in sections) ...[
                  _SectionHeader(section.title),
                  for (final item in section.items) _NavTile(item: item, onTap: () => onNavigate(item.key)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: _MiniUserCard(user: user, roleLabel: roleLabel),
          ),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 7),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: c.faint,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.onTap, this.selected = false});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final active = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: active
              ? Brand.blue.withValues(alpha: c.isDark ? 0.18 : 0.09)
              : _hover
                  ? widget.item.color.withValues(alpha: c.isDark ? 0.14 : 0.07)
                  : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: active ? Brand.blue.withValues(alpha: 0.18) : Colors.transparent,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            dense: true,
            minLeadingWidth: 30,
            visualDensity: const VisualDensity(vertical: -1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: widget.item.color.withValues(alpha: c.isDark ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(widget.item.icon, color: widget.item.color, size: 18),
            ),
            title: Text(
              widget.item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.ink, fontWeight: active ? FontWeight.w900 : FontWeight.w700, fontSize: 13),
            ),
            trailing: active ? const Icon(Icons.circle, size: 7, color: Brand.blue) : null,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

class _MiniUserCard extends StatelessWidget {
  final User user;
  final String roleLabel;
  const _MiniUserCard({required this.user, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Brand.blue.withValues(alpha: c.isDark ? 0.24 : 0.10),
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
            style: const TextStyle(color: Brand.blue, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.ink, fontWeight: FontWeight.w900, fontSize: 12.5)),
          Text(roleLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontWeight: FontWeight.w700, fontSize: 11)),
        ])),
      ]),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final User user;
  final String roleLabel;
  final _DashboardStats stats;
  final ValueChanged<String> onNavigate;

  const _DashboardHome({
    required this.user,
    required this.roleLabel,
    required this.stats,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c.isDark ? [c.surface, c.bg] : [Colors.white, Brand.blueSoft.withValues(alpha: 0.48), c.bg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _HeroPanel(user: user, roleLabel: roleLabel, onPunch: () => onNavigate('attendance_punch')),
          const SizedBox(height: 18),
          _StatsWrap(stats: stats),
          const SizedBox(height: 28),
          _FocusModules(role: user.role, onNavigate: onNavigate),
          const SizedBox(height: 28),
          _ProjectMap(role: user.role, onNavigate: onNavigate),
          const SizedBox(height: 30),
          Center(
            child: Text(
              'Academia360 · Projeto Erasmus+ · Prof. Albino de Matos',
              style: TextStyle(fontSize: 11, color: c.muted.withValues(alpha: 0.7)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatsWrap extends StatelessWidget {
  final _DashboardStats stats;
  const _StatsWrap({required this.stats});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(icon: Icons.people_alt_outlined, label: 'Estudantes', value: stats.students, color: Brand.blue),
      _StatTile(icon: Icons.school_outlined, label: 'Professores', value: stats.professors, color: Brand.ok),
      _StatTile(icon: Icons.groups_outlined, label: 'Turmas', value: stats.classes, color: Brand.warn),
      _StatTile(icon: Icons.check_circle_outline, label: 'Presentes hoje', value: stats.presentToday, color: Brand.teal),
      _StatTile(icon: Icons.warning_amber_outlined, label: 'Alertas hoje', value: stats.alertsToday, color: Brand.danger),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 760) {
        return Column(children: [for (final t in tiles) ...[t, const SizedBox(height: 12)]]);
      }
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (final t in tiles) SizedBox(width: 220, child: t),
      ]);
    });
  }
}

class _FocusModules extends StatelessWidget {
  final String role;
  final ValueChanged<String> onNavigate;
  const _FocusModules({required this.role, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Módulos principais', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: c.ink)),
        const SizedBox(width: 10),
        _Pill(text: 'Fluxo principal da plataforma', color: Brand.blue),
      ]),
      const SizedBox(height: 14),
      LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 860;
        final cards = [
          if (AppPermissions.canUsePunchTerminal(role))
            _LargeActionCard(
              icon: Icons.contactless_outlined,
              title: 'Picagem NFC/RFID',
              subtitle: 'Terminal para cartões, QR, código de barras e registo manual com timestamp.',
              color: Brand.blue,
              actionLabel: 'Abrir terminal',
              onTap: () => onNavigate('attendance_punch'),
            ),
          if (AppPermissions.canGenerateSchedule(role))
            _LargeActionCard(
              icon: Icons.auto_awesome_motion_outlined,
              title: 'Geração automática de horários',
              subtitle: 'Disponibilidade docente, calendário escolar, salas práticas e conflitos.',
              color: Brand.danger,
              actionLabel: 'Gerar horários',
              onTap: () => onNavigate('generate_schedule'),
            )
          else if (AppPermissions.canApproveSchedule(role))
            _LargeActionCard(
              icon: Icons.verified_outlined,
              title: 'Aprovação de horários',
              subtitle: 'Reveja rascunhos gerados e aprove ou rejeite antes da publicação.',
              color: Brand.ok,
              actionLabel: 'Rever pendentes',
              onTap: () => onNavigate('schedule_approval'),
            )
          else if (AppPermissions.canViewSchedule(role))
            _LargeActionCard(
              icon: Icons.calendar_today_outlined,
              title: 'Consulta de horários',
              subtitle: 'Acompanhe horários por turma, professor e ocupação de salas.',
              color: Brand.danger,
              actionLabel: 'Ver horários',
              onTap: () => onNavigate('schedule'),
            ),
        ];
        if (narrow) return Column(children: [for (final c in cards) ...[c, const SizedBox(height: 14)]]);
        return Row(children: [for (final c in cards) Expanded(child: Padding(padding: const EdgeInsets.only(right: 14), child: c))]);
      }),
    ]);
  }
}

class _ProjectMap extends StatelessWidget {
  final String role;
  final ValueChanged<String> onNavigate;
  const _ProjectMap({required this.role, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final groups = [
      _MapGroup('Gestão académica', 'Dados base usados pelos dois módulos.', Icons.account_tree_outlined, Brand.teal, [
        _MapLink('Estudantes', 'students'),
        _MapLink('Professores', 'professors'),
        _MapLink('Turmas', 'classes'),
        _MapLink('Cursos', 'courses'),
        _MapLink('Disciplinas', 'disciplines'),
        _MapLink('Salas', 'rooms'),
      ]),
      _MapGroup('Configuração operacional', 'Parâmetros necessários para gerar horários.', Icons.tune_outlined, Brand.violet, [
        _MapLink('Calendário escolar', 'configuration'),
        _MapLink('Disponibilidade docente', 'configuration'),
        _MapLink('Cargas horárias', 'configuration'),
        _MapLink('Atribuições professor-disciplina', 'configuration'),
      ]),
      _MapGroup('Relatórios e administração', 'Consulta, auditoria e gestão de acesso.', Icons.insights_outlined, Brand.amber, [
        _MapLink('Relatórios', 'reports'),
        _MapLink('Registos de assiduidade', 'attendance'),
        _MapLink('Justificações', 'justifications'),
        _MapLink('Aprovação de horários', 'schedule_approval'),
        _MapLink('Utilizadores', 'users'),
        _MapLink('Auditoria', 'audit_logs'),
      ]),
    ];

    final visibleGroups = groups
        .map((group) => _MapGroup(
              group.title,
              group.subtitle,
              group.icon,
              group.color,
              group.links.where((link) => AppPermissions.canOpenFeature(role, link.key)).toList(),
            ))
        .where((group) => group.links.isNotEmpty)
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Mapa da aplicação', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: c.ink)),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;
        if (narrow) return Column(children: [for (final g in visibleGroups) ...[_MapGroupCard(group: g, onNavigate: onNavigate), const SizedBox(height: 12)]]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final g in visibleGroups) Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: _MapGroupCard(group: g, onNavigate: onNavigate))),
        ]);
      }),
    ]);
  }
}

class _MapGroup {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_MapLink> links;
  const _MapGroup(this.title, this.subtitle, this.icon, this.color, this.links);
}

class _MapLink {
  final String label;
  final String key;
  const _MapLink(this.label, this.key);
}

class _MapGroupCard extends StatelessWidget {
  final _MapGroup group;
  final ValueChanged<String> onNavigate;
  const _MapGroupCard({required this.group, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: c.isDark ? 0.2 : 0.035), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: group.color.withValues(alpha: c.isDark ? 0.20 : 0.10), borderRadius: BorderRadius.circular(15)),
            child: Icon(group.icon, size: 20, color: group.color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(group.title, style: TextStyle(fontWeight: FontWeight.w900, color: c.ink))),
        ]),
        const SizedBox(height: 8),
        Text(group.subtitle, style: TextStyle(color: c.muted, fontSize: 12.5, height: 1.35)),
        const SizedBox(height: 12),
        for (final link in group.links)
          InkWell(
            onTap: () => onNavigate(link.key),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
              child: Row(children: [
                Icon(Icons.arrow_right_rounded, color: group.color, size: 20),
                Expanded(child: Text(link.label, style: TextStyle(color: c.ink, fontSize: 13, fontWeight: FontWeight.w700))),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _LargeActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String actionLabel;
  final VoidCallback onTap;

  const _LargeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  State<_LargeActionCard> createState() => _LargeActionCardState();
}

class _LargeActionCardState extends State<_LargeActionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: _hover ? (Matrix4.identity()..translateByDouble(0.0, -4.0, 0.0, 1.0)) : Matrix4.identity(),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.color, Color.lerp(widget.color, Colors.black, 0.28)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: widget.color.withValues(alpha: _hover ? 0.30 : 0.18), blurRadius: _hover ? 30 : 20, offset: const Offset(0, 12))],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.17), borderRadius: BorderRadius.circular(18)),
                child: Icon(widget.icon, color: Colors.white, size: 26),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.85)),
            ]),
            const SizedBox(height: 18),
            Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            Text(widget.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.78), height: 1.35, fontSize: 13)),
            const SizedBox(height: 16),
            _WhitePill(text: widget.actionLabel),
          ]),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
      );
}

class _WhitePill extends StatelessWidget {
  final String text;
  const _WhitePill({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.24))),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
      );
}

class _UserMenuButton extends StatelessWidget {
  final User user;
  final String roleLabel;
  final bool canOpenConfiguration;
  final VoidCallback onProfile;
  final VoidCallback onConfiguration;
  final VoidCallback onPunch;
  final VoidCallback onLogout;

  const _UserMenuButton({
    required this.user,
    required this.roleLabel,
    required this.canOpenConfiguration,
    required this.onProfile,
    required this.onConfiguration,
    required this.onPunch,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Abrir menu do utilizador',
      elevation: 12,
      color: c.surface,
      offset: const Offset(0, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.line)),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            onProfile();
            break;
          case 'configuration':
            onConfiguration();
            break;
          case 'punch':
            onPunch();
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
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Brand.blue.withValues(alpha: c.isDark ? 0.22 : 0.10),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Brand.blue, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, color: c.ink)),
                Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.muted)),
              ])),
            ]),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'profile', child: ListTile(dense: true, leading: Icon(Icons.person_outline), title: Text('Ver perfil'), contentPadding: EdgeInsets.zero)),
        const PopupMenuItem<String>(value: 'punch', child: ListTile(dense: true, leading: Icon(Icons.contactless_outlined), title: Text('Abrir picagem'), contentPadding: EdgeInsets.zero)),
        if (canOpenConfiguration)
          const PopupMenuItem<String>(value: 'configuration', child: ListTile(dense: true, leading: Icon(Icons.settings_outlined), title: Text('Configuração'), contentPadding: EdgeInsets.zero)),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'logout', child: ListTile(dense: true, leading: Icon(Icons.logout, color: Brand.danger), title: Text('Terminar sessão'), contentPadding: EdgeInsets.zero)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: c.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(user.fullName.split(' ').first, style: TextStyle(color: c.ink, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Brand.blue.withValues(alpha: c.isDark ? 0.18 : 0.10), borderRadius: BorderRadius.circular(999)),
            child: Text(roleLabel.toUpperCase(), style: const TextStyle(color: Brand.blue, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 5),
          Icon(Icons.expand_more, size: 17, color: c.muted),
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
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 72, child: Text(label, style: TextStyle(color: c.muted, fontWeight: FontWeight.w800))),
        Expanded(child: Text(value, style: TextStyle(color: c.ink, fontWeight: FontWeight.w800))),
      ]),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final User user;
  final String roleLabel;
  final VoidCallback onPunch;
  const _HeroPanel({required this.user, required this.roleLabel, required this.onPunch});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: Brand.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Brand.blue.withValues(alpha: 0.28), blurRadius: 30, offset: const Offset(0, 16))],
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
                  child: const Text('ACADEMIA PROFISSIONAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 14),
                Text('Olá, ${user.fullName.split(' ').first}', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 5),
                Text('Prof. Albino de Matos · $roleLabel', style: TextStyle(color: Colors.white.withValues(alpha: 0.74), fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 15),
                const Text('Prioridade do projeto: picagem NFC/RFID e geração automática de horários.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.45)),
                const SizedBox(height: 16),
                if (AppPermissions.canUsePunchTerminal(user.role))
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Brand.blue),
                  onPressed: onPunch,
                  icon: const Icon(Icons.contactless_outlined),
                  label: const Text('Abrir terminal de picagem'),
                ),
              ]),
            ),
            const SizedBox(width: 20),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.24))),
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
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)));
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? value;
  final Color color;
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: c.isDark ? 0.2 : 0.035), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: c.isDark ? 0.20 : 0.09), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          value == null
              ? SizedBox(width: 38, height: 16, child: LinearProgressIndicator(borderRadius: BorderRadius.circular(999), color: color.withValues(alpha: 0.5), backgroundColor: color.withValues(alpha: 0.12)))
              : _CountUp(value: value!, color: color),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: c.muted, fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }
}

class _CountUp extends StatelessWidget {
  final int value;
  final Color color;
  const _CountUp({required this.value, required this.color});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: value),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => Text('$v', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      );
}
