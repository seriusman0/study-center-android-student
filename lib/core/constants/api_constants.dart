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
}
