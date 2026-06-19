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
  List<dynamic> _records = [];
  List<dynamic> _filtered = [];
  List<dynamic> _classes = [];
  List<dynamic> _disciplines = [];
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _alerts = {};

  User? _user;
  bool _loading = true;
  bool _exportingPdf = false;
  bool _exportingExcel = false;
  String? _error;
  String _search = '';

  DateTimeRange? _range;
  int? _classId;
  int? _disciplineId;
  String? _punchType;
  String? _punchMethod;
  String? _syncFilter;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() => _user = user);
    await _loadOptions();
    await _load();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        ApiService.getClasses(),
        ApiService.getDisciplines(),
      ]);
      if (!mounted) return;
      setState(() {
        _classes = results[0];
        _disciplines = results[1];
      });
    } catch (_) {
      // The screen can still work without filter options.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dashboardDate = _formatDate(_range?.end ?? DateTime.now());
      final results = await Future.wait([
        ApiService.getAttendance(
          startDate: _range == null ? null : _formatDate(_range!.start),
          endDate: _range == null ? null : _formatDate(_range!.end),
          classId: _classId,
          disciplineId: _disciplineId,
          punchType: _punchType,
          punchMethod: _punchMethod,
          isSynced: _syncFilter == null ? null : _syncFilter == 'synced',
          limit: 500,
        ),
        ApiService.getAttendanceDashboard(
          date: dashboardDate,
          classId: _classId,
          disciplineId: _disciplineId,
        ),
        ApiService.getAttendanceAlerts(
          date: dashboardDate,
          classId: _classId,
          disciplineId: _disciplineId,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _records = results[0] as List<dynamic>;
        _dashboard = results[1] as Map<String, dynamic>;
        _alerts = results[2] as Map<String, dynamic>;
        _loading = false;
      });
      _applySearch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applySearch() {
    final query = _search.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = List<dynamic>.from(_records);
        return;
      }

      _filtered = _records.where((record) {
        final values = [
          record['student_name'],
          record['student_number'],
          record['card_uid'],
          record['class_name'],
          record['course_code'],
          record['discipline_name'],
          record['punch_method'],
          record['punch_type'],
        ].whereType<Object>().map((item) => item.toString().toLowerCase());
        return values.any((value) => value.contains(query));
      }).toList();
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    return text.length >= 16 ? text.substring(0, 16).replaceAll('T', ' ') : text;
  }

  String _rangeLabel() {
    if (_range == null) return 'Todas as datas';
    return '${_formatDate(_range!.start)} → ${_formatDate(_range!.end)}';
  }

  String _punchLabel(dynamic type) => type == 'in' ? 'Entrada' : 'Saída';

  String _methodLabel(String? value) {
    return switch (value) {
      'nfc' => 'NFC',
      'rfid' => 'RFID',
      'qr' => 'QR Code',
      'barcode' => 'Código de barras',
      'manual' => 'Manual',
      _ => 'Todos os métodos',
    };
  }

  Future<void> _pickRange() async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 3),
      lastDate: DateTime(today.year + 3),
      initialDateRange: _range ?? DateTimeRange(start: today, end: today),
      helpText: 'Selecionar período',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
    );

    if (picked == null || !mounted) return;
    setState(() => _range = picked);
    await _load();
  }

  void _clearFilters() {
    setState(() {
      _range = null;
      _classId = null;
      _disciplineId = null;
      _punchType = null;
      _punchMethod = null;
      _syncFilter = null;
      _search = '';
    });
    _load();
  }


  Future<void> _exportAttendance(String format) async {
    setState(() {
      if (format == 'pdf') {
        _exportingPdf = true;
      } else {
        _exportingExcel = true;
      }
    });

    try {
      await ApiService.downloadAttendanceExport(
        format: format,
        startDate: _range == null ? null : _formatDate(_range!.start),
        endDate: _range == null ? null : _formatDate(_range!.end),
        classId: _classId,
        disciplineId: _disciplineId,
        punchType: _punchType,
        punchMethod: _punchMethod,
        isSynced: _syncFilter == null ? null : _syncFilter == 'synced',
        search: _search,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(format == 'pdf' ? 'PDF exportado com sucesso.' : 'Excel exportado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Brand.danger),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _exportingPdf = false;
        _exportingExcel = false;
      });
    }
  }


  String _classLabel(dynamic item) {
    final name = item['name']?.toString() ?? 'Turma';
    final course = item['course_code']?.toString();
    return course == null || course.isEmpty ? name : '$name · $course';
  }

  String _disciplineLabel(dynamic item) {
    final code = item['code']?.toString();
    final name = item['name']?.toString() ?? 'Disciplina';
    return code == null || code.isEmpty ? name : '$code · $name';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assiduidade'),
        actions: [
          if (AppPermissions.canUsePunchTerminal(_user?.role)) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendancePunchScreen()),
              ).then((_) => _load()),
              icon: const Icon(Icons.contactless_outlined, size: 18),
              label: const Text('Picagem'),
            ),
            const SizedBox(width: 10),
          ],
        ],
        backgroundColor: c.surface,
        foregroundColor: c.ink,
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
            colors: c.isDark
                ? [c.surface, c.bg]
                : [Colors.white, Brand.blueSoft.withValues(alpha: 0.42), c.bg],
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
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
                      children: [
                        _DashboardSummary(
                          dashboard: _dashboard,
                          filteredCount: _filtered.length,
                          selectedDate: _formatDate(_range?.end ?? DateTime.now()),
                        ),
                        const SizedBox(height: 14),
                        _AbsenteeismAlertsCard(alerts: _alerts),
                        const SizedBox(height: 14),
                        _FiltersCard(
                          rangeLabel: _rangeLabel(),
                          classes: _classes,
                          disciplines: _disciplines,
                          classId: _classId,
                          disciplineId: _disciplineId,
                          punchType: _punchType,
                          punchMethod: _punchMethod,
                          syncFilter: _syncFilter,
                          classLabel: _classLabel,
                          disciplineLabel: _disciplineLabel,
                          methodLabel: _methodLabel,
                          onSearchChanged: (value) {
                            _search = value;
                            _applySearch();
                          },
                          onPickRange: _pickRange,
                          onClearRange: () {
                            setState(() => _range = null);
                            _load();
                          },
                          onClassChanged: (value) {
                            setState(() => _classId = value);
                            _load();
                          },
                          onDisciplineChanged: (value) {
                            setState(() => _disciplineId = value);
                            _load();
                          },
                          onPunchTypeChanged: (value) {
                            setState(() => _punchType = value);
                            _load();
                          },
                          onPunchMethodChanged: (value) {
                            setState(() => _punchMethod = value);
                            _load();
                          },
                          onSyncChanged: (value) {
                            setState(() => _syncFilter = value);
                            _load();
                          },
                          onClearFilters: _clearFilters,
                        ),
                        const SizedBox(height: 12),
                        _AttendanceExportActions(
                          exportingPdf: _exportingPdf,
                          exportingExcel: _exportingExcel,
                          enabled: _filtered.isNotEmpty,
                          onExportPdf: () => _exportAttendance('pdf'),
                          onExportExcel: () => _exportAttendance('excel'),
                        ),
                        const SizedBox(height: 8),
                        ResultCount(count: _filtered.length, noun: 'registos encontrados'),
                        const SizedBox(height: 6),
                        if (_filtered.isEmpty)
                          const SizedBox(
                            height: 280,
                            child: EmptyView(
                              icon: Icons.fingerprint,
                              message: 'Sem registos de assiduidade para os filtros selecionados',
                            ),
                          )
                        else
                          ..._filtered.map((record) => _AttendanceRecordCard(
                                record: record,
                                formatDateTime: _formatDateTime,
                                punchLabel: _punchLabel,
                              )),
                      ],
                    ),
                  ),
      ),
    );
  }
}


class _AttendanceExportActions extends StatelessWidget {
  final bool exportingPdf;
  final bool exportingExcel;
  final bool enabled;
  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;

  const _AttendanceExportActions({
    required this.exportingPdf,
    required this.exportingExcel,
    required this.enabled,
    required this.onExportPdf,
    required this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ios_share_outlined, color: c.muted, size: 18),
              const SizedBox(width: 8),
              Text(
                'Exportar relatório filtrado',
                style: TextStyle(color: c.ink, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: enabled && !exportingPdf ? onExportPdf : null,
                icon: exportingPdf
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('PDF'),
              ),
              FilledButton.icon(
                onPressed: enabled && !exportingExcel ? onExportExcel : null,
                icon: exportingExcel
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.table_chart_outlined, size: 18),
                label: const Text('Excel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardSummary extends StatelessWidget {
  final Map<String, dynamic> dashboard;
  final int filteredCount;
  final String selectedDate;

  const _DashboardSummary({
    required this.dashboard,
    required this.filteredCount,
    required this.selectedDate,
  });

  int _value(String key) {
    final raw = dashboard[key];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = dashboard['alerts'];
    final alertCount = alerts is List ? alerts.length : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Dashboard de assiduidade',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 10),
            Tag(text: selectedDate, color: Brand.blue),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 850;
            final cards = [
              _MetricCard(
                icon: Icons.groups_outlined,
                label: 'Estudantes',
                value: _value('total_students').toString(),
                color: Brand.blue,
              ),
              _MetricCard(
                icon: Icons.check_circle_outline,
                label: 'Presentes',
                value: _value('present_students').toString(),
                color: Brand.ok,
              ),
              _MetricCard(
                icon: Icons.warning_amber_rounded,
                label: 'Ausentes',
                value: _value('absent_students').toString(),
                color: Brand.danger,
              ),
              _MetricCard(
                icon: Icons.notifications_active_outlined,
                label: 'Alertas',
                value: alertCount.toString(),
                color: const Color(0xFFF08C00),
              ),
              _MetricCard(
                icon: Icons.filter_alt_outlined,
                label: 'Registos filtrados',
                value: filteredCount.toString(),
                color: const Color(0xFF7048E8),
              ),
            ];

            if (compact) {
              return Column(
                children: cards.map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: card,
                )).toList(),
              );
            }

            return Row(
              children: cards.map((card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: card,
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: c.isDark ? 0.08 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: c.ink)),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _AbsenteeismAlertsCard extends StatelessWidget {
  final Map<String, dynamic> alerts;

  const _AbsenteeismAlertsCard({required this.alerts});

  List<dynamic> _list(String key) {
    final raw = alerts[key];
    return raw is List ? raw : const [];
  }

  String _date(dynamic value) => value?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final todayAbsentees = _list('today_absentees');
    final recurrent = _list('recurrent_absences');
    final classAlerts = _list('class_alerts');
    final hasAlerts = todayAbsentees.isNotEmpty || recurrent.isNotEmpty || classAlerts.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: Brand.warn.withValues(alpha: c.isDark ? 0.06 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Brand.warn.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.notification_important_outlined, color: Brand.warn, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alertas de absentismo', style: TextStyle(fontWeight: FontWeight.w900, color: c.ink)),
                    Text(
                      "Dia ${_date(alerts['date'])} · período desde ${_date(alerts['period_start'])}",
                      style: TextStyle(fontSize: 12, color: c.muted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Tag(text: hasAlerts ? 'Atenção' : 'Sem alertas', color: hasAlerts ? Brand.warn : Brand.ok),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasAlerts)
            Text(
              'Não existem alertas para os filtros atuais.',
              style: TextStyle(color: c.muted, fontWeight: FontWeight.w700),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 850;
                final children = [
                  _AlertColumn(
                    title: 'Sem entrada hoje',
                    icon: Icons.event_busy_outlined,
                    color: Brand.danger,
                    items: todayAbsentees,
                    empty: 'Todos têm entrada registada.',
                    builder: (item) => _studentAlertLine(item),
                  ),
                  _AlertColumn(
                    title: 'Ausências recorrentes',
                    icon: Icons.trending_down_outlined,
                    color: Brand.warn,
                    items: recurrent,
                    empty: 'Sem padrões críticos nos últimos dias.',
                    builder: (item) {
                      final days = item['missing_days']?.toString() ?? '0';
                      return '${_studentAlertLine(item)} · $days dias';
                    },
                  ),
                  _AlertColumn(
                    title: 'Turmas com alertas',
                    icon: Icons.groups_2_outlined,
                    color: const Color(0xFF7048E8),
                    items: classAlerts,
                    empty: 'Sem turmas em risco.',
                    builder: (item) {
                      final name = item['class_name']?.toString() ?? 'Turma';
                      final missing = item['missing_today']?.toString() ?? '0';
                      final total = item['total_students']?.toString() ?? '0';
                      return '$name · $missing/$total sem entrada';
                    },
                  ),
                ];

                if (narrow) {
                  return Column(
                    children: children.map((child) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: child,
                    )).toList(),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children.map((child) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: child,
                    ),
                  )).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  String _studentAlertLine(dynamic item) {
    final name = item['student_name']?.toString() ?? 'Estudante';
    final number = item['student_number']?.toString();
    final className = item['class_name']?.toString();
    final parts = [
      name,
      if (number != null && number.isNotEmpty) '#$number',
      if (className != null && className.isNotEmpty) className,
    ];
    return parts.join(' · ');
  }
}

class _AlertColumn extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<dynamic> items;
  final String empty;
  final String Function(dynamic item) builder;

  const _AlertColumn({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.empty,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: TextStyle(color: c.ink, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(empty, style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w700))
          else
            ...items.take(5).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                builder(item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.ink, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            )),
          if (items.length > 5)
            Text('+${items.length - 5} restantes', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  final String rangeLabel;
  final List<dynamic> classes;
  final List<dynamic> disciplines;
  final int? classId;
  final int? disciplineId;
  final String? punchType;
  final String? punchMethod;
  final String? syncFilter;
  final String Function(dynamic item) classLabel;
  final String Function(dynamic item) disciplineLabel;
  final String Function(String? value) methodLabel;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPickRange;
  final VoidCallback onClearRange;
  final ValueChanged<int?> onClassChanged;
  final ValueChanged<int?> onDisciplineChanged;
  final ValueChanged<String?> onPunchTypeChanged;
  final ValueChanged<String?> onPunchMethodChanged;
  final ValueChanged<String?> onSyncChanged;
  final VoidCallback onClearFilters;

  const _FiltersCard({
    required this.rangeLabel,
    required this.classes,
    required this.disciplines,
    required this.classId,
    required this.disciplineId,
    required this.punchType,
    required this.punchMethod,
    required this.syncFilter,
    required this.classLabel,
    required this.disciplineLabel,
    required this.methodLabel,
    required this.onSearchChanged,
    required this.onPickRange,
    required this.onClearRange,
    required this.onClassChanged,
    required this.onDisciplineChanged,
    required this.onPunchTypeChanged,
    required this.onPunchMethodChanged,
    required this.onSyncChanged,
    required this.onClearFilters,
  });

  int _id(dynamic item) {
    final raw = item['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c.line),
    );

    InputDecoration decoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19, color: Brand.blue),
      prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      fillColor: c.surface,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: Brand.blue, width: 1.6),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_outlined, color: Brand.blue),
              const SizedBox(width: 8),
              Text('Filtros de assiduidade', style: TextStyle(fontWeight: FontWeight.w900, color: c.ink)),
              const Spacer(),
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                label: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: onSearchChanged,
            decoration: decoration('Pesquisar estudante, turma, cartão ou disciplina', Icons.search),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 250,
                child: OutlinedButton.icon(
                  onPressed: onPickRange,
                  icon: const Icon(Icons.date_range_outlined, size: 18),
                  label: Text(rangeLabel, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: _FilterDropdown<int?>(
                  value: classId,
                  decoration: decoration('Turma', Icons.groups_2_outlined),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Todas as turmas')),
                    ...classes.map((item) => DropdownMenuItem<int?>(
                          value: _id(item),
                          child: Text(classLabel(item), overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: onClassChanged,
                ),
              ),
              SizedBox(
                width: 270,
                child: _FilterDropdown<int?>(
                  value: disciplineId,
                  decoration: decoration('Disciplina', Icons.menu_book_outlined),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Todas as disciplinas')),
                    ...disciplines.map((item) => DropdownMenuItem<int?>(
                          value: _id(item),
                          child: Text(disciplineLabel(item), overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: onDisciplineChanged,
                ),
              ),
              SizedBox(
                width: 190,
                child: _FilterDropdown<String?>(
                  value: punchType,
                  decoration: decoration('Tipo', Icons.login_outlined),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Entrada e saída')),
                    DropdownMenuItem<String?>(value: 'in', child: Text('Entrada')),
                    DropdownMenuItem<String?>(value: 'out', child: Text('Saída')),
                  ],
                  onChanged: onPunchTypeChanged,
                ),
              ),
              SizedBox(
                width: 230,
                child: _FilterDropdown<String?>(
                  value: punchMethod,
                  decoration: decoration('Método', Icons.contactless_outlined),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todos os métodos')),
                    ...['nfc', 'rfid', 'qr', 'barcode', 'manual'].map((method) => DropdownMenuItem<String?>(
                          value: method,
                          child: Text(methodLabel(method)),
                        )),
                  ],
                  onChanged: onPunchMethodChanged,
                ),
              ),
              SizedBox(
                width: 220,
                child: _FilterDropdown<String?>(
                  value: syncFilter,
                  decoration: decoration('Sincronização', Icons.cloud_done_outlined),
                  items: const [
                    DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                    DropdownMenuItem<String?>(value: 'synced', child: Text('Sincronizados')),
                    DropdownMenuItem<String?>(value: 'offline', child: Text('Offline')),
                  ],
                  onChanged: onSyncChanged,
                ),
              ),
            ],
          ),
          if (rangeLabel != 'Todas as datas') ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onClearRange,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Remover período'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _FilterDropdown<T> extends StatelessWidget {
  final T? value;
  final InputDecoration decoration;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.decoration,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InputDecorator(
      decoration: decoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.muted),
          style: TextStyle(color: c.ink, fontWeight: FontWeight.w700, fontSize: 14),
          selectedItemBuilder: (context) => items.map((item) {
            final child = item.child;
            return Align(
              alignment: Alignment.centerLeft,
              child: DefaultTextStyle.merge(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: child,
              ),
            );
          }).toList(),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _AttendanceRecordCard extends StatelessWidget {
  final dynamic record;
  final String Function(dynamic value) formatDateTime;
  final String Function(dynamic type) punchLabel;

  const _AttendanceRecordCard({
    required this.record,
    required this.formatDateTime,
    required this.punchLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isIn = record['punch_type'] == 'in';
    final color = isIn ? Brand.ok : Brand.danger;
    final isSynced = record['is_synced'] == true || record['is_synced'] == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(isIn ? Icons.login : Icons.logout, color: color, size: 20),
        ),
        title: Text(
          record['student_name'] ?? 'Desconhecido',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (record['student_number'] != null) Tag(text: '#${record['student_number']}'),
              if (record['class_name'] != null) Tag(text: record['class_name'].toString(), color: const Color(0xFF0B7285)),
              if (record['discipline_name'] != null) Tag(text: record['discipline_name'].toString(), color: const Color(0xFF7048E8)),
              Tag(text: punchLabel(record['punch_type']), color: color),
              Tag(text: isSynced ? 'Sincronizado' : 'Offline', color: isSynced ? Brand.ok : const Color(0xFFF08C00)),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatDateTime(record['punch_time']),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            Text(
              record['punch_method']?.toString().toUpperCase() ?? '',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
