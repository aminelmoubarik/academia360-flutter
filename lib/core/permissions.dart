/// Centraliza as permissões da interface segundo os papéis definidos no
/// enunciado do projeto Academia360.
class AppPermissions {
  static String normalize(String? role) => (role ?? '').trim().toLowerCase();

  static bool isAdmin(String? role) => normalize(role) == 'admin';
  static bool isDirector(String? role) => normalize(role) == 'director';
  static bool isSecretary(String? role) => normalize(role) == 'secretary';
  static bool isProfessor(String? role) => normalize(role) == 'professor';

  static bool canUsePunchTerminal(String? role) =>
      isAdmin(role) || isSecretary(role) || isProfessor(role);

  static bool canViewAttendance(String? role) =>
      isAdmin(role) || isDirector(role) || isSecretary(role) || isProfessor(role);

  static bool canManageAttendance(String? role) =>
      isAdmin(role) || isSecretary(role) || isProfessor(role);

  static bool canManageAttendanceRecords(String? role) =>
      isAdmin(role) || isSecretary(role);

  static bool canViewJustifications(String? role) =>
      isAdmin(role) || isDirector(role) || isSecretary(role) || isProfessor(role);

  static bool canCreateJustifications(String? role) =>
      isAdmin(role) || isSecretary(role);

  static bool canReviewJustifications(String? role) =>
      isAdmin(role) || isDirector(role) || isSecretary(role);

  static bool canDeleteJustifications(String? role) =>
      isAdmin(role) || isSecretary(role);

  static bool canViewSchedule(String? role) =>
      isAdmin(role) || isDirector(role) || isSecretary(role) || isProfessor(role);

  static bool canGenerateSchedule(String? role) => isAdmin(role);

  static bool canApproveSchedule(String? role) =>
      isAdmin(role) || isDirector(role);

  static bool canViewReports(String? role) =>
      isAdmin(role) || isDirector(role) || isSecretary(role);

  static bool canViewAcademicData(String? role) =>
      isAdmin(role) || isDirector(role) || isSecretary(role) || isProfessor(role);

  static bool canManageStudents(String? role) => isAdmin(role) || isSecretary(role);
  static bool canManageClasses(String? role) => isAdmin(role) || isSecretary(role);

  /// Dados estruturais: cursos, disciplinas, salas, professores e configurações
  /// que afetam o algoritmo de horários. Mantidos como área de Administração.
  static bool canManageAcademicCatalog(String? role) => isAdmin(role);
  static bool canManageConfiguration(String? role) => isAdmin(role);
  static bool canManageUsers(String? role) => isAdmin(role);
  static bool canViewAuditLogs(String? role) => isAdmin(role) || isDirector(role);

  static bool canOpenFeature(String? role, String key) {
    switch (key) {
      case 'dashboard':
        return true;
      case 'attendance_punch':
        return canUsePunchTerminal(role);
      case 'attendance':
        return canViewAttendance(role);
      case 'justifications':
        return canViewJustifications(role);
      case 'reports':
        return canViewReports(role);
      case 'schedule':
      case 'my_schedule':
        return canViewSchedule(role);
      case 'generate_schedule':
        return canGenerateSchedule(role);
      case 'schedule_approval':
        return canApproveSchedule(role);
      case 'students':
      case 'professors':
      case 'classes':
      case 'courses':
      case 'disciplines':
      case 'rooms':
        return canViewAcademicData(role);
      case 'configuration':
        return canManageConfiguration(role);
      case 'users':
        return canManageUsers(role);
      case 'audit_logs':
        return canViewAuditLogs(role);
      default:
        return false;
    }
  }
}
