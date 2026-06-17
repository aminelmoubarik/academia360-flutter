import 'package:flutter/material.dart';
import '../main.dart';
import 'crud_screen.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudScreen(
      title: 'Estudantes',
      endpoint: '/students',
      icon: Icons.people_alt_outlined,
      color: Brand.blue,
      fields: [
        const CrudField(keyName: 'full_name', label: 'Nome completo', required: true),
        const CrudField(keyName: 'student_number', label: 'Número de estudante'),
        const CrudField(keyName: 'card_uid', label: 'UID do cartão / RFID'),
        CrudField(
          keyName: 'class_id',
          label: 'Turma',
          type: CrudFieldType.select,
          optionsEndpoint: '/classes',
          optionValue: (r) => r['id'],
          optionLabel: (r) {
            final name = r['name'] ?? 'Turma ${r['id']}';
            final year = r['school_year'];
            return year != null ? '$name · $year' : '$name';
          },
        ),
        const CrudField(
          keyName: 'gender_id',
          label: 'Género',
          type: CrudFieldType.select,
          options: [
            CrudOption(1, 'Masculino'),
            CrudOption(2, 'Feminino'),
            CrudOption(3, 'Outro'),
          ],
        ),
        const CrudField(keyName: 'contact', label: 'Contacto'),
        const CrudField(keyName: 'city', label: 'Cidade'),
        const CrudField(
          keyName: 'date_of_birth',
          label: 'Data de nascimento',
          type: CrudFieldType.date,
          hint: 'AAAA-MM-DD',
        ),
      ],
      searchableKeys: const ['full_name', 'student_number', 'class_name', 'course_name'],
      titleBuilder: (r) => r['full_name']?.toString() ?? 'Estudante',
      subtitleBuilder: (r) => [
        if (r['student_number'] != null) '#${r['student_number']}',
        if (r['class_name'] != null) r['class_name'],
        if (r['course_name'] != null) r['course_name'],
        if (r['school_year'] != null) r['school_year'],
      ].join(' · '),
    );
  }
}
