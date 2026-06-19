import 'package:flutter/material.dart';

import '../core/permissions.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'attendance_screen.dart';
import 'audit_logs_screen.dart';
import 'schedule_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  User? _user;
  bool _loading = true;
  String? _error;

  List<dynamic> _classes = [];
  Map<String, dynamic> _attendanceDashboard = {};
  Map<String, dynamic> _attendanceAlerts = {};
  Map<String, dynamic>? _auditSummary;
  List<dynamic> _pendingApprovals = [];

  String? _attendanceStartDate;
  String? _attendanceEndDate;
  int? _attendanceClassId;
  int? _scheduleClassId;
  String _scheduleStatus = 'approved';
  String? _exporting;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AuthService.getCurrentUser();
      final classes = await ApiService.getClasses();
      final dashboard = await ApiService.getAttendanceDashboard();
      final alerts = await ApiService.getAttendanceAlerts();

      Map<String, dynamic>? auditSummary;
      if (AppPermissions.canViewAuditLogs(user?.role)) {
        try {
          auditSummary = await ApiService.getAuditSummary(days: 7);
        } catch (_) {
          auditSummary = null;
        }
      }

      List<dynamic> pendingApprovals = [];
      if (AppPermissions.canApproveSchedule(user?.role)) {
        try {
          pendingApprovals = await ApiService.getPendingScheduleApprovals();
        } catch (_) {
          pendingApprovals = [];
        }
      }

      if (!mounted) return;
      final uniqueClasses = _uniqueClasses(classes);
      final validClassIds = uniqueClasses
          .map((item) => _intValue(item['id']))
          .whereType<int>()
          .toSet();

      setState(() {
        _user = user;
        _classes = uniqueClasses;
        _attendanceDashboard = dashboard;
        _attendanceAlerts = alerts;
        _auditSummary = auditSummary;
        _pendingApprovals = pendingApprovals;
        if (_attendanceClassId != null && !validClassIds.contains(_attendanceClassId)) {
          _attendanceClassId = null;
        }
        if (_scheduleClassId == null || !validClassIds.contains(_scheduleClassId)) {
          _scheduleClassId = uniqueClasses.isNotEmpty ? _intValue(uniqueClasses.first['id']) : null;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int? _intValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  int _intFromMap(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _classLabel(dynamic item) {
    final name = item['name']?.toString() ?? item['class_name']?.toString() ?? 'Turma';
    final course = item['course_code']?.toString();
    if (course == null || course.isEmpty) return name;
    return '$name · $course';
  }

  List<dynamic> _uniqueClasses(List<dynamic> classes) {
    final seen = <int>{};
    final unique = <dynamic>[];
    for (final item in classes) {
      final id = _intValue(item['id']);
      if (id == null || seen.contains(id)) continue;
      seen.add(id);
      unique.add(item);
    }
    return unique;
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final current = DateTime.tryParse(start ? (_attendanceStartDate ?? '') : (_attendanceEndDate ?? '')) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      helpText: start ? 'Data inicial' : 'Data final',
    );
    if (picked == null || !mounted) return;
    final value = picked.toIso8601String().split('T').first;
    setState(() {
      if (start) {
        _attendanceStartDate = value;
      } else {
        _attendanceEndDate = value;
      }
    });
  }

  Future<void> _exportAttendance(String format) async {
    setState(() => _exporting = 'attendance_$format');
    try {
      await ApiService.downloadAttendanceExport(
        format: format,
        startDate: _attendanceStartDate,
        endDate: _attendanceEndDate,
        classId: _attendanceClassId,
      );
      if (!mounted) return;
      AppFeedback.success(context, 'Relatório de assiduidade exportado.');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _exporting = null);
    }
  }

  Future<void> _exportSchedule(String format) async {
    final classId = _scheduleClassId;
    if (classId == null) {
      AppFeedback.error(context, 'Selecione uma turma para exportar o horário.');
      return;
    }

    setState(() => _exporting = 'schedule_$format');
    try {
      await ApiService.downloadScheduleExport(
        classId: classId,
        format: format,
        status: _scheduleStatus,
      );
      if (!mounted) return;
      AppFeedback.success(context, 'Horário exportado.');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _exporting = null);
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final role = _user?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de relatórios'),
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Brand.blue, Brand.blueLight, Brand.amber]),
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: c.isDark
                ? [c.surface, c.bg]
                : [Colors.white, Brand.blueSoft.withValues(alpha: 0.44), c.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        _ReportsHero(onOpenAttendance: () => _open(const AttendanceScreen()), onOpenSchedule: () => _open(const ScheduleScreen())),
                        const SizedBox(height: 18),
                        _SummaryGrid(
                          attendanceDashboard: _attendanceDashboard,
                          alerts: _attendanceAlerts,
                          auditSummary: _auditSummary,
                          pendingApprovals: _pendingApprovals.length,
                          intFromMap: _intFromMap,
                        ),
                        const SizedBox(height: 22),
                        LayoutBuilder(builder: (context, constraints) {
                          final narrow = constraints.maxWidth < 950;
                          final children = [
                            _AttendanceExportCard(
                              classes: _classes,
                              selectedClassId: _attendanceClassId,
                              startDate: _attendanceStartDate,
                              endDate: _attendanceEndDate,
                              exporting: _exporting,
                              classLabel: _classLabel,
                              intValue: _intValue,
                              onClassChanged: (value) => setState(() => _attendanceClassId = value),
                              onPickStart: () => _pickDate(start: true),
                              onPickEnd: () => _pickDate(start: false),
                              onClear: () => setState(() {
                                _attendanceStartDate = null;
                                _attendanceEndDate = null;
                                _attendanceClassId = null;
                              }),
                              onPdf: () => _exportAttendance('pdf'),
                              onExcel: () => _exportAttendance('excel'),
                              onOpen: () => _open(const AttendanceScreen()),
                            ),
                            _ScheduleExportCard(
                              classes: _classes,
                              selectedClassId: _scheduleClassId,
                              status: _scheduleStatus,
                              exporting: _exporting,
                              classLabel: _classLabel,
                              intValue: _intValue,
                              onClassChanged: (value) => setState(() => _scheduleClassId = value),
                              onStatusChanged: (value) => setState(() => _scheduleStatus = value ?? 'approved'),
                              onPdf: () => _exportSchedule('pdf'),
                              onExcel: () => _exportSchedule('excel'),
                              onOpen: () => _open(const ScheduleScreen()),
                            ),
                          ];
                          if (narrow) {
                            return Column(children: [for (final child in children) ...[child, const SizedBox(height: 16)]]);
                          }
                          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: children[0]),
                            const SizedBox(width: 16),
                            Expanded(child: children[1]),
                          ]);
                        }),
                        const SizedBox(height: 22),
                        _ReportModules(
                          canViewAudit: AppPermissions.canViewAuditLogs(role),
                          onOpenAttendance: () => _open(const AttendanceScreen()),
                          onOpenSchedule: () => _open(const ScheduleScreen()),
                          onOpenAudit: () => _open(const AuditLogsScreen()),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _ReportsHero extends StatelessWidget {
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenSchedule;

  const _ReportsHero({required this.onOpenAttendance, required this.onOpenSchedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Brand.blueDeep, Brand.blue, Brand.blueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Brand.blue.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 780;
        final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Text(
              'DIREÇÃO · SECRETARIA · ADMINISTRAÇÃO',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Centro de relatórios Academia360',
            style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Consolida assiduidade, horários, alertas, exportações e auditoria num único ponto de consulta.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.84), fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.icon(
              onPressed: onOpenAttendance,
              icon: const Icon(Icons.fingerprint, size: 18),
              label: const Text('Ver assiduidade'),
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Brand.blue),
            ),
            OutlinedButton.icon(
              onPressed: onOpenSchedule,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: const Text('Ver horários'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
              ),
            ),
          ]),
        ]);

        final icon = Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 42),
        );

        if (narrow) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [icon, const SizedBox(height: 18), text]);
        }
        return Row(children: [Expanded(child: text), const SizedBox(width: 20), icon]);
      }),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final Map<String, dynamic> attendanceDashboard;
  final Map<String, dynamic> alerts;
  final Map<String, dynamic>? auditSummary;
  final int pendingApprovals;
  final int Function(Map<String, dynamic>, String) intFromMap;

  const _SummaryGrid({
    required this.attendanceDashboard,
    required this.alerts,
    required this.auditSummary,
    required this.pendingApprovals,
    required this.intFromMap,
  });

  @override
  Widget build(BuildContext context) {
    final todayAbsentees = alerts['today_absentees'];
    final recurrent = alerts['recurrent_absences'];
    final auditTotal = auditSummary?['total_events'] ?? auditSummary?['total'] ?? 0;
    final tiles = [
      _MetricCard(
        label: 'Presentes hoje',
        value: intFromMap(attendanceDashboard, 'present_students').toString(),
        icon: Icons.check_circle_outline,
        color: Brand.teal,
      ),
      _MetricCard(
        label: 'Ausentes hoje',
        value: intFromMap(attendanceDashboard, 'absent_students').toString(),
        icon: Icons.warning_amber_outlined,
        color: Brand.danger,
      ),
      _MetricCard(
        label: 'Alertas ativos',
        value: '${(todayAbsentees is List ? todayAbsentees.length : 0) + (recurrent is List ? recurrent.length : 0)}',
        icon: Icons.notifications_active_outlined,
        color: Brand.warn,
      ),
      _MetricCard(
        label: 'Horários pendentes',
        value: pendingApprovals.toString(),
        icon: Icons.verified_outlined,
        color: Brand.ok,
      ),
      if (auditSummary != null)
        _MetricCard(
          label: 'Eventos de auditoria',
          value: auditTotal.toString(),
          icon: Icons.security_outlined,
          color: Brand.violet,
        ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth < 720 ? constraints.maxWidth : 210.0;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (final tile in tiles) SizedBox(width: width, child: tile),
      ]);
    });
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: c.isDark ? 0.18 : 0.04), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: c.ink, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }
}

class _AttendanceExportCard extends StatelessWidget {
  final List<dynamic> classes;
  final int? selectedClassId;
  final String? startDate;
  final String? endDate;
  final String? exporting;
  final String Function(dynamic) classLabel;
  final int? Function(dynamic) intValue;
  final ValueChanged<int?> onClassChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClear;
  final VoidCallback onPdf;
  final VoidCallback onExcel;
  final VoidCallback onOpen;

  const _AttendanceExportCard({
    required this.classes,
    required this.selectedClassId,
    required this.startDate,
    required this.endDate,
    required this.exporting,
    required this.classLabel,
    required this.intValue,
    required this.onClassChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClear,
    required this.onPdf,
    required this.onExcel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      icon: Icons.fingerprint,
      title: 'Relatório de assiduidade',
      subtitle: 'Exporta picagens e filtros principais para Direção ou Secretaria.',
      color: Brand.pink,
      children: [
        _ClassSelect(
          label: 'Turma',
          value: selectedClassId,
          classes: classes,
          classLabel: classLabel,
          intValue: intValue,
          includeAll: true,
          onChanged: onClassChanged,
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _DateButton(label: 'Data inicial', value: startDate ?? 'Todas', onTap: onPickStart)),
          const SizedBox(width: 10),
          Expanded(child: _DateButton(label: 'Data final', value: endDate ?? 'Todas', onTap: onPickEnd)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _ExportButton(label: 'PDF', icon: Icons.picture_as_pdf_outlined, loading: exporting == 'attendance_pdf', onPressed: onPdf),
          _ExportButton(label: 'Excel', icon: Icons.table_chart_outlined, loading: exporting == 'attendance_excel', onPressed: onExcel),
          TextButton.icon(onPressed: onClear, icon: const Icon(Icons.cleaning_services_outlined), label: const Text('Limpar filtros')),
          TextButton.icon(onPressed: onOpen, icon: const Icon(Icons.open_in_new), label: const Text('Abrir registos')),
        ]),
      ],
    );
  }
}

class _ScheduleExportCard extends StatelessWidget {
  final List<dynamic> classes;
  final int? selectedClassId;
  final String status;
  final String? exporting;
  final String Function(dynamic) classLabel;
  final int? Function(dynamic) intValue;
  final ValueChanged<int?> onClassChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onPdf;
  final VoidCallback onExcel;
  final VoidCallback onOpen;

  const _ScheduleExportCard({
    required this.classes,
    required this.selectedClassId,
    required this.status,
    required this.exporting,
    required this.classLabel,
    required this.intValue,
    required this.onClassChanged,
    required this.onStatusChanged,
    required this.onPdf,
    required this.onExcel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      icon: Icons.calendar_month_outlined,
      title: 'Relatório de horários',
      subtitle: 'Exporta horários aprovados, rascunhos ou todos os estados por turma.',
      color: Brand.blue,
      children: [
        _ClassSelect(
          label: 'Turma',
          value: selectedClassId,
          classes: classes,
          classLabel: classLabel,
          intValue: intValue,
          includeAll: false,
          onChanged: onClassChanged,
        ),
        const SizedBox(height: 10),
        _StatusSelect(value: status, onChanged: onStatusChanged),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _ExportButton(label: 'PDF', icon: Icons.picture_as_pdf_outlined, loading: exporting == 'schedule_pdf', onPressed: onPdf),
          _ExportButton(label: 'Excel', icon: Icons.table_chart_outlined, loading: exporting == 'schedule_excel', onPressed: onExcel),
          TextButton.icon(onPressed: onOpen, icon: const Icon(Icons.open_in_new), label: const Text('Abrir horários')),
        ]),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<Widget> children;

  const _ReportCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: c.line),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: c.isDark ? 0.18 : 0.05), blurRadius: 24, offset: const Offset(0, 14))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: c.ink, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(color: c.muted, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ])),
        ]),
        const SizedBox(height: 18),
        ...children,
      ]),
    );
  }
}

class _ClassSelect extends StatelessWidget {
  final String label;
  final int? value;
  final List<dynamic> classes;
  final String Function(dynamic) classLabel;
  final int? Function(dynamic) intValue;
  final bool includeAll;
  final ValueChanged<int?> onChanged;

  const _ClassSelect({
    required this.label,
    required this.value,
    required this.classes,
    required this.classLabel,
    required this.intValue,
    required this.includeAll,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final uniqueClasses = <int, dynamic>{};
    for (final item in classes) {
      final id = intValue(item);
      if (id == null || uniqueClasses.containsKey(id)) continue;
      uniqueClasses[id] = item;
    }
    final safeValue = value != null && uniqueClasses.containsKey(value) ? value : null;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.groups_outlined, size: 19),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c.line)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: safeValue,
          hint: Text(includeAll ? 'Todas as turmas' : 'Selecione uma turma'),
          isExpanded: true,
          items: [
            if (includeAll) const DropdownMenuItem<int?>(value: null, child: Text('Todas as turmas')),
            for (final entry in uniqueClasses.entries)
              DropdownMenuItem<int?>(
                value: entry.key,
                child: Text(classLabel(entry.value), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StatusSelect extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _StatusSelect({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Estado do horário',
        prefixIcon: const Icon(Icons.verified_outlined, size: 19),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c.line)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'approved', child: Text('Apenas aprovados')),
            DropdownMenuItem(value: 'draft', child: Text('Rascunhos')),
            DropdownMenuItem(value: 'all', child: Text('Todos os estados')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Row(children: [
          const Icon(Icons.date_range_outlined, color: Brand.blue, size: 19),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: c.ink, fontSize: 13, fontWeight: FontWeight.w900)),
          ])),
        ]),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;

  const _ExportButton({required this.label, required this.icon, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _ReportModules extends StatelessWidget {
  final bool canViewAudit;
  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenAudit;

  const _ReportModules({
    required this.canViewAudit,
    required this.onOpenAttendance,
    required this.onOpenSchedule,
    required this.onOpenAudit,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final modules = [
      _SmallReportModule(
        title: 'Assiduidade e alertas',
        subtitle: 'Filtros, ausências, picagens, justificações e exportação.',
        icon: Icons.fingerprint,
        color: Brand.pink,
        onTap: onOpenAttendance,
      ),
      _SmallReportModule(
        title: 'Horários e aprovação',
        subtitle: 'Consulta, aprovação pela Direção e exportação por turma.',
        icon: Icons.calendar_today_outlined,
        color: Brand.blue,
        onTap: onOpenSchedule,
      ),
      if (canViewAudit)
        _SmallReportModule(
          title: 'Auditoria',
          subtitle: 'Histórico de ações sensíveis e acessos ao sistema.',
          icon: Icons.security_outlined,
          color: Brand.violet,
          onTap: onOpenAudit,
        ),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Áreas de relatório', style: TextStyle(color: c.ink, fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth < 760 ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;
        return Wrap(spacing: 12, runSpacing: 12, children: [for (final module in modules) SizedBox(width: width, child: module)]);
      }),
    ]);
  }
}

class _SmallReportModule extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallReportModule({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded, color: c.faint),
            ]),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: c.ink, fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: c.muted, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ]),
        ),
      ),
    );
  }
}
