class ApiConstants {
  static const String baseUrl = 'https://studycenter.nanoprojectdevindonesia.com/api';

  // Auth
  static const String login       = '/auth/login';
  static const String register    = '/auth/register';
  static const String logout      = '/auth/logout';
  static const String refresh     = '/auth/refresh';
  static const String me          = '/me';
  static const String googleLogin = '/auth/google';

  // Profile
  static const String profile = '/profile';
  static String publicProfile(String username) => '/profil/$username';

  // CV
  static const String cv = '/cv';

  // Jurnal
  static const String jurnalToday   = '/jurnal/today';
  static const String jurnalCheck   = '/jurnal/check';
  static const String jurnalHistory = '/jurnal/history';
  static const String jurnalFoto    = '/jurnal/foto';

  // Laporan
  static const String laporanSummary = '/laporan/my';
  static const String laporanMatrix  = '/laporan/my/matrix';

  // Galeri
  static const String galeri = '/galeri';

  // Blog
  static const String blogs           = '/blogs';
  static String blogDetail(String slug) => '/blogs/$slug';
  static String blogUpdate(int id)      => '/blogs/$id';
  static String blogDelete(int id)      => '/blogs/$id';
  static const String blogUploadImage   = '/blogs/upload-image';
  static String blogComments(int blogId)    => '/blogs/$blogId/comments';
  static String deleteComment(int commentId) => '/comments/$commentId';

  // Public
  static const String cabangs = '/cabangs';
  static String cabangDetail(String slug) => '/cabangs/$slug';

  // Kelas Master (mentor/admin)
  static const String kelasMaster = '/kelas-master';
  static String kelasMasterDetail(int id) => '/kelas-master/$id';

  // Mentor Presensi — mentor's own attendance log
  static const String mentorPresensi = '/mentor-presensi';
  static String mentorPresensiDetail(int id) => '/mentor-presensi/$id';

  // Presensi — student attendance taken by mentor
  static const String presensi = '/presensi';
  static String presensiDetail(int id) => '/presensi/$id';
  static const String presensiSearchStudents = '/presensi/students/search';

  // App version check (public)
  static const String appVersion = '/app/version';

  // Admin: Dashboard
  static const String adminDashboard = '/admin/dashboard';

  // Admin: Users (full CRUD)
  static const String adminUsers = '/admin/users';
  static String adminUserDetail(int id) => '/admin/users/$id';
  static String adminUserRole(int id) => '/admin/users/$id/role';
  static String adminUserToggleActive(int id) => '/admin/users/$id/toggle-active';

  // Admin: Cross-role jurnal monitoring
  static const String jurnalMonitorSummary = '/admin/jurnal-monitor/summary';
  static String jurnalMonitorList(String role) => '/admin/jurnal-monitor/$role';
  static String jurnalMonitorDetail(String role, int userId) =>
      '/admin/jurnal-monitor/$role/$userId';
  static String jurnalMonitorExport(String role, int userId) =>
      '/admin/jurnal-monitor/$role/$userId/export';

  // Admin: Jurnal life items / bible schedules / weekly verses
  static const String adminJurnalLifeItems = '/admin/jurnal/life-items';
  static String adminJurnalLifeItemDetail(int id) => '/admin/jurnal/life-items/$id';
  static String adminJurnalStudentLifeItems(int studentId) =>
      '/admin/jurnal/students/$studentId/life-items';
  static const String adminJurnalBibleSchedules = '/admin/jurnal/bible-schedules';
  static String adminJurnalBibleScheduleDetail(int id) =>
      '/admin/jurnal/bible-schedules/$id';
  static const String adminJurnalBibleSchedulesBulk = '/admin/jurnal/bible-schedules/bulk';
  static const String adminJurnalWeeklyVerses = '/admin/jurnal/weekly-verses';
  static String adminJurnalWeeklyVerseDetail(int id) => '/admin/jurnal/weekly-verses/$id';

  // Admin: Blog & comment moderation
  static const String adminBlogs = '/admin/blogs';
  static String adminBlogDelete(int id) => '/admin/blogs/$id';
  static const String adminComments = '/admin/comments';
  static String adminCommentDelete(int id) => '/admin/comments/$id';

  // Admin: Mata Pelajaran
  static const String adminMataPelajaran = '/admin/mata-pelajaran';
  static String adminMataPelajaranDetail(int id) => '/admin/mata-pelajaran/$id';
  static String adminMataPelajaranToggle(int id) => '/admin/mata-pelajaran/$id/toggle';

  // Admin: Pendaftaran
  static const String adminPendaftaran = '/admin/pendaftaran';
  static String adminPendaftaranDetail(int userId) => '/admin/pendaftaran/$userId';
  static String adminPendaftaranValidasi(int userId) => '/admin/pendaftaran/$userId/validasi';

  // Admin: Certificates
  static const String adminCertTemplates = '/admin/certificates/templates';
  static String adminCertTemplateDetail(int id) => '/admin/certificates/templates/$id';
  static const String adminCertIssued = '/admin/certificates/issued';
  static String adminCertIssuedDetail(int id) => '/admin/certificates/issued/$id';
  static String adminCertIssuedDownload(int id) => '/admin/certificates/issued/$id/download';

  // Admin: Roles & Permissions
  static const String adminRoles = '/admin/roles';
  static String adminRoleDetail(int id) => '/admin/roles/$id';
  static String adminRolePermissions(int id) => '/admin/roles/$id/permissions';
  static const String adminPermissions = '/admin/permissions';

  // Admin: Name tags
  static const String adminNameTags = '/admin/nametags';
  static const String adminNameTagsGenerate = '/admin/nametags/generate';

  // Admin: Mentor presensi reports
  static const String adminMentorPresensi = '/admin/mentor-presensi';
  static const String adminMentorPresensiReports = '/admin/mentor-presensi/reports';
  static const String adminMentorPresensiExportExcel = '/admin/mentor-presensi/export/excel';
  static const String adminMentorPresensiExportPdf = '/admin/mentor-presensi/export/pdf';

  // Admin: Notifications
  static const String adminNotifications = '/admin/admin-notifications';
  static String adminNotificationMarkRead(int id) =>
      '/admin/admin-notifications/$id/mark-read';

  // Admin: Jurnal offline templates + photo scans
  static const String adminJurnalOfflineTemplates = '/jurnal-offline-templates';
  static String adminJurnalOfflineTemplateDetail(int id) => '/jurnal-offline-templates/$id';
  static String adminJurnalOfflineTemplateDownload(int id) => '/jurnal-offline-templates/$id/download';
  static const String adminJurnalPhotoScans = '/jurnal-photo-scans';

  // Admin: Jurnal College
  static const String adminJurnalCollegeDashboard = '/admin/jurnal-college/';
  static const String adminJurnalCollegeBible     = '/admin/jurnal-college/bible';
  static const String adminJurnalCollegeItems     = '/admin/jurnal-college/items';

  // ── College self-service (API, role:college) ─────────────────────────────
  static const String collegeJurnalToday   = '/college-jurnal/today';
  static const String collegeJurnalCheck   = '/college-jurnal/check';
  static const String collegeJurnalHistory = '/college-jurnal/history';
  static const String collegeJurnalFoto    = '/college-jurnal/foto';
  static const String collegeProfile       = '/college/profile';
  static const String collegeReviewList    = '/college/review';
  static String collegeReviewDetail(int id) => '/college/review/$id';
}
