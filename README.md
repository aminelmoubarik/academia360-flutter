# Academia360 Flutter Frontend

Frontend web/mobile em Flutter para o projeto Erasmus+ Academia360.

## Funcionalidades atuais

- Início de sessão ligado ao backend FastAPI.
- Armazenamento do token JWT.
- Painel com navegação baseada no perfil do utilizador.
- Ecrãs para estudantes, professores, cursos, disciplinas, turmas, salas, horários, assiduidade e relatórios.
- Gestão de dados para admin/diretor/secretaria.
- Área de configuração para os dados necessários à geração de horários:
  - anos letivos,
  - calendário escolar,
  - disponibilidade dos professores,
  - carga horária das disciplinas,
  - atribuições professor-disciplina.
- Geração automática de horários com pré-visualização, substituição de horário existente e verificação de condições.

## Executar localmente

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Notas

O gerador de horários depende dos dados do backend. Antes de gerar um horário real, confirma que a turma selecionada tem disciplinas, professores atribuídos, salas válidas, disponibilidade dos professores e dias letivos no calendário escolar.
