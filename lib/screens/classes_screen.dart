import 'package:flutter/material.dart';
import 'crud_screen.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudScreen(
      title: 'Turmas',
      endpoint: '/classes',
      icon: Icons.groups_outlined,
      color: const Color(0xFFE8590C),
      fields: [
        const CrudField(
          keyName: 'name',
          label: 'Nome da turma',
          required: true,
          hint: 'Exemplo: TGEI 1A',
        ),
        CrudField(
          keyName: 'course_id',
          label: 'Curso',
          type: CrudFieldType.select,
          required: true,
          optionsEndpoint: '/courses',
          optionValue: (r) => r['id'],
          optionLabel: (r) => '${r['code'] ?? ''} — ${r['name'] ?? ''}',
        ),
        CrudField(
          keyName: 'school_year_id',
          label: 'Ano letivo',
          type: CrudFieldType.select,
          required: true,
          optionsEndpoint: '/school-years',
          optionValue: (r) => r['id'],
          optionLabel: (r) => r['name']?.toString() ?? 'Ano ${r['id']}',
        ),
        const CrudField(
          keyName: 'course_year_number',
          label: 'Ano do curso',
          type: CrudFieldType.select,
          required: true,
          options: [
            CrudOption(1, '1.º ano'),
            CrudOption(2, '2.º ano'),
            CrudOption(3, '3.º ano'),
          ],
        ),
      ],
      searchableKeys: const ['name', 'course_code', 'course_name', 'school_year'],
      titleBuilder: (r) => r['name']?.toString() ?? 'Turma',
      subtitleBuilder: (r) => [
        if (r['course_code'] != null) r['course_code'],
        if (r['course_name'] != null) r['course_name'],
        if (r['school_year'] != null) r['school_year'],
        if (r['course_year_number'] != null) '${r['course_year_number']}.º ano',
      ].join(' · '),
    );
  }
}
