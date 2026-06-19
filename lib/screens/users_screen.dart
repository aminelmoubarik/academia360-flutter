import 'package:flutter/material.dart';
import '../models/user.dart';
import 'crud_screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudScreen(
      title: 'Utilizadores',
      endpoint: '/users',
      icon: Icons.manage_accounts_outlined,
      color: const Color(0xFF495057),
      editableRoles: const ['admin'],
      canDeleteRecord: (record, User? currentUser) {
        final recordId = record['id'];
        final isCurrentUser = currentUser != null && recordId == currentUser.userId;
        final isAdmin = record['role']?.toString() == 'admin';
        return !isCurrentUser && !isAdmin;
      },
      fields: const [
        CrudField(keyName: 'full_name', label: 'Nome completo', required: true),
        CrudField(keyName: 'email', label: 'Email', type: CrudFieldType.email, required: true),
        CrudField(
          keyName: 'password',
          label: 'Palavra-passe',
          type: CrudFieldType.password,
          required: true,
          editableSecret: true,
          hint: 'Mínimo 6 caracteres',
        ),
        CrudField(
          keyName: 'password_confirm',
          label: 'Confirmar palavra-passe',
          type: CrudFieldType.password,
          required: true,
          editableSecret: true,
          confirmFor: 'password',
          sendInPayload: false,
          hint: 'Repita a palavra-passe',
        ),
        CrudField(
          keyName: 'role_id',
          label: 'Perfil',
          type: CrudFieldType.select,
          required: true,
          options: [
            CrudOption(1, 'Administrador'),
            CrudOption(2, 'Diretor'),
            CrudOption(3, 'Secretaria'),
            CrudOption(4, 'Professor'),
          ],
        ),
      ],
      searchableKeys: const ['full_name', 'email', 'role'],
      titleBuilder: (r) => r['full_name']?.toString() ?? 'Utilizador',
      subtitleBuilder: (r) => [
        if (r['email'] != null) r['email'],
        if (r['role'] != null) r['role'],
        if (r['password_status'] != null) r['password_status'],
      ].join(' · '),
    );
  }
}
