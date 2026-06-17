import 'package:flutter/material.dart';
import 'crud_screen.dart';

class DisciplinesScreen extends StatelessWidget {
  const DisciplinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudScreen(
      title: 'Disciplinas',
      endpoint: '/disciplines',
      icon: Icons.menu_book_outlined,
      color: const Color(0xFF7048E8),
      fields: const [
        CrudField(keyName: 'name', label: 'Nome da disciplina', required: true),
        CrudField(keyName: 'code', label: 'Código', hint: 'Exemplo: PROG'),
      ],
      searchableKeys: const ['name', 'code'],
      titleBuilder: (r) => r['name']?.toString() ?? 'Disciplina',
      subtitleBuilder: (r) => [
        if (r['code'] != null) 'Código: ${r['code']}',
        if (r['id'] != null) 'ID: ${r['id']}',
      ].join(' · '),
    );
  }
}
