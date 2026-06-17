import 'package:flutter/material.dart';
import 'crud_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudScreen(
      title: 'Cursos',
      endpoint: '/courses',
      icon: Icons.layers_outlined,
      color: const Color(0xFF0B7285),
      fields: const [
        CrudField(keyName: 'code', label: 'Código', required: true, hint: 'Exemplo: TGPSI'),
        CrudField(keyName: 'name', label: 'Nome do curso', required: true),
      ],
      searchableKeys: const ['code', 'name'],
      titleBuilder: (r) => '${r['code'] ?? ''} — ${r['name'] ?? ''}',
      subtitleBuilder: (r) => 'ID do curso: ${r['id']}',
    );
  }
}
