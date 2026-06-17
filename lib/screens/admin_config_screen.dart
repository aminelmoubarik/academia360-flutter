import 'package:flutter/material.dart';

import '../main.dart';
import 'crud_screen.dart';

class AdminConfigScreen extends StatelessWidget {
  const AdminConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ConfigCard(
        title: 'Anos letivos',
        subtitle: 'Períodos académicos usados por turmas, calendário e disponibilidade',
        icon: Icons.date_range_outlined,
        color: Brand.blue,
        builder: (_) => CrudScreen(
          title: 'Anos letivos',
          endpoint: '/school-years',
          icon: Icons.date_range_outlined,
          color: Brand.blue,
          fields: const [
            CrudField(keyName: 'name', label: 'Nome', required: true, hint: '2025/2026'),
            CrudField(keyName: 'start_date', label: 'Data de início', type: CrudFieldType.date, required: true, hint: 'AAAA-MM-DD'),
            CrudField(keyName: 'end_date', label: 'Data de fim', type: CrudFieldType.date, required: true, hint: 'AAAA-MM-DD'),
          ],
          searchableKeys: const ['name', 'start_date', 'end_date'],
          titleBuilder: (r) => r['name']?.toString() ?? 'Ano letivo',
          subtitleBuilder: (r) => '${r['start_date']} → ${r['end_date']}',
        ),
      ),
      _ConfigCard(
        title: 'Calendário escolar',
        subtitle: 'Defina que datas são dias letivos válidos',
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFF0B7285),
        builder: (_) => CrudScreen(
          title: 'Calendário escolar',
          endpoint: '/school-calendar',
          idKey: 'id',
          icon: Icons.calendar_month_outlined,
          color: const Color(0xFF0B7285),
          fields: [
            CrudField(
              keyName: 'school_year_id',
              label: 'Ano letivo',
              type: CrudFieldType.select,
              required: true,
              optionsEndpoint: '/school-years',
              optionValue: (r) => r['id'],
              optionLabel: (r) => r['name']?.toString() ?? 'Ano ${r['id']}',
            ),
            const CrudField(keyName: 'calendar_date', label: 'Data', type: CrudFieldType.date, required: true, hint: 'AAAA-MM-DD'),
            const CrudField(keyName: 'is_school_day', label: 'Dia letivo', type: CrudFieldType.boolean),
            const CrudField(keyName: 'description', label: 'Descrição'),
          ],
          searchableKeys: const ['calendar_date', 'school_year', 'description'],
          titleBuilder: (r) => r['calendar_date']?.toString() ?? 'Data',
          subtitleBuilder: (r) => '${r['school_year'] ?? 'Ano ${r['school_year_id']}'} · ${r['is_school_day'] == true || r['is_school_day'] == 1 ? 'Dia letivo' : 'Feriado'} · ${r['description'] ?? ''}',
        ),
      ),
      _ConfigCard(
        title: 'Disponibilidade dos professores',
        subtitle: 'Obrigatória para o gerador automático de horários',
        icon: Icons.access_time_outlined,
        color: const Color(0xFFE8590C),
        builder: (_) => CrudScreen(
          title: 'Disponibilidade dos professores',
          endpoint: '/teacher-availability',
          icon: Icons.access_time_outlined,
          color: const Color(0xFFE8590C),
          fields: [
            CrudField(
              keyName: 'professor_id',
              label: 'Professor',
              type: CrudFieldType.select,
              required: true,
              optionsEndpoint: '/professors',
              optionValue: (r) => r['id'],
              optionLabel: (r) => '${r['full_name'] ?? 'Professor ${r['id']}'} · ${r['email'] ?? ''}',
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
              keyName: 'day_of_week',
              label: 'Dia da semana',
              type: CrudFieldType.select,
              required: true,
              options: [
                CrudOption('monday', 'Segunda-feira'),
                CrudOption('tuesday', 'Terça-feira'),
                CrudOption('wednesday', 'Quarta-feira'),
                CrudOption('thursday', 'Quinta-feira'),
                CrudOption('friday', 'Sexta-feira'),
              ],
            ),
            const CrudField(keyName: 'start_time', label: 'Hora de início', type: CrudFieldType.time, required: true, hint: '09:00:00'),
            const CrudField(keyName: 'end_time', label: 'Hora de fim', type: CrudFieldType.time, required: true, hint: '17:00:00'),
          ],
          searchableKeys: const ['professor_name', 'school_year', 'day_of_week'],
          titleBuilder: (r) => '${r['professor_name'] ?? 'Professor ${r['professor_id']}'} · ${_weekdayPt(r['day_of_week'])}',
          subtitleBuilder: (r) => '${r['school_year'] ?? 'Ano ${r['school_year_id']}'} · ${r['start_time']} - ${r['end_time']}',
        ),
      ),
      _ConfigCard(
        title: 'Carga horária das disciplinas',
        subtitle: 'Liga disciplinas a cursos, anos e requisitos práticos',
        icon: Icons.tune_outlined,
        color: const Color(0xFF7048E8),
        builder: (_) => CrudScreen(
          title: 'Carga horária das disciplinas',
          endpoint: '/discipline-course-years',
          icon: Icons.tune_outlined,
          color: const Color(0xFF7048E8),
          fields: [
            CrudField(
              keyName: 'discipline_id',
              label: 'Disciplina',
              type: CrudFieldType.select,
              required: true,
              optionsEndpoint: '/disciplines',
              optionValue: (r) => r['id'],
              optionLabel: (r) => '${r['name'] ?? 'Disciplina ${r['id']}'} · ${r['code'] ?? ''}',
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
            const CrudField(keyName: 'total_minutes', label: 'Minutos totais', type: CrudFieldType.integer, required: true),
            const CrudField(keyName: 'lesson_duration_minutes', label: 'Duração da aula em minutos', type: CrudFieldType.integer, required: true),
            const CrudField(keyName: 'is_practical', label: 'Disciplina prática', type: CrudFieldType.boolean),
          ],
          searchableKeys: const ['discipline_name', 'course_code', 'course_name', 'school_year'],
          titleBuilder: (r) => r['discipline_name']?.toString() ?? 'Carga horária',
          subtitleBuilder: (r) => '${r['course_code'] ?? 'Curso ${r['course_id']}'} · ${r['school_year'] ?? 'Ano ${r['school_year_id']}'} · ${r['course_year_number']}.º ano · ${r['total_hours'] ?? ''}h',
        ),
      ),
      _ConfigCard(
        title: 'Atribuições de professores',
        subtitle: 'Atribui professores às cargas horárias configuradas',
        icon: Icons.link_outlined,
        color: const Color(0xFF087F5B),
        builder: (_) => CrudScreen(
          title: 'Atribuições de professores',
          endpoint: '/professor-discipline-course-years',
          icon: Icons.link_outlined,
          color: const Color(0xFF087F5B),
          canUpdate: false,
          fields: [
            CrudField(
              keyName: 'professor_id',
              label: 'Professor',
              type: CrudFieldType.select,
              required: true,
              optionsEndpoint: '/professors',
              optionValue: (r) => r['id'],
              optionLabel: (r) => '${r['full_name'] ?? 'Professor ${r['id']}'} · ${r['email'] ?? ''}',
            ),
            CrudField(
              keyName: 'discipline_course_year_id',
              label: 'Disciplina / curso / ano',
              type: CrudFieldType.select,
              required: true,
              optionsEndpoint: '/discipline-course-years',
              optionValue: (r) => r['id'],
              optionLabel: (r) => '${r['discipline_name'] ?? 'Disciplina ${r['id']}'} · ${r['course_code'] ?? ''} · ${r['school_year'] ?? ''} · ${r['course_year_number']}.º ano',
            ),
          ],
          deletePathBuilder: (r) => '/professor-discipline-course-years/${r['professor_id']}/${r['discipline_course_year_id']}',
          searchableKeys: const ['professor_name', 'discipline_name', 'course_code', 'school_year'],
          titleBuilder: (r) => r['professor_name']?.toString() ?? 'Atribuição',
          subtitleBuilder: (r) => '${r['discipline_name'] ?? 'Disciplina ${r['discipline_course_year_id']}'} · ${r['course_code'] ?? ''} · ${r['school_year'] ?? ''}',
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 66,
        title: const Text('Configuração'),
        backgroundColor: Colors.white,
        foregroundColor: Brand.ink,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(gradient: Brand.heroGradient),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Brand.blueSoft.withValues(alpha: 0.45), Brand.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 350,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.38,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) => cards[index],
        ),
      ),
    );
  }
}

String _weekdayPt(dynamic value) {
  return switch (value?.toString()) {
    'monday' => 'Segunda-feira',
    'tuesday' => 'Terça-feira',
    'wednesday' => 'Quarta-feira',
    'thursday' => 'Quinta-feira',
    'friday' => 'Sexta-feira',
    _ => value?.toString() ?? '',
  };
}

class _ConfigCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const _ConfigCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: builder)),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Brand.line),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.035), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.white, 0.32)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Brand.ink, letterSpacing: -0.2)),
            const SizedBox(height: 4),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
          ),
      ),
    );
  }
}
