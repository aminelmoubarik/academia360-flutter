import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/ui.dart';
import '../services/api_service.dart';

class ScheduleApprovalScreen extends StatefulWidget {
  const ScheduleApprovalScreen({super.key});

  @override
  State<ScheduleApprovalScreen> createState() => _ScheduleApprovalScreenState();
}

class _ScheduleApprovalScreenState extends State<ScheduleApprovalScreen> {
  List<dynamic> _groups = [];
  bool _loading = true;
  String? _error;

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
      final groups = await ApiService.getPendingScheduleApprovals();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  String _date(dynamic value) {
    final text = value?.toString() ?? '';
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _openDetails(dynamic group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleApprovalDetailsScreen(group: group),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprovação de horários'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Brand.blue, Brand.blueLight]),
            ),
          ),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _groups.isEmpty
                  ? const EmptyView(
                      icon: Icons.verified_outlined,
                      message: 'Não há horários pendentes de aprovação.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: c.line),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Brand.blue.withValues(alpha: c.isDark ? 0.18 : 0.09),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.rule_folder_outlined, color: Brand.blue),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Horários em rascunho', style: TextStyle(color: c.ink, fontWeight: FontWeight.w900, fontSize: 17)),
                                const SizedBox(height: 4),
                                Text('Reveja os horários gerados pelo Admin antes de os disponibilizar como aprovados.', style: TextStyle(color: c.muted, fontSize: 13)),
                              ])),
                              Tag(text: '${_groups.length} pendente(s)', color: Brand.blue),
                            ]),
                          ),
                          const SizedBox(height: 18),
                          for (final group in _groups) ...[
                            _ApprovalGroupCard(
                              group: group,
                              startDate: _date(group['start_date']),
                              endDate: _date(group['end_date']),
                              sessions: _asInt(group['sessions_count']),
                              disciplines: _asInt(group['disciplines_count']),
                              professors: _asInt(group['professors_count']),
                              rooms: _asInt(group['rooms_count']),
                              onOpen: () => _openDetails(group),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class _ApprovalGroupCard extends StatelessWidget {
  final dynamic group;
  final String startDate;
  final String endDate;
  final int sessions;
  final int disciplines;
  final int professors;
  final int rooms;
  final VoidCallback onOpen;

  const _ApprovalGroupCard({
    required this.group,
    required this.startDate,
    required this.endDate,
    required this.sessions,
    required this.disciplines,
    required this.professors,
    required this.rooms,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Brand.warn.withValues(alpha: c.isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.pending_actions_outlined, color: Brand.warn),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(group['class_name']?.toString() ?? 'Turma', style: TextStyle(color: c.ink, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 3),
                Text('${group['course_name'] ?? ''} · ${group['school_year'] ?? ''}', style: TextStyle(color: c.muted, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Tag(text: '$sessions sessões', color: Brand.blue),
                  Tag(text: '$disciplines disciplinas', color: Brand.teal),
                  Tag(text: '$professors professores', color: Brand.ok),
                  Tag(text: '$rooms salas', color: Brand.violet),
                ]),
              ])),
              Icon(Icons.chevron_right_rounded, color: c.faint),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.date_range_outlined, size: 16, color: c.muted),
              const SizedBox(width: 6),
              Expanded(child: Text('$startDate → $endDate', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700, fontSize: 12.5))),
              const Tag(text: 'Rascunho', color: Brand.warn),
            ]),
          ]),
        ),
      ),
    );
  }
}

class ScheduleApprovalDetailsScreen extends StatefulWidget {
  final dynamic group;
  const ScheduleApprovalDetailsScreen({super.key, required this.group});

  @override
  State<ScheduleApprovalDetailsScreen> createState() => _ScheduleApprovalDetailsScreenState();
}

class _ScheduleApprovalDetailsScreenState extends State<ScheduleApprovalDetailsScreen> {
  List<dynamic> _details = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  String get _startDate => _date(widget.group['start_date']);
  String get _endDate => _date(widget.group['end_date']);
  int get _classId => widget.group['class_id'] is int
      ? widget.group['class_id'] as int
      : int.parse(widget.group['class_id'].toString());

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  String _date(dynamic value) {
    final text = value?.toString() ?? '';
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  String _time(dynamic value) {
    final text = value?.toString() ?? '';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final details = await ApiService.getScheduleApprovalDetails(
        classId: _classId,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      setState(() {
        _details = details;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _approve() async {
    final confirmed = await _confirm(
      title: 'Aprovar horário?',
      message: 'As sessões em rascunho desta turma passarão para aprovado.',
      action: 'Aprovar',
      color: Brand.ok,
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final result = await ApiService.approveScheduleBatch(
        classId: _classId,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (!mounted) return;
      AppFeedback.success(context, result['message']?.toString() ?? 'Horário aprovado.');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _submitting = false;
      });
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar horário'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Motivo interno',
            hintText: 'Ex.: conflito com disponibilidade, sala incorreta…',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Brand.danger),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            icon: const Icon(Icons.close),
            label: const Text('Rejeitar'),
          ),
        ],
      ),
    );
    if (reason == null) return;

    setState(() => _submitting = true);
    try {
      final result = await ApiService.rejectScheduleBatch(
        classId: _classId,
        startDate: _startDate,
        endDate: _endDate,
        reason: reason,
      );
      if (!mounted) return;
      AppFeedback.success(context, result['message']?.toString() ?? 'Horário rejeitado.');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _submitting = false;
      });
    }
  }

  Future<bool?> _confirm({required String title, required String message, required String action, required Color color}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final items = <dynamic>[];
    String? lastDate;
    for (final detail in _details) {
      final currentDate = _date(detail['schedule_date']);
      if (currentDate != lastDate) {
        items.add(currentDate);
        lastDate = currentDate;
      }
      items.add(detail);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rever horário')),
      bottomNavigationBar: _loading || _details.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting ? null : _reject,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Rejeitar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Brand.ok),
                      onPressed: _submitting ? null : _approve,
                      icon: _submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded),
                      label: Text(_submitting ? 'A guardar…' : 'Aprovar'),
                    ),
                  ),
                ]),
              ),
            ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadDetails)
              : _details.isEmpty
                  ? const EmptyView(icon: Icons.event_available_outlined, message: 'Este horário já não tem sessões em rascunho.')
                  : Column(children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                        color: c.surface,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.group['class_name']?.toString() ?? 'Turma', style: TextStyle(color: c.ink, fontWeight: FontWeight.w900, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text('${widget.group['course_name'] ?? ''} · $_startDate → $_endDate', style: TextStyle(color: c.muted, fontSize: 13)),
                          const SizedBox(height: 10),
                          const Tag(text: 'Pendente de aprovação', color: Brand.warn),
                        ]),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final item = items[index];
                            if (item is String) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 2),
                                child: Row(children: [
                                  const Icon(Icons.calendar_today, size: 13, color: Brand.blue),
                                  const SizedBox(width: 6),
                                  Text(item, style: const TextStyle(fontWeight: FontWeight.w900, color: Brand.blue)),
                                  const SizedBox(width: 10),
                                  const Expanded(child: Divider()),
                                ]),
                              );
                            }

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(13),
                                child: Row(children: [
                                  Container(width: 4, height: 58, decoration: BoxDecoration(color: Brand.warn, borderRadius: BorderRadius.circular(4))),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(item['discipline_name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.ink, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text('${item['professor_name'] ?? ''} · ${item['room_name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 13)),
                                  ])),
                                  Text('${_time(item['start_time'])}–${_time(item['end_time'])}', style: const TextStyle(fontWeight: FontWeight.w900, color: Brand.blue)),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
    );
  }
}
