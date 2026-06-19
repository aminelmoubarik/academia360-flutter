import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/api_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _searchController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<dynamic> _logs = [];
  Map<String, dynamic>? _summary;
  String? _module;
  String? _action;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getAuditLogs(
          startDate: _emptyToNull(_startDateController.text),
          endDate: _emptyToNull(_endDateController.text),
          module: _module,
          action: _action,
          search: _emptyToNull(_searchController.text),
        ),
        ApiService.getAuditSummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _logs = results[0] as List<dynamic>;
        _summary = results[1] as Map<String, dynamic>;
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

  String? _emptyToNull(String value) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  void _clearFilters() {
    _searchController.clear();
    _startDateController.clear();
    _endDateController.clear();
    setState(() {
      _module = null;
      _action = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        color: c.bg,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _Header(summary: _summary),
                    const SizedBox(height: 16),
                    _Filters(
                      searchController: _searchController,
                      startDateController: _startDateController,
                      endDateController: _endDateController,
                      module: _module,
                      action: _action,
                      onModuleChanged: (value) => setState(() => _module = value),
                      onActionChanged: (value) => setState(() => _action = value),
                      onApply: _load,
                      onClear: _clearFilters,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      _ErrorCard(message: _error!)
                    else if (_logs.isEmpty)
                      const _EmptyCard()
                    else
                      for (final item in _logs) ...[
                        _AuditLogCard(item: item as Map<String, dynamic>),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Map<String, dynamic>? summary;
  const _Header({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary?['total'] ?? 0;
    final byModule = (summary?['by_module'] as List?) ?? const [];
    final byAction = (summary?['by_action'] as List?) ?? const [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Brand.blue, Brand.blueDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Brand.blue.withValues(alpha: 0.20), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.security_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Histórico de auditoria', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text('Registo de ações críticas, acessos e alterações na plataforma.', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _MetricPill(label: 'Eventos 7 dias', value: total.toString()),
          if (byModule.isNotEmpty)
            _MetricPill(label: 'Módulo principal', value: (byModule.first as Map)['module']?.toString() ?? '-'),
          if (byAction.isNotEmpty)
            _MetricPill(label: 'Ação principal', value: (byAction.first as Map)['action']?.toString() ?? '-'),
        ]),
        const SizedBox(height: 4),
        Text('Apenas Administração e Direção podem consultar estes registos.', style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white24)),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 12),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final String? module;
  final String? action;
  final ValueChanged<String?> onModuleChanged;
  final ValueChanged<String?> onActionChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _Filters({
    required this.searchController,
    required this.startDateController,
    required this.endDateController,
    required this.module,
    required this.action,
    required this.onModuleChanged,
    required this.onActionChanged,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Filtros', style: TextStyle(color: c.ink, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(width: 260, child: TextField(controller: searchController, decoration: const InputDecoration(labelText: 'Pesquisar', prefixIcon: Icon(Icons.search_rounded)))),
          SizedBox(width: 150, child: TextField(controller: startDateController, decoration: const InputDecoration(labelText: 'Desde', hintText: '2026-06-01'))),
          SizedBox(width: 150, child: TextField(controller: endDateController, decoration: const InputDecoration(labelText: 'Até', hintText: '2026-06-30'))),
          SizedBox(width: 190, child: _SelectField(label: 'Módulo', value: module, items: const ['authentication', 'attendance', 'justifications', 'schedule', 'administration'], onChanged: onModuleChanged)),
          SizedBox(width: 170, child: _SelectField(label: 'Ação', value: action, items: const ['login_success', 'login_failed', 'create', 'update', 'delete', 'punch', 'offline_sync', 'generate', 'approve', 'reject', 'review'], onChanged: onActionChanged)),
          FilledButton.icon(onPressed: onApply, icon: const Icon(Icons.filter_alt_outlined), label: const Text('Aplicar')),
          TextButton.icon(onPressed: onClear, icon: const Icon(Icons.clear_rounded), label: const Text('Limpar')),
        ]),
      ]),
    );
  }
}

class _SelectField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _SelectField({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Todos')),
        for (final item in items) DropdownMenuItem(value: item, child: Text(_label(item), overflow: TextOverflow.ellipsis)),
      ],
      onChanged: onChanged,
    );
  }

  String _label(String value) => value.replaceAll('_', ' ');
}

class _AuditLogCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _AuditLogCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final action = item['action']?.toString() ?? '-';
    final module = item['module']?.toString() ?? '-';
    final user = item['user_email']?.toString() ?? 'system';
    final role = item['user_role']?.toString() ?? '-';
    final entity = [item['entity_type'], item['entity_id']].where((v) => v != null && v.toString().isNotEmpty).join(' #');

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.line)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: _actionColor(action).withValues(alpha: c.isDark ? 0.25 : 0.12), child: Icon(_actionIcon(action), color: _actionColor(action), size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            _Tag(text: module, color: Brand.blue),
            _Tag(text: action.replaceAll('_', ' '), color: _actionColor(action)),
            if (entity.isNotEmpty) _Tag(text: entity, color: Brand.violet),
          ]),
          const SizedBox(height: 8),
          Text(item['summary']?.toString() ?? '-', style: TextStyle(color: c.ink, fontWeight: FontWeight.w900, fontSize: 14.5)),
          const SizedBox(height: 6),
          Text('$user · $role', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700, fontSize: 12.5)),
          if (item['ip_address'] != null) ...[
            const SizedBox(height: 4),
            Text('IP: ${item['ip_address']}', style: TextStyle(color: c.faint, fontSize: 11.5)),
          ],
        ])),
        const SizedBox(width: 12),
        Text(_formatDate(item['created_at']), style: TextStyle(color: c.muted, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }

  Color _actionColor(String action) {
    if (action.contains('delete') || action.contains('reject') || action.contains('failed')) return Brand.danger;
    if (action.contains('approve') || action.contains('success')) return Brand.ok;
    if (action.contains('create') || action.contains('punch') || action.contains('generate')) return Brand.blue;
    return Brand.amber;
  }

  IconData _actionIcon(String action) {
    if (action.contains('delete')) return Icons.delete_outline;
    if (action.contains('approve')) return Icons.verified_outlined;
    if (action.contains('reject')) return Icons.cancel_outlined;
    if (action.contains('login')) return Icons.login_rounded;
    if (action.contains('punch')) return Icons.fingerprint;
    return Icons.history_rounded;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (text.length >= 16) return text.substring(0, 16).replaceFirst('T', ' ');
    return text;
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: c.isDark ? 0.22 : 0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Brand.danger.withValues(alpha: c.isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Brand.danger.withValues(alpha: 0.22)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline, color: Brand.danger),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Não foi possível carregar a auditoria', style: TextStyle(color: c.ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(message, style: TextStyle(color: c.muted, fontSize: 12.5)),
        ])),
      ]),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.line)),
      child: Column(children: [
        Icon(Icons.history_rounded, size: 42, color: c.faint),
        const SizedBox(height: 10),
        Text('Ainda não há registos de auditoria para estes filtros.', style: TextStyle(color: c.ink, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Execute ações como login, picagem, aprovação de horários ou gestão de utilizadores.', textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
      ]),
    );
  }
}
