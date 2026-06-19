import 'package:flutter/material.dart';

import 'crud_screen.dart';

class JustificationsScreen extends StatelessWidget {
  const JustificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudScreen(
      title: 'Justificações de faltas',
      endpoint: '/attendance-justifications',
      idKey: 'id',
      icon: Icons.fact_check_outlined,
      color: const Color(0xFF1929E9),
      editableRoles: const ['admin', 'director', 'secretary'],
      createRoles: const ['admin', 'secretary'],
      updateRoles: const ['admin', 'director', 'secretary'],
      deleteRoles: const ['admin', 'secretary'],
      canCreate: true,
      canUpdate: true,
      canDelete: true,
      fields: [
        CrudField(
          keyName: 'student_id',
          label: 'Estudante',
          type: CrudFieldType.select,
          required: true,
          optionsEndpoint: '/students',
          optionValue: (r) => r['id'],
          optionLabel: (r) {
            final name = r['full_name']?.toString() ?? 'Estudante';
            final number = r['student_number']?.toString();
            final className = r['class_name']?.toString();
            final parts = [name, if (number != null && number.isNotEmpty) number, if (className != null && className.isNotEmpty) className];
            return parts.join(' · ');
          },
        ),
        CrudField(
          keyName: 'schedule_id',
          label: 'Aula/horário associado',
          type: CrudFieldType.select,
          required: false,
          hint: 'Opcional: associe a justificação a uma aula concreta.',
          optionsEndpoint: '/schedule',
          optionValue: (r) => r['id'],
          optionLabel: (r) {
            final date = r['schedule_date']?.toString() ?? r['date']?.toString() ?? 'Data';
            final start = r['start_time']?.toString() ?? '';
            final discipline = r['discipline_name']?.toString() ?? 'Disciplina';
            final className = r['class_name']?.toString() ?? 'Turma';
            return '$date $start · $className · $discipline';
          },
        ),
        const CrudField(
          keyName: 'justification_date',
          label: 'Data da falta',
          type: CrudFieldType.date,
          required: true,
          hint: 'Formato: AAAA-MM-DD',
        ),
        const CrudField(
          keyName: 'reason',
          label: 'Motivo',
          required: true,
          hint: 'Ex.: consulta médica, motivo familiar, transporte, etc.',
        ),
        const CrudField(
          keyName: 'status',
          label: 'Estado',
          type: CrudFieldType.select,
          required: true,
          options: [
            CrudOption('pending', 'Pendente'),
            CrudOption('approved', 'Aprovada'),
            CrudOption('rejected', 'Rejeitada'),
          ],
        ),
        const CrudField(
          keyName: 'document_path',
          label: 'Documento/comprovativo',
          required: false,
          hint: 'Opcional: caminho ou referência do comprovativo.',
        ),
      ],
      titleBuilder: (j) => j['student_name']?.toString() ?? 'Justificação',
      subtitleBuilder: (j) {
        final date = j['justification_date']?.toString() ?? 'Sem data';
        final status = _statusLabel(j['status']?.toString());
        final className = j['class_name']?.toString();
        final reason = j['reason']?.toString();
        final parts = [date, status, if (className != null && className.isNotEmpty) className, if (reason != null && reason.isNotEmpty) reason];
        return parts.join(' · ');
      },
      searchableKeys: const ['student_name', 'student_number', 'class_name', 'reason', 'status', 'justification_date'],
    );
  }
}

String _statusLabel(String? status) {
  return switch (status) {
    'approved' => 'Aprovada',
    'rejected' => 'Rejeitada',
    'pending' => 'Pendente',
    _ => status ?? 'Sem estado',
  };
}
