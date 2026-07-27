class ApiConstants {
  static const String baseUrl = 'http://10.190.121.161:8000/api';

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
}
