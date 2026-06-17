import 'package:flutter/material.dart';
import 'crud_screen.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudScreen(
      title: 'Salas',
      endpoint: '/rooms',
      icon: Icons.meeting_room_outlined,
      color: const Color(0xFF087F5B),
      fields: const [
        CrudField(keyName: 'name', label: 'Nome da sala', required: true),
        CrudField(keyName: 'capacity', label: 'Capacidade', type: CrudFieldType.integer),
        CrudField(keyName: 'is_practice_room', label: 'Sala prática', type: CrudFieldType.boolean),
        CrudField(keyName: 'location', label: 'Localização'),
      ],
      searchableKeys: const ['name', 'location'],
      titleBuilder: (r) => r['name']?.toString() ?? 'Sala',
      subtitleBuilder: (r) => [
        if (r['capacity'] != null) 'Capacidade: ${r['capacity']}',
        if (r['is_practice_room'] == true || r['is_practice_room'] == 1) 'Prática',
        if (r['location'] != null) r['location'],
      ].join(' · '),
    );
  }
}
