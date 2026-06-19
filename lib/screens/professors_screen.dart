import 'package:flutter/material.dart';
import 'crud_screen.dart';

class ProfessorsScreen extends StatelessWidget {
  const ProfessorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudScreen(
      title: 'Professores',
      endpoint: '/professors',
      icon: Icons.school_outlined,
      color: const Color(0xFF0CA678),
      editableRoles: const ['admin'],
      fields: [
        CrudField(
          keyName: 'user_id',
          label: 'Utilizador associado',
          type: CrudFieldType.select,
          required: true,
          optionsEndpoint: '/users',
          optionValue: (r) => r['id'],
          optionLabel: (r) => '${r['full_name'] ?? 'Utilizador ${r['id']}'} · ${r['email'] ?? ''} · ${r['role'] ?? ''}',
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
        const CrudField(keyName: 'photo_path', label: 'Caminho da fotografia'),
      ],
      searchableKeys: const ['full_name', 'email', 'role', 'city'],
      titleBuilder: (r) => r['full_name']?.toString() ?? 'Professor',
      subtitleBuilder: (r) => [
        if (r['email'] != null) r['email'],
        if (r['city'] != null) r['city'],
        if (r['contact'] != null) r['contact'],
      ].join(' · '),
    );
  }
}
