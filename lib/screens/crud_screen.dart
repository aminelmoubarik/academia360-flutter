import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../main.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

enum CrudFieldType { text, email, password, integer, boolean, date, time, select }

/// Opção para um campo do tipo [CrudFieldType.select].
class CrudOption {
  final dynamic value;
  final String label;
  const CrudOption(this.value, this.label);
}

class CrudField {
  final String keyName;
  final String label;
  final CrudFieldType type;
  final bool required;
  final bool createOnly;
  final bool hideInList;
  final String? hint;

  /// Apenas para [CrudFieldType.select].
  final List<CrudOption> options;

  /// Para [CrudFieldType.select] com opções carregadas pela API.
  /// Se definido, as opções são obtidas deste endpoint em vez de
  /// [options]. [optionLabel] e [optionValue] extraem a etiqueta e o valor de
  /// cada registo devolvido.
  final String? optionsEndpoint;
  final String Function(Map<String, dynamic>)? optionLabel;
  final dynamic Function(Map<String, dynamic>)? optionValue;

  /// Para campos sensíveis (palavra-passe): obrigatório ao criar, mas opcional ao
  /// editar. Se ficar vazio em edição, o campo NÃO é enviado (não muda).
  /// Substitui o padrão `createOnly` para palavras-passe.
  final bool editableSecret;

  /// Quando definido, este campo confirma o valor de outro campo.
  /// Exemplo: password_confirm confirma password.
  final String? confirmFor;

  /// Define se o campo deve ser enviado ao backend.
  /// Campos de confirmação normalmente ficam como false.
  final bool sendInPayload;

  const CrudField({
    required this.keyName,
    required this.label,
    this.type = CrudFieldType.text,
    this.required = false,
    this.createOnly = false,
    this.hideInList = false,
    this.hint,
    this.options = const [],
    this.optionsEndpoint,
    this.optionLabel,
    this.optionValue,
    this.editableSecret = false,
    this.confirmFor,
    this.sendInPayload = true,
  });
}

class CrudScreen extends StatefulWidget {
  final String title;
  final String endpoint;
  final String idKey;
  final IconData icon;
  final Color color;
  final List<CrudField> fields;
  final String Function(Map<String, dynamic>) titleBuilder;
  final String Function(Map<String, dynamic>) subtitleBuilder;
  final List<String> searchableKeys;
  final List<String> editableRoles;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;
  final String Function(Map<String, dynamic>)? deletePathBuilder;
  final bool Function(Map<String, dynamic> record, User? currentUser)? canDeleteRecord;

  const CrudScreen({
    super.key,
    required this.title,
    required this.endpoint,
    required this.fields,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.idKey = 'id',
    this.icon = Icons.table_rows_outlined,
    this.color = const Color(0xFF1929E9),
    this.searchableKeys = const [],
    this.editableRoles = const ['admin', 'director', 'secretary'],
    this.canCreate = true,
    this.canUpdate = true,
    this.canDelete = true,
    this.deletePathBuilder,
    this.canDeleteRecord,
  });

  @override
  State<CrudScreen> createState() => _CrudScreenState();
}

class _CrudScreenState extends State<CrudScreen> {
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  User? _user;
  bool _loading = true;
  String? _error;

  bool get _canManage => _user != null && widget.editableRoles.contains(_user!.role);

  bool _canDeleteRecord(Map<String, dynamic> record) {
    if (!_canManage || !widget.canDelete) return false;
    return widget.canDeleteRecord?.call(record, _user) ?? true;
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted) return;
    setState(() => _user = user);
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getListByPath(widget.endpoint);
      if (!mounted) return;
      setState(() {
        _all = data;
        _filtered = data;
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

  void _search(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = _all;
        return;
      }
      _filtered = _all.where((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final values =
            widget.searchableKeys.isEmpty ? map.values : widget.searchableKeys.map((k) => map[k]);
        return values.any((value) => (value?.toString() ?? '').toLowerCase().contains(query));
      }).toList();
    });
  }

  Future<void> _openForm([Map<String, dynamic>? record]) async {
    if (!_canManage) return;

    final isEdit = record != null;
    if (isEdit && !widget.canUpdate) return;
    if (!isEdit && !widget.canCreate) return;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: !_loading,
      builder: (_) => _CrudFormDialog(
        title: isEdit ? 'Editar registo' : 'Novo registo',
        fields: widget.fields,
        record: record,
        color: widget.color,
        icon: widget.icon,
        isEdit: isEdit,
        onSubmit: (payload) async {
          if (isEdit) {
            await ApiService.updateRecord(widget.endpoint, record[widget.idKey], payload);
          } else {
            await ApiService.createRecord(widget.endpoint, payload);
          }
        },
      ),
    );

    if (saved != true || !mounted) return;

    AppFeedback.success(
      context,
      isEdit ? 'Alterações guardadas com sucesso.' : 'Registo criado com sucesso.',
    );
    await _load();
  }

  Future<void> _delete(Map<String, dynamic> record) async {
    if (!_canDeleteRecord(record)) return;

    final label = widget.titleBuilder(record);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
        title: const Text('Eliminar registo?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Esta ação não pode ser anulada.\n\n'),
              TextSpan(
                text: label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      if (widget.deletePathBuilder != null) {
        await ApiService.deleteByPath(widget.deletePathBuilder!(record));
      } else {
        await ApiService.deleteRecord(widget.endpoint, record[widget.idKey]);
      }
      if (!mounted) return;
      AppFeedback.success(context, 'Registo eliminado com sucesso.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 66,
        titleSpacing: 12,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        backgroundColor: Colors.white,
        foregroundColor: Brand.ink,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [widget.color, Color.lerp(widget.color, Colors.white, 0.35)!]),
            ),
          ),
        ),
      ),
      floatingActionButton: _canManage && widget.canCreate
          ? FloatingActionButton.extended(
              elevation: 4,
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : null,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, widget.color.withValues(alpha: 0.035), Brand.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : Column(children: [
                  if (!_canManage)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.lock_outline, size: 18, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'O seu perfil tem apenas acesso de leitura.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ]),
                    ),
                  SearchBarField(
                    hint: 'Pesquisar em ${widget.title.toLowerCase()}…',
                    onChanged: _search,
                  ),
                  ResultCount(count: _filtered.length, noun: 'registos'),
                  Expanded(
                    child: _filtered.isEmpty
                        ? EmptyView(icon: widget.icon, message: 'Não foram encontrados registos')
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final record = Map<String, dynamic>.from(_filtered[i] as Map);
                                final delay = Duration(milliseconds: (i % 10) * 28);
                                return TweenAnimationBuilder<double>(
                                  key: ValueKey(record[widget.idKey] ?? i),
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(milliseconds: 260) + delay,
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 18 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    elevation: 0,
                                    shadowColor: Colors.black12,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.color.withValues(alpha: 0.035),
                                            blurRadius: 22,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        minVerticalPadding: 14,
                                        leading: InitialAvatar(
                                          text: widget.titleBuilder(record),
                                          color: widget.color,
                                        ),
                                        title: Text(
                                          widget.titleBuilder(record),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                        subtitle: Text(
                                          widget.subtitleBuilder(record),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: _canManage
                                            ? _RowActions(
                                                color: widget.color,
                                                canUpdate: widget.canUpdate,
                                                canDelete: _canDeleteRecord(record),
                                                onEdit: () => _openForm(record),
                                                onDelete: () => _delete(record),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ]),
      ),
    );
  }
}

/// Ações da linha. Mantêm-se compactas para não empurrar o texto do
/// ListTile nem provocar desbordamentos no título/subtítulo.
class _RowActions extends StatelessWidget {
  final Color color;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RowActions({
    required this.color,
    required this.canUpdate,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canUpdate)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Editar',
            icon: Icon(Icons.edit_outlined, color: color),
            onPressed: onEdit,
          ),
        if (canDelete)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Eliminar',
            icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
            onPressed: onDelete,
          ),
      ],
    );
  }
}

class _CrudFormDialog extends StatefulWidget {
  final String title;
  final List<CrudField> fields;
  final Map<String, dynamic>? record;
  final Color color;
  final bool isEdit;
  final IconData icon;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  const _CrudFormDialog({
    required this.title,
    required this.fields,
    required this.color,
    required this.isEdit,
    required this.icon,
    required this.onSubmit,
    this.record,
  });

  @override
  State<_CrudFormDialog> createState() => _CrudFormDialogState();
}

class _CrudFormDialogState extends State<_CrudFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _boolValues = {};
  final Map<String, dynamic> _selectValues = {};
  final Map<String, bool> _obscured = {}; // visibilidad de campos secretos
  final Map<String, List<CrudOption>> _dynamicOptions = {}; // opções da API
  final Set<String> _loadingOptions = {};
  bool _submitting = false;
  String? _submitError;

  /// Um campo de palavra-passe é tratado como secreto editável quando está marcado
  /// com [CrudField.editableSecret] ou quando é do tipo password.
  bool _isSecret(CrudField f) =>
      f.editableSecret || f.type == CrudFieldType.password;

  /// Decide se um campo deve ser apresentado no formulário conforme o modo.
  bool _isVisible(CrudField f) {
    // Os campos secretos editáveis aparecem sempre (também em edição).
    if (f.editableSecret) return true;
    // Os restantes createOnly ficam ocultos ao editar.
    if (widget.isEdit && f.createOnly) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      final value = widget.record?[field.keyName];
      switch (field.type) {
        case CrudFieldType.boolean:
          _boolValues[field.keyName] =
              value == true || value == 1 || value?.toString().toLowerCase() == 'true';
          break;
        case CrudFieldType.select:
          {
            // Mantém o valor atual se corresponder a uma opção disponível.
            final match = field.options
                .where((o) => o.value.toString() == value?.toString())
                .map((o) => o.value)
                .toList();
            _selectValues[field.keyName] = match.isNotEmpty ? match.first : null;
            break;
          }
        default:
          // As palavras-passe nunca são pré-preenchidas (não vêm do backend).
          final initial = _isSecret(field) ? '' : (value?.toString() ?? '');
          _controllers[field.keyName] = TextEditingController(text: initial);
          if (_isSecret(field)) _obscured[field.keyName] = true;
          break;
      }
    }
    _loadDynamicOptions();
  }

  /// Carrega as opções dos seletores que apontam para um endpoint.
  Future<void> _loadDynamicOptions() async {
    for (final field in widget.fields) {
      if (field.type != CrudFieldType.select || field.optionsEndpoint == null) {
        continue;
      }
      setState(() => _loadingOptions.add(field.keyName));
      try {
        final rows = await ApiService.getListByPath(field.optionsEndpoint!);
        final opts = rows.map((r) {
          final map = Map<String, dynamic>.from(r as Map);
          final label = field.optionLabel?.call(map) ?? map.toString();
          final value = field.optionValue?.call(map) ?? map['id'];
          return CrudOption(value, label);
        }).toList();
        if (!mounted) return;
        setState(() {
          _dynamicOptions[field.keyName] = opts;
          _loadingOptions.remove(field.keyName);
          // Reconcilia o valor inicial com as opções acabadas de carregar.
          final current = widget.record?[field.keyName];
          final match = opts
              .where((o) => o.value.toString() == current?.toString())
              .map((o) => o.value)
              .toList();
          if (match.isNotEmpty) _selectValues[field.keyName] = match.first;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _loadingOptions.remove(field.keyName));
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextInputType _keyboard(CrudFieldType type) {
    return switch (type) {
      CrudFieldType.email => TextInputType.emailAddress,
      CrudFieldType.integer => TextInputType.number,
      CrudFieldType.date => TextInputType.datetime,
      CrudFieldType.time => TextInputType.datetime,
      _ => TextInputType.text,
    };
  }

  Map<String, dynamic> _payload() {
    final payload = <String, dynamic>{};
    for (final field in widget.fields) {
      if (!field.sendInPayload || field.confirmFor != null) continue;
      // Campos clássicos apenas de criação não são reenviados ao editar.
      if (widget.isEdit && field.createOnly && !field.editableSecret) continue;

      switch (field.type) {
        case CrudFieldType.boolean:
          payload[field.keyName] = _boolValues[field.keyName] ?? false;
          break;
        case CrudFieldType.select:
          {
            final v = _selectValues[field.keyName];
            if (v != null) payload[field.keyName] = v;
            break;
          }
        default:
          {
            final raw = _controllers[field.keyName]!.text.trim();

            // Campo secreto (palavra-passe): se estiver vazio em edição, NÃO é enviado
            // (mantém-se a atual). Ao criar, vazio é bloqueado pelo validador.
            if (_isSecret(field)) {
              if (raw.isNotEmpty) payload[field.keyName] = raw;
              continue;
            }

            if (raw.isEmpty) {
              // Vazio + opcional => null explícito para que o backend limpe o valor.
              // Vazio + obrigatório nunca chega aqui (é bloqueado pelo validador).
              if (!field.required) payload[field.keyName] = null;
              continue;
            }
            if (field.type == CrudFieldType.integer) {
              payload[field.keyName] = int.tryParse(raw);
            } else {
              payload[field.keyName] = raw;
            }
            break;
          }
      }
    }
    return payload;
  }

  String _cleanFormError(Object error) {
    final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    if (raw.isEmpty) return 'Não foi possível guardar o registo.';
    return raw.length > 280 ? '${raw.substring(0, 277)}...' : raw;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      await widget.onSubmit(_payload());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = _cleanFormError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Largura responsiva: confortável no desktop, sem sair do ecrã no telemóvel.
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 560 ? screenWidth - 48 : 460.0;

    final visibleFields = widget.fields.where(_isVisible).toList();

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, Color.lerp(widget.color, Colors.white, 0.32)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Brand.ink),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _submitError == null
                      ? const SizedBox.shrink()
                      : Container(
                          key: const ValueKey('form-error'),
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Brand.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Brand.danger.withValues(alpha: 0.22)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, color: Brand.danger, size: 19),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  _submitError!,
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Brand.danger,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                for (final field in visibleFields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildField(field),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.isEdit ? 'Guardar alterações' : 'Criar'),
        ),
      ],
    );
  }

  Widget _buildField(CrudField field) {
    switch (field.type) {
      case CrudFieldType.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(field.label),
          subtitle: field.hint != null ? Text(field.hint!) : null,
          value: _boolValues[field.keyName] ?? false,
          activeThumbColor: widget.color,
          onChanged: (v) => setState(() => _boolValues[field.keyName] = v),
        );

      case CrudFieldType.select:
        final isLoading = _loadingOptions.contains(field.keyName);
        final opts = field.optionsEndpoint != null
            ? (_dynamicOptions[field.keyName] ?? const <CrudOption>[])
            : field.options;
        // O value tem de existir entre os items ou o Flutter lança uma exceção.
        final current = _selectValues[field.keyName];
        final safeValue =
            opts.any((o) => o.value == current) ? current : null;
        return DropdownButtonFormField<dynamic>(
          initialValue: safeValue,
          isExpanded: true, // evita desbordamento de etiquetas longas
          decoration: InputDecoration(
            labelText: field.label,
            helperText: field.hint,
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
          items: opts
              .map((o) => DropdownMenuItem(
                    value: o.value,
                    child: Text(o.label, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          validator: (v) {
            if (field.required && v == null) return 'Selecione ${field.label.toLowerCase()}';
            return null;
          },
          onChanged: isLoading ? null : (v) => setState(() => _selectValues[field.keyName] = v),
        );

      default:
        final isSecret = _isSecret(field);
        final obscured = _obscured[field.keyName] ?? false;
        // Em edição, um segredo é opcional: fica claro no texto auxiliar.
        final secretEditHint = field.confirmFor != null
            ? (widget.isEdit
                ? 'Repita apenas se alterar a palavra-passe'
                : field.hint)
            : (widget.isEdit ? 'Deixe vazio para manter a atual' : field.hint);
        return TextFormField(
          controller: _controllers[field.keyName],
          obscureText: isSecret && obscured,
          keyboardType: _keyboard(field.type),
          decoration: InputDecoration(
            labelText: field.label,
            hintText: isSecret ? null : field.hint,
            helperText: isSecret ? secretEditHint : field.hint,
            // helperMaxLines evita que dicas longas quebrem o layout.
            helperMaxLines: 2,
            suffixIcon: isSecret
                ? IconButton(
                    icon: Icon(obscured ? Icons.visibility_off : Icons.visibility, size: 20),
                    tooltip: obscured ? 'Mostrar' : 'Ocultar',
                    onPressed: () =>
                        setState(() => _obscured[field.keyName] = !obscured),
                  )
                : null,
          ),
          validator: (value) {
            final v = value?.trim() ?? '';

            if (field.confirmFor != null) {
              final original = _controllers[field.confirmFor!]?.text.trim() ?? '';
              final needsConfirmation = !widget.isEdit || original.isNotEmpty || v.isNotEmpty;
              if (!needsConfirmation) return null;
              if (v.isEmpty) return 'Confirme a palavra-passe';
              if (v != original) return 'As palavras-passe não coincidem';
              return null;
            }

            // Segredo em edição: vazio é válido (não muda).
            if (isSecret && widget.isEdit && v.isEmpty) return null;
            if ((field.required || (isSecret && !widget.isEdit)) && v.isEmpty) {
              return '${field.label} é obrigatório';
            }
            // Regra de palavra-passe do backend: mínimo 6 caracteres.
            if (isSecret && v.isNotEmpty && v.length < 6) {
              return 'Mínimo 6 caracteres';
            }
            if (field.type == CrudFieldType.integer && v.isNotEmpty && int.tryParse(v) == null) {
              return 'Introduza um número válido';
            }
            if (field.type == CrudFieldType.email &&
                v.isNotEmpty &&
                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
              return 'Introduza um email válido';
            }
            return null;
          },
        );
    }
  }
}
