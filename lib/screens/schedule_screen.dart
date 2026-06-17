import 'package:flutter/material.dart';
import '../core/ui.dart';
import '../main.dart';
import '../services/api_service.dart';

const _primary = Brand.blue;
const _orange = Color(0xFFE8590C);

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<dynamic> _classes = [];
  List<dynamic> _schedule = [];
  dynamic _selectedClass;
  bool _loadingClasses = true;
  bool _loadingSchedule = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadClasses(); }

  Future<void> _loadClasses() async {
    setState(() { _loadingClasses = true; _error = null; });
    try {
      final data = await ApiService.getClasses();
      setState(() { _classes = data; _loadingClasses = false; });
    } catch (e) { setState(() { _error = e.toString(); _loadingClasses = false; }); }
  }

  Future<void> _loadSchedule(int classId) async {
    setState(() { _loadingSchedule = true; _schedule = []; _error = null; });
    try {
      final data = await ApiService.getScheduleByClass(classId);
      setState(() { _schedule = data; _loadingSchedule = false; });
    } catch (e) { setState(() { _error = e.toString(); _loadingSchedule = false; }); }
  }

  String _t(dynamic v) {
    final s = v?.toString() ?? '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'approved': return const Color(0xFF0CA678);
      case 'draft': return _orange;
      case 'cancelled': return const Color(0xFFE03131);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'approved': return 'Aprovado';
      case 'draft': return 'Rascunho';
      case 'cancelled': return 'Cancelado';
      default: return s ?? '';
    }
  }

  void _openGenerator() {
    if (_selectedClass == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => GenerateScheduleScreen(selectedClass: _selectedClass),
    )).then((_) {
      if (_selectedClass != null) _loadSchedule(_selectedClass['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horários')),
      body: _loadingClasses ? const LoadingView()
          : _error != null ? ErrorView(message: _error!, onRetry: _loadClasses)
          : Column(children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<dynamic>(
                  decoration: const InputDecoration(labelText: 'Selecionar turma'),
                  initialValue: _selectedClass,
                  isExpanded: true,
                  items: _classes.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c['name']} — ${c['course_name']} (${c['school_year']})',
                        overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) {
                    setState(() => _selectedClass = v);
                    if (v != null) _loadSchedule(v['id']);
                  },
                ),
              ),
              if (_loadingSchedule)
                const Expanded(child: LoadingView())
              else if (_selectedClass == null)
                const Expanded(child: EmptyView(
                  icon: Icons.calendar_month_outlined,
                  message: 'Selecione uma turma para ver o horário'))
              else if (_schedule.isEmpty)
                Expanded(child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('Esta turma ainda não tem horário', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text('Antes de guardar, use a pré-visualização para confirmar as condições.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: _orange),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Gerar horário'),
                      onPressed: _openGenerator,
                    ),
                  ],
                )))
              else
                Expanded(child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_schedule.length} sessões',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        TextButton.icon(
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Regenerar'),
                          onPressed: _openGenerator,
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: Builder(builder: (context) {
                    final items = <dynamic>[];
                    String? lastDate;
                    for (final s in _schedule) {
                      final d = s['schedule_date']?.toString().substring(0, 10) ?? '';
                      if (d != lastDate) { items.add(d); lastDate = d; }
                      items.add(s);
                    }
                    return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      if (item is String) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 2),
                          child: Row(children: [
                            const Icon(Icons.calendar_today, size: 13, color: _primary),
                            const SizedBox(width: 6),
                            Text(item, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _primary)),
                            const SizedBox(width: 10),
                            const Expanded(child: Divider()),
                          ]),
                        );
                      }
                      final s = item;
                      return Card(child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Container(width: 4, height: 60, decoration: BoxDecoration(color: _statusColor(s['status']), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s['discipline_name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('${s['professor_name'] ?? ''} · ${s['room_name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(_statusLabel(s['status']), style: TextStyle(color: _statusColor(s['status']), fontSize: 11, fontWeight: FontWeight.w700)),
                          ])),
                          Text('${_t(s['start_time'])} – ${_t(s['end_time'])}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _primary)),
                        ]),
                      ));
                    },
                  );
                  })),
                ])),
            ]),
    );
  }
}

class GenerateScheduleScreen extends StatefulWidget {
  final dynamic selectedClass;
  const GenerateScheduleScreen({super.key, required this.selectedClass});
  @override
  State<GenerateScheduleScreen> createState() => _GenerateScheduleScreenState();
}

class _GenerateScheduleScreenState extends State<GenerateScheduleScreen> {
  DateTime _start = DateTime(2025, 9, 15);
  DateTime _end = DateTime(2025, 10, 15);
  bool _replace = true;
  bool _dryRun = true;
  bool _generating = false;
  bool _checking = false;
  String _schoolStart = '09:00:00';
  String _schoolEnd = '17:00:00';
  String _status = 'draft';
  int _maxSessionsPerDiscipline = 1;
  int _maxTotalSessions = 300;
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _readiness;
  String? _error;

  String _d(DateTime d) => d.toIso8601String().substring(0, 10);

  bool _validTime(String value) {
    final reg = RegExp(r'^\d{2}:\d{2}:\d{2}$');
    if (!reg.hasMatch(value)) return false;
    final parts = value.split(':').map(int.tryParse).toList();
    if (parts.any((p) => p == null)) return false;
    final h = parts[0]!;
    final m = parts[1]!;
    final s = parts[2]!;
    return h >= 0 && h < 24 && m >= 0 && m < 60 && s >= 0 && s < 60;
  }

  bool _validateSettings() {
    if (_end.isBefore(_start)) {
      setState(() => _error = 'A data final não pode ser anterior à data inicial.');
      return false;
    }
    if (!_validTime(_schoolStart) || !_validTime(_schoolEnd)) {
      setState(() => _error = 'As horas devem ter o formato HH:MM:SS.');
      return false;
    }
    return true;
  }

  Future<void> _pick(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _checkReadiness() async {
    if (!_validateSettings()) return;
    setState(() { _checking = true; _readiness = null; _error = null; });
    try {
      final r = await ApiService.getScheduleReadiness(
        classId: widget.selectedClass['id'],
        startDate: _d(_start),
        endDate: _d(_end),
      );
      setState(() { _readiness = r; _checking = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _checking = false; });
    }
  }

  Future<void> _generate() async {
    if (!_validateSettings()) return;
    setState(() { _generating = true; _result = null; _error = null; });
    try {
      final r = await ApiService.generateSchedule(
        classId: widget.selectedClass['id'],
        startDate: _d(_start),
        endDate: _d(_end),
        schoolStart: _schoolStart,
        schoolEnd: _schoolEnd,
        replaceExisting: _replace,
        dryRun: _dryRun,
        status: _status,
        maxSessionsPerDiscipline: _maxSessionsPerDiscipline,
        maxTotalSessions: _maxTotalSessions,
      );
      setState(() { _result = r; _generating = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _generating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ok = _result?['success'] == true;
    final conflicts = ((_result?['conflicts'] as List?) ?? []);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerar horário'),
        backgroundColor: Colors.white,
        foregroundColor: Brand.ink,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [_orange, Brand.blueLight])),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Brand.blueSoft.withValues(alpha: 0.42), Brand.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Turma: ${widget.selectedClass['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('${widget.selectedClass['course_name']} · ${widget.selectedClass['school_year']}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 10),
                  const Text('Dica: primeiro use a pré-visualização. Se as condições estiverem corretas, desligue o modo de teste para guardar.', style: TextStyle(fontSize: 12)),
                ]),
              )),
              const SizedBox(height: 18),
              const Text('Intervalo de datas', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(spacing: 12, runSpacing: 12, children: [
                OutlinedButton.icon(icon: const Icon(Icons.calendar_today, size: 16), label: Text('Início: ${_d(_start)}'), onPressed: () => _pick(true)),
                OutlinedButton.icon(icon: const Icon(Icons.calendar_today, size: 16), label: Text('Fim: ${_d(_end)}'), onPressed: () => _pick(false)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _SmallTextSetting(label: 'Início escolar', value: _schoolStart, onChanged: (v) => _schoolStart = v)),
                const SizedBox(width: 12),
                Expanded(child: _SmallTextSetting(label: 'Fim escolar', value: _schoolEnd, onChanged: (v) => _schoolEnd = v)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _SmallNumberSetting(label: 'Máx. sessões / disciplina', value: _maxSessionsPerDiscipline, onChanged: (v) => _maxSessionsPerDiscipline = v)),
                const SizedBox(width: 12),
                Expanded(child: _SmallNumberSetting(label: 'Máx. total de sessões', value: _maxTotalSessions, onChanged: (v) => _maxTotalSessions = v)),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Modo de teste / pré-visualização'),
                subtitle: const Text('Recomendado: testa sem inserir registos na base de dados'),
                value: _dryRun,
                onChanged: (v) => setState(() => _dryRun = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Substituir horário existente'),
                subtitle: const Text('Necessário se a turma já tiver horário no intervalo selecionado'),
                value: _replace,
                onChanged: (v) => setState(() => _replace = v),
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Estado ao guardar'),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Rascunho')),
                  DropdownMenuItem(value: 'approved', child: Text('Aprovado')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'draft'),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  icon: _checking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.fact_check_outlined),
                  label: Text(_checking ? 'A verificar…' : 'Verificar condições'),
                  onPressed: _checking ? null : _checkReadiness,
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _orange),
                  icon: _generating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
                  label: Text(_generating ? 'A gerar…' : (_dryRun ? 'Pré-visualizar' : 'Gerar e guardar')),
                  onPressed: _generating ? null : _generate,
                )),
              ]),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _ResultBox(color: const Color(0xFFE03131), icon: Icons.error_outline, title: 'Pedido falhou', lines: [_error!]),
              ],
              if (_readiness != null) ...[
                const SizedBox(height: 16),
                _ReadinessBox(readiness: _readiness!),
              ],
              if (_result != null) ...[
                const SizedBox(height: 16),
                _ResultBox(
                  color: ok ? const Color(0xFF0CA678) : _orange,
                  icon: ok ? Icons.check_circle_outline : Icons.warning_amber,
                  title: ok ? (_dryRun ? 'Pré-visualização gerada com sucesso' : 'Horário guardado com sucesso') : 'Geração bloqueada',
                  lines: [
                    'Sessões: ${_result!['created_records']}',
                    'Pontuação de qualidade: ${_result!['score']}',
                    if (_result!['stats'] != null) 'Estatísticas: ${_result!['stats']}',
                    ...conflicts.take(5).map((c) => '• ${c['discipline'] ?? 'Geral'}: ${c['reason']}'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar ao horário'))),
              ],
            ]),
          ),
        ),
      ),
      ),
    );
  }
}

class _SmallTextSetting extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _SmallTextSetting({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label, hintText: 'HH:MM:SS'),
      onChanged: onChanged,
    );
  }
}

class _SmallNumberSetting extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _SmallNumberSetting({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: '$value',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (v) => onChanged(int.tryParse(v) ?? value),
    );
  }
}

class _ReadinessBox extends StatelessWidget {
  final Map<String, dynamic> readiness;
  const _ReadinessBox({required this.readiness});

  @override
  Widget build(BuildContext context) {
    final checks = (readiness['checks'] as List?) ?? [];
    final ready = readiness['ready'] == true;
    final color = ready ? const Color(0xFF0CA678) : const Color(0xFFE8590C);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(ready ? Icons.check_circle_outline : Icons.warning_amber, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(ready ? 'As condições estão corretas' : 'Há condições que precisam de atenção', style: TextStyle(fontWeight: FontWeight.bold, color: color))),
        ]),
        const SizedBox(height: 10),
        ...checks.map((c) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(c['ok'] == true ? Icons.check : Icons.close, size: 16, color: c['ok'] == true ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text('${c['name']}: ${c['detail']}', style: const TextStyle(fontSize: 13))),
          ]),
        )),
      ]),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final List<String> lines;
  const _ResultBox({required this.color, required this.icon, required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))),
        ]),
        const SizedBox(height: 8),
        ...lines.map((l) => Padding(padding: const EdgeInsets.only(top: 2), child: Text(l, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))),
      ]),
    );
  }
}
