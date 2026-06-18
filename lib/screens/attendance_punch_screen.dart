import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/storage.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import '../services/api_service.dart';

class AttendancePunchScreen extends StatefulWidget {
  const AttendancePunchScreen({super.key});

  @override
  State<AttendancePunchScreen> createState() => _AttendancePunchScreenState();
}

class _AttendancePunchScreenState extends State<AttendancePunchScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  String _method = 'nfc';
  String _punchType = 'auto';
  bool _submitting = false;
  bool _loadingDashboard = true;
  String? _error;
  Map<String, dynamic>? _lastResult;
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _offlineQueue = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadQueue(), _loadDashboard()]);
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loadingDashboard = true;
        _error = null;
      });
    }
    try {
      final data = await ApiService.getAttendanceDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = data;
        _loadingDashboard = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingDashboard = false;
      });
    }
  }

  Future<void> _loadQueue() async {
    final raw = await SecureStorage.getOfflineAttendanceQueue();
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        setState(() {
          _offlineQueue = decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveQueue() async {
    if (_offlineQueue.isEmpty) {
      await SecureStorage.clearOfflineAttendanceQueue();
    } else {
      await SecureStorage.saveOfflineAttendanceQueue(jsonEncode(_offlineQueue));
    }
  }

  Future<void> _registerPunch({bool forceOffline = false}) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      AppFeedback.error(context, 'Introduza ou leia o UID/cartão do estudante.');
      _focusNode.requestFocus();
      return;
    }

    final offlineRecord = <String, dynamic>{
      'card_uid': code,
      'punch_method': _method,
      'punch_time': DateTime.now().toIso8601String(),
      if (_punchType != 'auto') 'punch_type': _punchType,
    };

    if (forceOffline) {
      await _addOfflineRecord(offlineRecord);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _lastResult = null;
    });

    try {
      final result = await ApiService.punchAttendance(
        cardUid: code,
        punchMethod: _method,
        punchType: _punchType == 'auto' ? null : _punchType,
        punchTime: offlineRecord['punch_time'] as String,
      );
      if (!mounted) return;
      setState(() {
        _lastResult = result;
        _submitting = false;
      });
      _codeController.clear();
      AppFeedback.success(context, _successMessage(result));
      await _loadDashboard();
      _focusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
      final message = e.toString().toLowerCase();
      final looksOffline = message.contains('servidor') || message.contains('contactar') || message.contains('offline');
      if (looksOffline) {
        await _addOfflineRecord(offlineRecord, silent: true);
        if (!mounted) return;
        AppFeedback.info(context, 'Sem ligação ao backend. Picagem guardada offline para sincronização.');
        _codeController.clear();
      } else {
        AppFeedback.error(context, e.toString());
      }
      _focusNode.requestFocus();
    }
  }

  Future<void> _addOfflineRecord(Map<String, dynamic> record, {bool silent = false}) async {
    setState(() => _offlineQueue = [..._offlineQueue, record]);
    await _saveQueue();
    _codeController.clear();
    if (!silent && mounted) {
      AppFeedback.info(context, 'Picagem guardada offline.');
    }
    _focusNode.requestFocus();
  }

  Future<void> _syncQueue() async {
    if (_offlineQueue.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final result = await ApiService.syncOfflineAttendance(_offlineQueue);
      if (!mounted) return;
      final success = result['success'] == true;
      if (success) {
        setState(() => _offlineQueue = []);
        await _saveQueue();
        if (!mounted) return;
        AppFeedback.success(context, 'Picagens offline sincronizadas com sucesso.');
        await _loadDashboard();
      } else {
        AppFeedback.error(context, 'Algumas picagens não foram sincronizadas. Verifique os cartões.');
      }
    } catch (e) {
      if (mounted) AppFeedback.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _successMessage(Map<String, dynamic> result) {
    final student = result['student'];
    final name = student is Map ? student['student_name']?.toString() : null;
    final type = result['punch_type'] == 'out' ? 'Saída' : 'Entrada';
    return '${name ?? 'Estudante'} · $type registada';
  }


  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Picagem de assiduidade'),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(gradient: Brand.heroGradient),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: c.isDark
                ? [c.surface, c.bg]
                : [Colors.white, Brand.blueSoft.withValues(alpha: 0.55), c.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PunchHero(queueCount: _offlineQueue.length, onSync: _syncQueue),
              const SizedBox(height: 18),
              LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 960;
                final form = _PunchFormCard(
                  codeController: _codeController,
                  focusNode: _focusNode,
                  method: _method,
                  punchType: _punchType,
                  submitting: _submitting,
                  onMethodChanged: (v) => setState(() => _method = v),
                  onPunchTypeChanged: (v) => setState(() => _punchType = v),
                  onSubmit: () => _registerPunch(),
                  onOffline: () => _registerPunch(forceOffline: true),
                );
                final status = _StatusPanel(
                  loading: _loadingDashboard,
                  error: _error,
                  dashboard: _dashboard,
                  lastResult: _lastResult,
                  offlineQueue: _offlineQueue,
                  onRetry: _loadDashboard,
                  onSync: _syncQueue,
                );
                if (!wide) {
                  return Column(children: [form, const SizedBox(height: 16), status]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: form),
                    const SizedBox(width: 18),
                    Expanded(flex: 5, child: status),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PunchHero extends StatelessWidget {
  final int queueCount;
  final VoidCallback onSync;
  const _PunchHero({required this.queueCount, required this.onSync});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: Brand.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Brand.blue.withValues(alpha: 0.24), blurRadius: 26, offset: const Offset(0, 14)),
        ],
      ),
      child: Stack(children: [
        Positioned(right: -80, top: -90, child: _Glow(size: 230, alpha: 0.14)),
        Positioned(left: -70, bottom: -100, child: _Glow(size: 250, alpha: 0.12)),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: const Icon(Icons.contactless_outlined, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Módulo 1 · Picagem NFC/RFID',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text(
                    'Leitura de cartão, entrada/saída com timestamp, fila offline e sincronização automática manual.',
                    style: TextStyle(color: Colors.white, fontSize: 13, height: 1.45),
                  ),
                ],
              ),
            ),
            if (queueCount > 0) ...[
              const SizedBox(width: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Brand.blue),
                onPressed: onSync,
                icon: const Icon(Icons.cloud_sync_outlined),
                label: Text('Sincronizar $queueCount'),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _PunchFormCard extends StatelessWidget {
  final TextEditingController codeController;
  final FocusNode focusNode;
  final String method;
  final String punchType;
  final bool submitting;
  final ValueChanged<String> onMethodChanged;
  final ValueChanged<String> onPunchTypeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onOffline;

  const _PunchFormCard({
    required this.codeController,
    required this.focusNode,
    required this.method,
    required this.punchType,
    required this.submitting,
    required this.onMethodChanged,
    required this.onPunchTypeChanged,
    required this.onSubmit,
    required this.onOffline,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Brand.blue.withValues(alpha: c.isDark ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.sensors_outlined, color: Brand.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Terminal de picagem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: c.ink)),
                Text('Compatível com leitor USB tipo teclado, QR/barcode e introdução manual.',
                    style: TextStyle(fontSize: 12.5, color: c.muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          TextField(
            controller: codeController,
            focusNode: focusNode,
            autofocus: true,
            enabled: !submitting,
            onSubmitted: (_) => onSubmit(),
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'UID do cartão / QR / código de barras',
              hintText: 'Passe o cartão ou leia o código…',
              prefixIcon: Icon(Icons.credit_card_outlined),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 560;
            final methodField = DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(labelText: 'Método', prefixIcon: Icon(Icons.tap_and_play_outlined)),
              items: const [
                DropdownMenuItem(value: 'nfc', child: Text('NFC')),
                DropdownMenuItem(value: 'rfid', child: Text('RFID')),
                DropdownMenuItem(value: 'qr', child: Text('QR Code')),
                DropdownMenuItem(value: 'barcode', child: Text('Código de barras')),
                DropdownMenuItem(value: 'manual', child: Text('Manual')),
              ],
              onChanged: submitting ? null : (v) => onMethodChanged(v ?? 'nfc'),
            );
            final typeField = DropdownButtonFormField<String>(
              initialValue: punchType,
              decoration: const InputDecoration(labelText: 'Tipo', prefixIcon: Icon(Icons.login_outlined)),
              items: const [
                DropdownMenuItem(value: 'auto', child: Text('Automático')),
                DropdownMenuItem(value: 'in', child: Text('Entrada')),
                DropdownMenuItem(value: 'out', child: Text('Saída')),
              ],
              onChanged: submitting ? null : (v) => onPunchTypeChanged(v ?? 'auto'),
            );
            if (narrow) return Column(children: [methodField, const SizedBox(height: 12), typeField]);
            return Row(children: [Expanded(child: methodField), const SizedBox(width: 12), Expanded(child: typeField)]);
          }),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: submitting ? null : onSubmit,
                icon: submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.fingerprint),
                label: Text(submitting ? 'A registar…' : 'Registar picagem'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: submitting ? null : onOffline,
              icon: const Icon(Icons.cloud_off_outlined),
              label: const Text('Offline'),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            'Dica: leitores USB RFID/QR normalmente escrevem o código neste campo e enviam Enter automaticamente.',
            style: TextStyle(fontSize: 12, color: c.faint, height: 1.35),
          ),
        ]),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? dashboard;
  final Map<String, dynamic>? lastResult;
  final List<Map<String, dynamic>> offlineQueue;
  final VoidCallback onRetry;
  final VoidCallback onSync;

  const _StatusPanel({
    required this.loading,
    required this.error,
    required this.dashboard,
    required this.lastResult,
    required this.offlineQueue,
    required this.onRetry,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (loading) return const LoadingView();
    final total = dashboard?['total_students'] ?? 0;
    final present = dashboard?['present_students'] ?? 0;
    final absent = dashboard?['absent_students'] ?? 0;
    final recent = (dashboard?['recent'] as List?) ?? const [];
    final absentees = (dashboard?['absentees'] as List?) ?? const [];

    return Column(children: [
      if (error != null) ...[
        ErrorView(message: error!, onRetry: onRetry),
        const SizedBox(height: 12),
      ],
      if (lastResult != null) ...[
        _LastPunchCard(result: lastResult!),
        const SizedBox(height: 12),
      ],
      Row(children: [
        Expanded(child: _MiniMetric(label: 'Estudantes', value: '$total', icon: Icons.people_outline, color: Brand.blue)),
        const SizedBox(width: 10),
        Expanded(child: _MiniMetric(label: 'Presentes', value: '$present', icon: Icons.check_circle_outline, color: Brand.ok)),
        const SizedBox(width: 10),
        Expanded(child: _MiniMetric(label: 'Alertas', value: '$absent', icon: Icons.warning_amber_outlined, color: Brand.warn)),
      ]),
      const SizedBox(height: 12),
      if (offlineQueue.isNotEmpty)
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_off_outlined, color: Brand.warn),
            title: Text('${offlineQueue.length} picagens offline', style: TextStyle(fontWeight: FontWeight.w900, color: c.ink)),
            subtitle: Text('Sincronize quando o backend estiver disponível.', style: TextStyle(color: c.muted)),
            trailing: FilledButton(onPressed: onSync, child: const Text('Sincronizar')),
          ),
        ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Últimas picagens', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: c.ink)),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              Text('Ainda não há picagens hoje.', style: TextStyle(color: c.muted))
            else
              for (final r in recent.take(6))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(r['punch_type'] == 'out' ? Icons.logout : Icons.login, color: r['punch_type'] == 'out' ? Brand.danger : Brand.ok),
                  title: Text(r['student_name']?.toString() ?? 'Estudante', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${r['class_name'] ?? ''} · ${r['punch_method']?.toString().toUpperCase() ?? ''}'),
                  trailing: Text(_shortDate(r['punch_time']), style: TextStyle(fontSize: 11, color: c.muted, fontWeight: FontWeight.w800)),
                ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Alertas de absentismo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: c.ink)),
            const SizedBox(height: 8),
            if (absentees.isEmpty)
              const ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.verified_outlined, color: Brand.ok),
                title: Text('Sem alertas para hoje'),
              )
            else
              for (final s in absentees.take(6))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber_outlined, color: Brand.warn),
                  title: Text(s['student_name']?.toString() ?? 'Estudante', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${s['class_name'] ?? ''} · ${s['student_number'] ?? ''}'),
                ),
          ]),
        ),
      ),
    ]);
  }

  static String _shortDate(dynamic value) {
    if (value == null) return '';
    final s = value.toString().replaceAll('T', ' ');
    return s.length > 16 ? s.substring(11, 16) : s;
  }
}


String _formatPunchDate(dynamic value) {
  if (value == null) return 'Agora';
  final s = value.toString().replaceAll('T', ' ');
  return s.length > 16 ? s.substring(0, 16) : s;
}

class _LastPunchCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _LastPunchCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final student = result['student'];
    final name = student is Map ? student['student_name']?.toString() : 'Estudante';
    final klass = student is Map ? student['class_name']?.toString() : '';
    final isOut = result['punch_type'] == 'out';
    final color = isOut ? Brand.danger : Brand.ok;
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withValues(alpha: c.isDark ? 0.20 : 0.10),
            child: Icon(isOut ? Icons.logout : Icons.login, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name ?? 'Estudante', style: TextStyle(fontWeight: FontWeight.w900, color: c.ink, fontSize: 16)),
              const SizedBox(height: 3),
              Text('${isOut ? 'Saída' : 'Entrada'} · ${klass ?? ''}', style: TextStyle(color: c.muted)),
            ]),
          ),
          Text(_formatPunchDate(result['punch_time']), style: TextStyle(color: c.muted, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniMetric({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final double alpha;
  const _Glow({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)),
      );
}
